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

  // ─── ADMIN STATS ─────────────────────────────────────────

  Future<Map<String, dynamic>> adminDashboardStats() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final in7days = now.add(const Duration(days: 7));

    final activeMembers = await _db
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .count()
        .get();

    final expiringSoon = await _db
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .where('endDate', isLessThanOrEqualTo: in7days)
        .count()
        .get();

    final monthCourses = await _db
        .collection('courses')
        .where('schedule', isGreaterThanOrEqualTo: monthStart)
        .count()
        .get();

    return {
      'activeMembers': activeMembers.count ?? 0,
      'expiringSoon': expiringSoon.count ?? 0,
      'monthCourses': monthCourses.count ?? 0,
    };
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