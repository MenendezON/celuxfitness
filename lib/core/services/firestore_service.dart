import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── MEMBERS ───────────────────────────────────────────────

  Stream<List<UserModel>> membersStream({
    String? statusFilter,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) {
    Query query = _db
        .collection('users')
        .where('role', isEqualTo: 'member')
        .orderBy('lastName')
        .limit(limit);

    if (lastDoc != null) query = query.startAfterDocument(lastDoc);

    return query.snapshots().map((snap) =>
        snap.docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList());
  }

  // Liste des coaches pour le sélecteur du planning
  Stream<List<UserModel>> coachesStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .orderBy('lastName')
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  Future<void> createMemberProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> fields) async {
    await _db.collection('users').doc(uid).update(fields);
  }

  // US-ADMIN : supprimer un membre (Firestore uniquement — Auth via Cloud Function en prod)
  Future<void> deleteMember(String uid) async {
    final batch = _db.batch();

    // Supprimer tous les abonnements du membre
    final subs = await _db
        .collection('subscriptions')
        .where('userId', isEqualTo: uid)
        .get();
    for (final doc in subs.docs) {
      batch.delete(doc.reference);
    }

    // Supprimer le profil utilisateur
    batch.delete(_db.collection('users').doc(uid));

    await batch.commit();

    // Suppression Auth : doit être fait via Cloud Function en production
    // car un admin ne peut pas supprimer un autre compte côté client.
    // Ici on tente quand même si c'est le même utilisateur (cas de test).
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null && current.uid == uid) {
        await current.delete();
      }
    } catch (_) {}
  }

  // US-ADMIN : suspendre le dernier abonnement actif d'un membre
  Future<void> suspendLatestSubscription(String userId) async {
    final snap = await _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference.update({'status': 'suspended'});
  }

  // ─── SUBSCRIPTIONS ────────────────────────────────────────

  Stream<SubscriptionModel?> activeSubscriptionStream(String userId) {
    return _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return SubscriptionModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    });
  }

  Future<List<SubscriptionModel>> subscriptionHistory(String userId) async {
    final snap = await _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .get();
    return snap.docs.map((d) => SubscriptionModel.fromMap(d.data(), d.id)).toList();
  }

  // Stream pour la page "Gérer l'abonnement" (historique temps réel)
  Stream<List<SubscriptionModel>> memberSubscriptionsStream(String userId) {
    return _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => SubscriptionModel.fromMap(d.data(), d.id)).toList());
  }

  // Créer un nouvel abonnement (chainé si actif existant)
  Future<void> addSubscription({
    required String userId,
    required String plan,
    required int durationMonths,
    required String paymentMethod,
    DateTime? forceStartDate, // si null, calcul auto
  }) async {
    final now = DateTime.now();

    // Récupérer le dernier abonnement pour chaîner la date de début
    final snap = await _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    DateTime startDate = forceStartDate ?? now;
    if (snap.docs.isNotEmpty) {
      final latest = SubscriptionModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
      if (latest.status == SubscriptionStatus.active && latest.endDate.isAfter(now)) {
        // On chaîne : le nouveau commence à la fin du courant
        startDate = latest.endDate;
      }
    }

    final endDate = DateTime(
      startDate.year,
      startDate.month + durationMonths,
      startDate.day,
    );

    await _db.collection('subscriptions').add({
      'userId': userId,
      'plan': plan,
      'startDate': startDate,
      'endDate': endDate,
      'status': 'active',
      'paymentMethod': paymentMethod,
    });
  }

  // Mettre à jour le statut d'un abonnement existant
  Future<void> updateSubscriptionStatus(String subId, String status) async {
    await _db.collection('subscriptions').doc(subId).update({'status': status});
  }

  // ─── COURSES ──────────────────────────────────────────────

  Stream<List<CourseModel>> coursesForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _db
        .collection('courses')
        .where('schedule', isGreaterThanOrEqualTo: weekStart)
        .where('schedule', isLessThan: weekEnd)
        .orderBy('schedule')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => CourseModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<CourseModel>> coachCoursesForWeek(String coachId, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _db
        .collection('courses')
        .where('coachId', isEqualTo: coachId)
        .where('schedule', isGreaterThanOrEqualTo: weekStart)
        .where('schedule', isLessThan: weekEnd)
        .orderBy('schedule')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => CourseModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> createCourse(CourseModel course) async {
    await _db.collection('courses').add(course.toMap());
  }

  Future<void> updateCourse(String id, Map<String, dynamic> fields) async {
    await _db.collection('courses').doc(id).update(fields);
  }

  Future<void> deleteCourse(String id) async {
    await _db.collection('courses').doc(id).delete();
  }

  // ─── BOOKINGS ────────────────────────────────────────────

  Future<void> bookCourse({
    required String userId,
    required String courseId,
    required bool isFull,
  }) async {
    final batch = _db.batch();
    final bookingRef = _db.collection('bookings').doc();
    batch.set(bookingRef, {
      'userId': userId,
      'courseId': courseId,
      'status': isFull ? 'waitlist' : 'confirmed',
      'bookedAt': FieldValue.serverTimestamp(),
    });
    if (!isFull) {
      batch.update(
        _db.collection('courses').doc(courseId),
        {'enrolledCount': FieldValue.increment(1)},
      );
    }
    await batch.commit();
  }

  Future<void> cancelBooking(String bookingId, String courseId) async {
    final batch = _db.batch();
    batch.update(_db.collection('bookings').doc(bookingId), {'status': 'cancelled'});
    batch.update(_db.collection('courses').doc(courseId),
        {'enrolledCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  Stream<List<BookingModel>> userBookingsStream(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'confirmed')
        .orderBy('bookedAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => BookingModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<BookingModel>> courseBookingsStream(String courseId) {
    return _db
        .collection('bookings')
        .where('courseId', isEqualTo: courseId)
        .where('status', isNotEqualTo: 'cancelled')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => BookingModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> markAttendance(String bookingId, bool attended) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': attended ? 'attended' : 'absent',
    });
  }

  Future<bool> hasBooked(String userId, String courseId) async {
    final snap = await _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .where('status', whereIn: ['confirmed', 'waitlist'])
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // Stats membre : séances assistées, durée totale, streak journalier
  Stream<Map<String, dynamic>> memberStatsStream(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'attended')
        .snapshots()
        .asyncMap((snap) async {
      final bookings = snap.docs
          .map((d) => BookingModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();

      if (bookings.isEmpty) {
        return {'seances': 0, 'dureeMin': 0, 'streak': 0};
      }

      // Fetch tous les cours associés en parallèle
      final courseIds = bookings.map((b) => b.courseId).toSet().toList();
      final courseFutures = courseIds.map((id) => _db.collection('courses').doc(id).get());
      final courseDocs = await Future.wait(courseFutures);

      final Map<String, int> durationByCourseId = {};
      for (final doc in courseDocs) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          durationByCourseId[doc.id] = (data['durationMin'] as num?)?.toInt() ?? 0;
        }
      }

      // Durée totale
      int totalMin = 0;
      for (final b in bookings) {
        totalMin += durationByCourseId[b.courseId] ?? 0;
      }

      // Streak : jours consécutifs jusqu'à aujourd'hui
      final attendedDays = bookings
          .map((b) {
        final d = b.bookedAt;
        return DateTime(d.year, d.month, d.day);
      })
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // desc

      int streak = 0;
      DateTime cursor = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);

      for (final day in attendedDays) {
        if (day == cursor) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        } else if (day.isBefore(cursor)) {
          break; // jour manqué → streak rompu
        }
      }

      return {
        'seances': bookings.length,
        'dureeMin': totalMin,
        'streak': streak,
      };
    });
  }

  // ─── NOTIFICATIONS ────────────────────────────────────────

  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => NotificationModel.fromMap(d.data(), d.id))
        .toList());
  }

  Future<void> markNotificationRead(String notifId) async {
    await _db.collection('notifications').doc(notifId).update({'read': true});
  }

  // Historique des cours passés (attended ou absent)
  Stream<List<Map<String, dynamic>>> pastBookingsStream(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['attended', 'absent'])
        .orderBy('bookedAt', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snap) async {
      final bookings = snap.docs
          .map((d) => BookingModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      final results = <Map<String, dynamic>>[];
      for (final b in bookings) {
        final courseDoc = await _db.collection('courses').doc(b.courseId).get();
        if (!courseDoc.exists) continue;
        final course = CourseModel.fromMap(
            courseDoc.data() as Map<String, dynamic>, courseDoc.id);
        results.add({'booking': b, 'course': course});
      }
      return results;
    });
  }

  // Prochains cours réservés (confirmed, dans le futur)
  Stream<List<Map<String, dynamic>>> upcomingBookingsStream(String userId) {
    final now = Timestamp.fromDate(DateTime.now());
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .asyncMap((snap) async {
      final bookings = snap.docs
          .map((d) => BookingModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();

      final results = <Map<String, dynamic>>[];
      for (final b in bookings) {
        final courseDoc = await _db.collection('courses').doc(b.courseId).get();
        if (!courseDoc.exists) continue;
        final course = CourseModel.fromMap(
            courseDoc.data() as Map<String, dynamic>, courseDoc.id);
        if (course.schedule.isAfter(DateTime.now())) {
          results.add({'booking': b, 'course': course});
        }
      }
      results.sort((a, b) =>
          (a['course'] as CourseModel).schedule
              .compareTo((b['course'] as CourseModel).schedule));
      return results;
    });
  }

  // ─── ADMIN STATS ─────────────────────────────────────────
  // Calcul côté client depuis les snapshots — évite .count() qui
  // nécessite Firestore v9.14+ et des index supplémentaires.

  static const int prixMensualite = 15000; // FCFA
  static const int prixSeance    = 1000;   // FCFA

  Stream<Map<String, dynamic>> dashboardStatsStream() {
    final now = DateTime.now();
    final monthStart = Timestamp.fromDate(DateTime(now.year, now.month, 1));
    final in7days    = Timestamp.fromDate(now.add(const Duration(days: 7)));

    // Stream abonnements
    final subStream = _db
        .collection('subscriptions')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());

    // Stream cours du mois
    final courseStream = _db
        .collection('courses')
        .where('schedule', isGreaterThanOrEqualTo: monthStart)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());

    // Combiner les deux streams
    return subStream.asyncMap((subs) async {
      final coursesSnap = await _db
          .collection('courses')
          .where('schedule', isGreaterThanOrEqualTo: monthStart)
          .get();

      final activeSubs = subs
          .where((s) => s['status'] == 'active')
          .toList();

      final expiringSoon = activeSubs.where((s) {
        final endDate = (s['endDate'] as Timestamp?)?.toDate();
        if (endDate == null) return false;
        return endDate.isBefore(now.add(const Duration(days: 7)));
      }).length;

      final monthCourses = coursesSnap.docs.length;

      // Revenus du mois : abonnements actifs × mensualité
      // + séances individuelles (bookings confirmed du mois)
      final bookingsSnap = await _db
          .collection('bookings')
          .where('status', isEqualTo: 'confirmed')
          .where('bookedAt', isGreaterThanOrEqualTo: monthStart)
          .get();

      final revenuMensualites = activeSubs.length * prixMensualite;
      final revenuSeances     = bookingsSnap.docs.length * prixSeance;
      final revenuTotal       = revenuMensualites + revenuSeances;

      return {
        'activeMembers': activeSubs.length,
        'expiringSoon':  expiringSoon,
        'monthCourses':  monthCourses,
        'revenuTotal':   revenuTotal,
        'revenuMensualites': revenuMensualites,
        'revenuSeances':     revenuSeances,
      };
    });
  }

  Stream<List<SubscriptionModel>> subscriptionsStream() {
    return FirebaseFirestore.instance
        .collection('subscriptions')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SubscriptionModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}