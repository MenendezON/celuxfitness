import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import 'admin_create_member_screen.dart';
import 'admin_members_screen.dart';
import 'admin_planning_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_about_screen.dart';
import 'admin_reglement_screen.dart';
import '../widgets/stat_card.dart';

// US-017 : tableau de bord admin

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _DashboardTab(),
      const AdminMembersScreen(),
      const AdminPlanningScreen(),
      const AdminNotificationsScreen(),
    ];

    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Membres'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Planning'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign), label: 'Notifs'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'logout':
                  await AuthService().signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');
                  break;
                case 'about':
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminAboutScreen()),
                  );
                  break;
                case 'reglement':
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminReglementScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text('À propos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reglement',
                child: Row(
                  children: [
                    Icon(Icons.menu_book_outlined, size: 18, color: Colors.black),
                    SizedBox(width: 8),
                    Text('Règlement intérieur'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Vue d\'ensemble : ', style: Theme.of(context).textTheme.titleMedium),
                Text(DateFormat('EEEE d MMMM yyyy', 'fr').format(DateTime.now())),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<Map<String, dynamic>>(
              stream: svc.dashboardStatsStream(),
              builder: (context, snap) {
                final data = snap.data ?? {};
                final loading = snap.connectionState == ConnectionState.waiting;

                // Formatage des revenus en FCFA lisible
                String fmtFcfa(int amount) {
                  if (amount >= 1000000) {
                    return '${(amount / 1000000).toStringAsFixed(2)}M';
                  } else if (amount >= 1000) {
                    return '${(amount / 1000).toStringAsFixed(0)}k';
                  }
                  return '$amount';
                }

                final revenuTotal = data['revenuTotal'] as int? ?? 0;
                final expiringSoon = data['expiringSoon'] as int? ?? 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: StatCard(
                          label: 'Membres actifs',
                          value: loading ? '--' : '${data['activeMembers'] ?? 0}',
                          accentColor: AppColors.green,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(
                          label: 'Expirations < 7j',
                          value: loading ? '--' : '$expiringSoon',
                          accentColor: expiringSoon > 0
                              ? AppColors.amber
                              : AppColors.textHint,
                        )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: StatCard(
                          label: 'Cours ce mois',
                          value: loading ? '--' : '${data['monthCourses'] ?? 0}',
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: StatCard(
                          label: 'Revenus (FCFA)',
                          value: loading ? '--' : fmtFcfa(revenuTotal),
                          accentColor: AppColors.green,
                        )),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            Text('Actions rapides', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _QuickActions(),

            const SizedBox(height: 20),
            Text('Derniers membres inscrits', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _RecentMembers(),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.person_add_outlined, 'Nouveau membre', AppColors.navy, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMemberScreen()));
      }),
      (Icons.add_circle_outline, 'Nouveau cours', AppColors.green, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPlanningScreen()));
      }),
      (Icons.campaign_outlined, 'Notification', const Color(0xFF533AB7), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()));
      }),
    ];

    return Row(
      children: actions.map((a) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: a.$4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray, width: 0.5),
              ),
              child: Column(
                children: [
                  Icon(a.$1, color: a.$3, size: 24),
                  const SizedBox(height: 6),
                  Text(a.$2,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class _RecentMembers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService();

    return StreamBuilder<List<UserModel>>(
      stream: svc.membersStream(limit: 5),
      builder: (context, userSnap) {
        if (userSnap.hasError) return Text('Erreur: ${userSnap.error}');
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.green));
        }

        final members = userSnap.data ?? [];
        if (members.isEmpty) {
          return const Padding(padding: EdgeInsets.all(16), child: Text('Aucun membre'));
        }

        return StreamBuilder<List<SubscriptionModel>>(
          stream: svc.subscriptionsStream(),
          builder: (context, subSnap) {
            final subs = subSnap.data ?? [];
            final subMap = {for (final s in subs) s.userId: s};
            final combined = members.map((m) => UserWithSubscription(
              user: m,
              subscription: subMap[m.uid],
            )).toList();

            return Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray, width: 0.5),
              ),
              child: Column(
                children: combined
                    .map((item) => _MemberRow(member: item.user, subscription: item.subscription))
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  final UserModel member;
  final SubscriptionModel? subscription;

  const _MemberRow({required this.member, this.subscription});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.greenLight,
            backgroundImage: (member.photoUrl != null && member.photoUrl!.isNotEmpty)
                ? NetworkImage(member.photoUrl!)
                : const AssetImage('assets/images/default_avatar.jpg') as ImageProvider,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                Text(member.email,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(subscription?.plan ?? 'Aucun abonnement',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          if (subscription != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: subscription!.statusColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                subscription!.status.name[0].toUpperCase() +
                    subscription!.status.name.substring(1),
                style: const TextStyle(
                    fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}