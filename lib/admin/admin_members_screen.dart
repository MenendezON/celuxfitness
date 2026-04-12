import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';
import 'admin_create_member_screen.dart';

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
          // Barre de recherche + filtres
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Recherche
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un membre...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                // Filtres statut
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final selected = _statusFilter == f.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f.$2, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) => setState(() => _statusFilter = f.$1),
                          selectedColor: AppColors.navy,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          checkmarkColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste membres
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _svc.membersStream(limit: 20),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.green));
                }
                var members = snap.data ?? [];

                // Filtre recherche
                if (_searchQuery.isNotEmpty) {
                  members = members.where((m) =>
                  m.fullName.toLowerCase().contains(_searchQuery) ||
                      m.email.toLowerCase().contains(_searchQuery)).toList();
                }

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('Aucun membre trouve',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _MemberCard(member: members[i]),
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
        label: const Text('Nouveau membre', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserModel member;
  const _MemberCard({required this.member});

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
            backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            child: member.photoUrl == null
                ? Text(member.initials,
                style: const TextStyle(fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(member.email,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (member.phone != null)
                  Text(member.phone!,
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusPill(),
              const SizedBox(height: 6),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
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
      builder: (_) => _MemberActionsSheet(member: member),
    );
  }
}

class _StatusPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // En production : fetch depuis subscriptions
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text('Actif',
          style: TextStyle(fontSize: 10, color: Color(0xFF0F6E56), fontWeight: FontWeight.w600)),
    );
  }
}

class _MemberActionsSheet extends StatelessWidget {
  final UserModel member;
  const _MemberActionsSheet({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tete
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.greenLight,
                child: Text(member.initials,
                    style: const TextStyle(fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.fullName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(member.email,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _ActionTile(icon: Icons.edit_outlined, label: 'Modifier le profil', color: AppColors.navy, onTap: () {}),
          _ActionTile(icon: Icons.card_membership_outlined, label: 'Gerer l\'abonnement', color: AppColors.green, onTap: () {}),
          _ActionTile(icon: Icons.lock_reset_outlined, label: 'Reinitialiser le mot de passe', color: const Color(0xFF533AB7), onTap: () {}),
          _ActionTile(icon: Icons.pause_circle_outline, label: 'Suspendre le compte', color: AppColors.amber, onTap: () {}),
          _ActionTile(icon: Icons.delete_outline, label: 'Supprimer le compte', color: AppColors.red, onTap: () {}),
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

  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}