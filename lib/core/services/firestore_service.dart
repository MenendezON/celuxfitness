import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── MEMBERS ───────────────────────────────────────────────

  // US-015 : liste paginee des membres (admin)
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

  // US-014 : creation membre par admin
  Future<void> createMemberProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Mise a jour profil (US-004)
  Future<void> updateUserProfile(String uid, Map<String, dynamic> fields) async {
    await _db.collection('users').doc(uid).update(fields);
  }

  // ─── SUBSCRIPTIONS ────────────────────────────────────────

  // US-005 : abonnement actif d'un membre
  Stream<SubscriptionModel?> activeSubscriptionStream(String userId) {
    return _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return SubscriptionModel.fromMap(
          snap.docs.first.data(), snap.docs.first.id);
    });
  }

  // Historique abonnements
  Future<List<SubscriptionModel>> subscriptionHistory(String userId) async {
    final snap = await _db
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('startDate', descending: true)
        .get();
    return snap.docs
        .map((d) => SubscriptionModel.fromMap(d.data(), d.id))
        .toList();
  }

  // ─── COURSES ──────────────────────────────────────────────

  // US-007 : cours d'une semaine
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

  // Cours d'un coach
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

  // US-016 : creation cours (admin)
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

  // US-008 : reserver un cours
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

  // US-009 : annuler une reservation
  Future<void> cancelBooking(String bookingId, String courseId) async {
    final batch = _db.batch();
    batch.update(_db.collection('bookings').doc(bookingId), {'status': 'cancelled'});
    batch.update(_db.collection('courses').doc(courseId),
        {'enrolledCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  // Reservations d'un utilisateur
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

  // US-013 : inscrits d'un cours (coach)
  Stream<List<BookingModel>> courseBookingsStream(String courseId) {
    return _db
        .collection('bookings')
        .where('courseId', isEqualTo: courseId)
        .where('status', isNotEqualTo: 'cancelled')
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => BookingModel.fromMap(d.data(), d.id)).toList());
  }

  // US-013 : marquer presence
  Future<void> markAttendance(String bookingId, bool attended) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': attended ? 'attended' : 'absent',
    });
  }

  // Verifier si un user a deja reserve un cours
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

  // US-011 : notifications de l'utilisateur
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

  // US-017 : stats tableau de bord admin
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
}