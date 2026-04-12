import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../auth/login_screen.dart';

// US-004 : consultation et modification du profil membre
// US-005 : statut et historique abonnement

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final uid = auth.currentUser!.uid;
    final svc = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: const Text('Mon profil')),
      body: StreamBuilder<UserModel?>(
        stream: auth.userProfileStream(uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          return StreamBuilder<SubscriptionModel?>(
            stream: svc.activeSubscriptionStream(uid),
            builder: (context, subSnap) {
              final sub = subSnap.data;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar + nom
                    _ProfileHeader(user: user),
                    const SizedBox(height: 16),

                    // Abonnement (US-005)
                    if (sub != null) _SubscriptionCard(sub: sub),
                    const SizedBox(height: 12),

                    // Infos personnelles (US-004)
                    _InfoCard(user: user, uid: uid),
                    const SizedBox(height: 12),

                    // Niveau et objectif
                    _FitnessCard(user: user, uid: uid),
                    const SizedBox(height: 12),

                    // Historique abonnements
                    _SubscriptionHistory(uid: uid),
                    const SizedBox(height: 20),

                    // Deconnexion (US-002)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Se deconnecter ?', style: TextStyle(fontSize: 15)),
                              content: const Text('Vous devrez vous reconnecter manuellement.',
                                  style: TextStyle(fontSize: 13)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Se deconnecter'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await auth.signOut();
                            if (!context.mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (_) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout, color: AppColors.red),
                        label: const Text('Se deconnecter', style: TextStyle(color: AppColors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel? user;
  const _ProfileHeader({this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.greenLight,
              backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child: user?.photoUrl == null
                  ? Text(user?.initials ?? '?',
                  style: const TextStyle(fontSize: 28, color: AppColors.green, fontWeight: FontWeight.w700))
                  : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(user?.fullName ?? '...', style: Theme.of(context).textTheme.titleLarge),
        Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionModel sub;
  const _SubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMMM yyyy', 'fr_FR');
    final isExpiring = sub.isExpiringSoon;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_membership_outlined, color: Colors.white70, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub.plan.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Expire le ${dateFmt.format(sub.endDate)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (isExpiring)
                  Text('Expire dans ${sub.daysRemaining} jour(s) !',
                      style: const TextStyle(color: Color(0xFFEF9F27), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: sub.status == SubscriptionStatus.active
                  ? AppColors.green
                  : AppColors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sub.status == SubscriptionStatus.active ? 'Actif' : 'Expire',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel? user;
  final String uid;
  const _InfoCard({this.user, required this.uid});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Informations personnelles',
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.green),
        onPressed: () => _showEditSheet(context),
      ),
      children: [
        _InfoRow(icon: Icons.person_outline, label: 'Nom complet', value: user?.fullName ?? '--'),
        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user?.email ?? '--'),
        _InfoRow(icon: Icons.phone_outlined, label: 'Telephone', value: user?.phone ?? '--'),
      ],
    );
  }

  void _showEditSheet(BuildContext context) {
    if (user == null) return;
    final firstCtrl = TextEditingController(text: user!.firstName);
    final lastCtrl = TextEditingController(text: user!.lastName);
    final phoneCtrl = TextEditingController(text: user!.phone ?? '');
    final svc = FirestoreService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Modifier le profil',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: firstCtrl, decoration: const InputDecoration(labelText: 'Prenom'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: lastCtrl, decoration: const InputDecoration(labelText: 'Nom'))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telephone')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await svc.updateUserProfile(uid, {
                  'firstName': firstCtrl.text.trim(),
                  'lastName': lastCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil mis a jour !'), backgroundColor: AppColors.green),
                );
              },
              child: const Text('Enregistrer'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _FitnessCard extends StatelessWidget {
  final UserModel? user;
  final String uid;
  const _FitnessCard({this.user, required this.uid});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Fitness',
      children: [
        _InfoRow(icon: Icons.fitness_center_outlined, label: 'Niveau', value: user?.level ?? '--'),
        _InfoRow(icon: Icons.flag_outlined, label: 'Objectif', value: user?.goal ?? 'Non defini'),
      ],
    );
  }
}

class _SubscriptionHistory extends StatelessWidget {
  final String uid;
  const _SubscriptionHistory({required this.uid});

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService();
    return _Card(
      title: 'Historique abonnements',
      children: [
        FutureBuilder<List<SubscriptionModel>>(
          future: svc.subscriptionHistory(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.green));
            }
            final history = snap.data ?? [];
            if (history.isEmpty) return const Text('Aucun historique', style: TextStyle(color: AppColors.textHint, fontSize: 13));
            final dateFmt = DateFormat('dd/MM/yyyy');
            return Column(
              children: history.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text('${s.plan.toUpperCase()} — ${dateFmt.format(s.startDate)} au ${dateFmt.format(s.endDate)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.status == SubscriptionStatus.active ? AppColors.greenLight : AppColors.bgGray,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(s.status.name, style: TextStyle(
                        fontSize: 10,
                        color: s.status == SubscriptionStatus.active ? const Color(0xFF0F6E56) : AppColors.textHint,
                      )),
                    ),
                  ],
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  const _Card({required this.title, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              if (trailing != null) trailing!,
            ],
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}