import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import '../planning/planning_screen.dart';
import '../notifications/notifications_screen.dart';
import 'member_profile_screen.dart';
import '../widgets/stat_card.dart';
import '../widgets/course_item_tile.dart';
//import '../widgets/subscription_banner.dart';

// US-006 : tableau de bord membre personnalise

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  late final String _uid;
  UserModel? _user;
  SubscriptionModel? _subscription;

  @override
  void initState() {
    super.initState();
    _uid = _authService.currentUser!.uid;
    _loadProfile();
  }

  void _loadProfile() {
    _authService.userProfileStream(_uid).listen((u) {
      if (mounted) setState(() => _user = u);
    });
    _firestoreService.activeSubscriptionStream(_uid).listen((s) {
      if (mounted) setState(() => _subscription = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(uid: _uid, user: _user, subscription: _subscription),
      const PlanningScreen(),
      const NotificationsScreen(),
      const MemberProfileScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Planning'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), activeIcon: Icon(Icons.notifications), label: 'Notifs'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String uid;
  final UserModel? user;
  final SubscriptionModel? subscription;

  const _HomeTab({required this.uid, this.user, this.subscription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header navy avec logo
              _Header(user: user, subscription: subscription),

              // Bandeau expiration imminente
              if (subscription?.isExpiringSoon == true)
                SubscriptionBanner(subscription: subscription!),

              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats du mois (US-006)
                    Text('Ce mois', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _StatsRow(uid: uid),

                    const SizedBox(height: 20),

                    // Prochains cours reserves
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mes prochains cours', style: Theme.of(context).textTheme.titleMedium),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Voir tout', style: TextStyle(color: AppColors.green, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _UpcomingCourses(uid: uid),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserModel? user;
  final SubscriptionModel? subscription;
  const _Header({this.user, this.subscription});

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      color: AppColors.navy,
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.green,
            backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
            child: user?.photoUrl == null
                ? Text(user?.initials ?? '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour,', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                Text(user?.firstName ?? '...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                if (sub != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${sub.plan.toUpperCase()} · expire le ${_formatDate(sub.endDate)}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _StatsRow extends StatelessWidget {
  final String uid;
  const _StatsRow({required this.uid});

  @override
  Widget build(BuildContext context) {
    // En production : fetch depuis Firestore
    return Row(
      children: const [
        Expanded(child: StatCard(label: 'Seances', value: '12')),
        SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Duree', value: '4h30')),
        SizedBox(width: 10),
        Expanded(child: StatCard(label: 'Streak', value: '3j')),
      ],
    );
  }
}

class _UpcomingCourses extends StatelessWidget {
  final String uid;
  const _UpcomingCourses({required this.uid});

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService();
    return StreamBuilder<List<BookingModel>>(
      stream: svc.userBookingsStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.green));
        }
        final bookings = snap.data ?? [];
        if (bookings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGray, width: 0.5),
            ),
            child: const Center(
              child: Text('Aucun cours reserve.\nConsultez le planning !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
          );
        }
        return Column(
          children: bookings
              .take(3)
              .map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CourseItemTile(bookingId: b.id, courseId: b.courseId),
          ))
              .toList(),
        );
      },
    );
  }
}