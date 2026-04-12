enum UserRole { member, coach, admin }

enum SubscriptionStatus { active, expired, suspended, pending }

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final String level; // debutant / intermediaire / avance
  final String? goal;
  final DateTime createdAt;
  final String? createdByAdmin;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.role,
    this.level = 'debutant',
    this.goal,
    required this.createdAt,
    this.createdByAdmin,
  });

  String get fullName => '$firstName $lastName';
  String get initials =>
      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) => UserModel(
    uid: uid,
    firstName: map['firstName'] ?? '',
    lastName: map['lastName'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'],
    photoUrl: map['photoUrl'],
    role: UserRole.values.firstWhere(
          (r) => r.name == (map['role'] ?? 'member'),
      orElse: () => UserRole.member,
    ),
    level: map['level'] ?? 'debutant',
    goal: map['goal'],
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    createdByAdmin: map['createdByAdmin'],
  );

  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'photoUrl': photoUrl,
    'role': role.name,
    'level': level,
    'goal': goal,
    'createdAt': createdAt,
    'createdByAdmin': createdByAdmin,
  };
}

class SubscriptionModel {
  final String id;
  final String userId;
  final String plan; // standard / premium
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final String? paymentMethod;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.paymentMethod,
  });

  bool get isExpiringSoon =>
      status == SubscriptionStatus.active &&
          endDate.difference(DateTime.now()).inDays <= 7;

  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) => SubscriptionModel(
    id: id,
    userId: map['userId'] ?? '',
    plan: map['plan'] ?? 'standard',
    startDate: (map['startDate'] as dynamic)?.toDate() ?? DateTime.now(),
    endDate: (map['endDate'] as dynamic)?.toDate() ?? DateTime.now(),
    status: SubscriptionStatus.values.firstWhere(
          (s) => s.name == (map['status'] ?? 'active'),
      orElse: () => SubscriptionStatus.pending,
    ),
    paymentMethod: map['paymentMethod'],
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'plan': plan,
    'startDate': startDate,
    'endDate': endDate,
    'status': status.name,
    'paymentMethod': paymentMethod,
  };
}

class CourseModel {
  final String id;
  final String title;
  final String coachId;
  final String coachName;
  final DateTime schedule;
  final int durationMin;
  final int capacity;
  final int enrolledCount;
  final String room;
  final String type;

  CourseModel({
    required this.id,
    required this.title,
    required this.coachId,
    required this.coachName,
    required this.schedule,
    required this.durationMin,
    required this.capacity,
    required this.enrolledCount,
    required this.room,
    required this.type,
  });

  bool get isFull => enrolledCount >= capacity;
  bool get hasSpots => enrolledCount < capacity;

  factory CourseModel.fromMap(Map<String, dynamic> map, String id) => CourseModel(
    id: id,
    title: map['title'] ?? '',
    coachId: map['coachId'] ?? '',
    coachName: map['coachName'] ?? '',
    schedule: (map['schedule'] as dynamic)?.toDate() ?? DateTime.now(),
    durationMin: map['durationMin'] ?? 60,
    capacity: map['capacity'] ?? 12,
    enrolledCount: map['enrolledCount'] ?? 0,
    room: map['room'] ?? '',
    type: map['type'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'coachId': coachId,
    'coachName': coachName,
    'schedule': schedule,
    'durationMin': durationMin,
    'capacity': capacity,
    'enrolledCount': enrolledCount,
    'room': room,
    'type': type,
  };
}

class BookingModel {
  final String id;
  final String userId;
  final String courseId;
  final String status; // confirmed / cancelled / waitlist / attended / absent
  final DateTime bookedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.status,
    required this.bookedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) => BookingModel(
    id: id,
    userId: map['userId'] ?? '',
    courseId: map['courseId'] ?? '',
    status: map['status'] ?? 'confirmed',
    bookedAt: (map['bookedAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'courseId': courseId,
    'status': status,
    'bookedAt': bookedAt,
  };
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // booking / payment / system / promo
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) => NotificationModel(
    id: id,
    userId: map['userId'] ?? '',
    title: map['title'] ?? '',
    body: map['body'] ?? '',
    type: map['type'] ?? 'system',
    read: map['read'] ?? false,
    createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'body': body,
    'type': type,
    'read': read,
    'createdAt': createdAt,
  };
}