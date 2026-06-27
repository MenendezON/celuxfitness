import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';
import 'admin_create_member_screen.dart';
import 'admin_edit_member_screen.dart';
import 'admin_manage_subscription_screen.dart';

// US-015 : consulter et gerer la liste des membres (admin)

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  final _svc = FirestoreService();
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';
  String _searchQuery = '';

  final _filters = [
    ('all', 'Tous'),
    ('active', 'Actifs'),
    ('expired', 'Expires'),
    ('suspended', 'Suspendus'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        title: const Text('Membres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateMemberScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un membre...',
                    prefixIcon:
                    const Icon(Icons.search, color: AppColors.textHint),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final selected = _statusFilter == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f.$2,
                              style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _statusFilter = f.$1),
                          selectedColor: AppColors.navy,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          checkmarkColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<List<SubscriptionModel>>(
              stream: _svc.subscriptionsStream(),
              builder: (context, subSnap) {
                return StreamBuilder<List<UserModel>>(
                  stream: _svc.membersStream(limit: 100),
                  builder: (context, memberSnap) {
                    if (memberSnap.connectionState ==
                        ConnectionState.waiting ||
                        subSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.green));
                    }

                    final allMembers = memberSnap.data ?? [];
                    final allSubscriptions = subSnap.data ?? [];

                    final Map<String, SubscriptionModel> latestSubByUser = {};
                    for (final sub in allSubscriptions) {
                      final existing = latestSubByUser[sub.userId];
                      if (existing == null ||
                          sub.startDate.isAfter(existing.startDate)) {
                        latestSubByUser[sub.userId] = sub;
                      }
                    }

                    var entries = allMembers.map((m) {
                      return UserWithSubscription(
                        user: m,
                        subscription: latestSubByUser[m.uid],
                      );
                    }).toList();

                    if (_statusFilter != 'all') {
                      entries = entries.where((e) {
                        if (e.subscription == null) return false;
                        return e.subscription!.status.name == _statusFilter;
                      }).toList();
                    }

                    if (_searchQuery.isNotEmpty) {
                      entries = entries
                          .where((e) =>
                      e.user.fullName
                          .toLowerCase()
                          .contains(_searchQuery) ||
                          e.user.email
                              .toLowerCase()
                              .contains(_searchQuery))
                          .toList();
                    }

                    if (entries.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun membre trouvé',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                      itemBuilder: (_, i) => _MemberCard(
                        member: entries[i].user,
                        subscription: entries[i].subscription,
                        svc: _svc,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateMemberScreen()),
        ),
        backgroundColor: AppColors.green,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text(''),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final UserModel member;
  final SubscriptionModel? subscription;
  final FirestoreService svc;

  const _MemberCard({
    required this.member,
    required this.svc,
    this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.greenLight,
            backgroundImage: (member.photoUrl != null &&
                member.photoUrl!.isNotEmpty)
                ? NetworkImage(member.photoUrl!)
                : const AssetImage('assets/images/default_avatar.jpg')
            as ImageProvider,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(member.email,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                if (member.phone != null)
                  Text(member.phone!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusPill(subscription: subscription),
              const SizedBox(height: 6),
              IconButton(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary, size: 20),
                onPressed: () => _showActions(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberActionsSheet(
        member: member,
        subscription: subscription,
        svc: svc,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final SubscriptionModel? subscription;
  const _StatusPill({this.subscription});

  Color get _bgColor {
    if (subscription == null) return AppColors.textHint;
    switch (subscription!.status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.expired:
        return Colors.red;
      case SubscriptionStatus.suspended:
        return Colors.grey;
      case SubscriptionStatus.pending:
        return Colors.orange;
    }
  }

  String get _label {
    if (subscription == null) return 'Aucun';
    final name = subscription!.status.name;
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: _bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(_label,
          style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom sheet — toutes les actions câblées
// ─────────────────────────────────────────────────────────────

class _MemberActionsSheet extends StatelessWidget {
  final UserModel member;
  final SubscriptionModel? subscription;
  final FirestoreService svc;

  const _MemberActionsSheet({
    required this.member,
    required this.svc,
    this.subscription,
  });

  // ── Modifier le profil ─────────────────────────────────────
  // Sync : on ferme le sheet via Navigator.pop DANS _ActionTile,
  // puis on push depuis le contexte parent capturé avant le pop.
  void _editProfile(NavigatorState nav) {
    nav.push(MaterialPageRoute(
        builder: (_) => AdminEditMemberScreen(member: member)));
  }

  // ── Gérer l'abonnement ────────────────────────────────────
  void _manageSubscription(NavigatorState nav) {
    nav.push(MaterialPageRoute(
        builder: (_) => AdminManageSubscriptionScreen(member: member)));
  }

  // ── Réinitialiser le mot de passe ─────────────────────────
  // Pour les actions async : on affiche le dialog AVANT de fermer le sheet,
  // et on stocke messenger/navigator avant tout await.
  Future<void> _resetPassword(
      BuildContext sheetContext,
      ScaffoldMessengerState messenger,
      ) async {
    final confirm = await showDialog<bool>(
      context: sheetContext,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Text(
            'Un email de réinitialisation sera envoyé à ${member.email}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dlgCtx, true),
              child: const Text('Envoyer')),
        ],
      ),
    );
    if (confirm != true) return;

    // Fermer le sheet avant l'opération async
    if (sheetContext.mounted) Navigator.pop(sheetContext);

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: member.email);
      messenger.showSnackBar(SnackBar(
        content: Text('Email envoyé à ${member.email}'),
        backgroundColor: AppColors.green,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Erreur : $e'), backgroundColor: AppColors.red));
    }
  }

  // ── Suspendre le compte ────────────────────────────────────
  Future<void> _suspend(
      BuildContext sheetContext,
      ScaffoldMessengerState messenger,
      ) async {
    final confirm = await showDialog<bool>(
      context: sheetContext,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Suspendre le compte'),
        content: Text(
            'L\'abonnement de ${member.fullName} sera suspendu. Confirmez-vous ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amber),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Fermer le sheet avant l'opération async
    if (sheetContext.mounted) Navigator.pop(sheetContext);

    try {
      await svc.suspendLatestSubscription(member.uid);
      messenger.showSnackBar(const SnackBar(
        content: Text('Compte suspendu'),
        backgroundColor: AppColors.amber,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Erreur : $e'), backgroundColor: AppColors.red));
    }
  }

  // ── Supprimer le compte ────────────────────────────────────
  Future<void> _delete(
      BuildContext sheetContext,
      ScaffoldMessengerState messenger,
      ) async {
    final confirm = await showDialog<bool>(
      context: sheetContext,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Text(
          'Cette action est irréversible.\n\n'
              '${member.fullName} sera supprimé de Firestore (profil + abonnements).\n\n'
              'La suppression du compte Auth doit être faite via Cloud Function en production.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Fermer le sheet avant l'opération async
    if (sheetContext.mounted) Navigator.pop(sheetContext);

    try {
      await svc.deleteMember(member.uid);
      messenger.showSnackBar(const SnackBar(
        content: Text('Compte supprimé'),
        backgroundColor: AppColors.red,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Erreur : $e'), backgroundColor: AppColors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Capturer navigator et messenger UNE FOIS, pendant que le widget
    // est encore monté — ils restent valides même après fermeture du sheet.
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.greenLight,
                child: Text(member.initials,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.green,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(member.email,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Actions sync : _ActionTile pop le sheet, puis on push
          _ActionTile(
            icon: Icons.edit_outlined,
            label: 'Modifier le profil',
            color: AppColors.navy,
            onTap: () => _editProfile(nav),
          ),
          _ActionTile(
            icon: Icons.card_membership_outlined,
            label: 'Gérer l\'abonnement',
            color: AppColors.green,
            onTap: () => _manageSubscription(nav),
          ),

          // Actions async : NE PAS laisser _ActionTile pop le sheet —
          // le pop est géré DANS la méthode, après le dialog.
          _ActionTile(
            icon: Icons.lock_reset_outlined,
            label: 'Réinitialiser le mot de passe',
            color: const Color(0xFF533AB7),
            popBeforeCall: false,
            onTap: () => _resetPassword(context, messenger),
          ),
          _ActionTile(
            icon: Icons.pause_circle_outline,
            label: 'Suspendre le compte',
            color: AppColors.amber,
            popBeforeCall: false,
            onTap: () => _suspend(context, messenger),
          ),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Supprimer le compte',
            color: AppColors.red,
            popBeforeCall: false,
            onTap: () => _delete(context, messenger),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  /// Si true (défaut), ferme le bottom sheet avant d'appeler onTap.
  /// Mettre à false pour les actions async qui gèrent elles-mêmes le pop.
  final bool popBeforeCall;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.popBeforeCall = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(
              fontSize: 14, color: color, fontWeight: FontWeight.w500)),
      onTap: () {
        if (popBeforeCall) Navigator.pop(context);
        onTap();
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}