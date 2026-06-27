import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';

// US-ADMIN : gérer les abonnements d'un membre

class AdminManageSubscriptionScreen extends StatefulWidget {
  final UserModel member;
  const AdminManageSubscriptionScreen({super.key, required this.member});

  @override
  State<AdminManageSubscriptionScreen> createState() =>
      _AdminManageSubscriptionScreenState();
}

class _AdminManageSubscriptionScreenState
    extends State<AdminManageSubscriptionScreen> {
  final _svc = FirestoreService();
  final _fmt = DateFormat('dd MMM yyyy', 'fr_FR');

  String _newPlan = 'standard';
  String _newDuration = '1';
  String _newPayment = 'especes';
  bool _adding = false;
  bool _loadingAdd = false;

  final _plans = [('standard', 'Standard'), ('premium', 'Premium')];
  final _durations = [
    ('1', '1 mois'),
    ('3', '3 mois'),
    ('6', '6 mois'),
    ('12', '1 an'),
  ];
  final _payments = [
    ('especes', 'Espèces'),
    ('mobile_money', 'Mobile Money'),
    ('virement', 'Virement'),
    ('admin', 'Admin'),
  ];

  Future<void> _addSubscription() async {
    setState(() => _loadingAdd = true);
    try {
      await _svc.addSubscription(
        userId: widget.member.uid,
        plan: _newPlan,
        durationMonths: int.parse(_newDuration),
        paymentMethod: _newPayment,
      );
      setState(() {
        _adding = false;
        _loadingAdd = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Abonnement ajouté avec succès'),
            backgroundColor: AppColors.green),
      );
    } catch (e) {
      setState(() => _loadingAdd = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur : $e'), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _changeStatus(SubscriptionModel sub, String newStatus) async {
    final label = {
      'active': 'réactiver',
      'suspended': 'suspendre',
      'expired': 'marquer comme expiré',
    }[newStatus] ?? newStatus;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Voulez-vous $label cet abonnement ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _svc.updateSubscriptionStatus(sub.id, newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Statut mis à jour'),
            backgroundColor: AppColors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur : $e'), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        title: const Text('Gérer l\'abonnement'),
      ),
      body: StreamBuilder<List<SubscriptionModel>>(
        stream: _svc.memberSubscriptionsStream(widget.member.uid),
        builder: (context, snap) {
          final subs = snap.data ?? [];
          final latest = subs.isNotEmpty ? subs.first : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // En-tête membre
              _MemberHeader(member: widget.member),
              const SizedBox(height: 16),

              // Statut actuel
              _CurrentStatusCard(latest: latest, fmt: _fmt),
              const SizedBox(height: 16),

              // Bouton ajouter un abonnement
              if (!_adding)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _adding = true),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Ajouter un abonnement'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green,
                    side: const BorderSide(color: AppColors.green),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

              // Formulaire ajout
              if (_adding) ...[
                _AddSubscriptionForm(
                  plans: _plans,
                  durations: _durations,
                  payments: _payments,
                  selectedPlan: _newPlan,
                  selectedDuration: _newDuration,
                  selectedPayment: _newPayment,
                  latestEndDate: latest?.status == SubscriptionStatus.active
                      ? latest!.endDate
                      : null,
                  onPlanChanged: (v) => setState(() => _newPlan = v),
                  onDurationChanged: (v) => setState(() => _newDuration = v),
                  onPaymentChanged: (v) => setState(() => _newPayment = v),
                  onCancel: () => setState(() => _adding = false),
                  onSubmit: _loadingAdd ? null : _addSubscription,
                  loading: _loadingAdd,
                  fmt: _fmt,
                ),
                const SizedBox(height: 16),
              ],

              // Historique
              if (subs.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Historique des abonnements',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                ...subs.map((sub) => _SubscriptionHistoryCard(
                  sub: sub,
                  fmt: _fmt,
                  onChangeStatus: _changeStatus,
                )),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Widgets internes ──────────────────────────────────────────

class _MemberHeader extends StatelessWidget {
  final UserModel member;
  const _MemberHeader({required this.member});

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
            child: Text(member.initials,
                style: const TextStyle(
                    color: AppColors.green, fontWeight: FontWeight.w700)),
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
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  final SubscriptionModel? latest;
  final DateFormat fmt;
  const _CurrentStatusCard({required this.latest, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (latest == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray, width: 0.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textHint, size: 20),
            SizedBox(width: 10),
            Text('Aucun abonnement enregistré',
                style:
                TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

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
              const Text('Abonnement actuel',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              _StatusBadge(status: latest!.status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
              icon: Icons.card_membership_outlined,
              label: 'Plan',
              value: latest!.plan == 'premium' ? 'Premium' : 'Standard'),
          const SizedBox(height: 6),
          _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Début',
              value: fmt.format(latest!.startDate)),
          const SizedBox(height: 6),
          _InfoRow(
              icon: Icons.event_outlined,
              label: 'Fin',
              value: fmt.format(latest!.endDate)),
          if (latest!.status == SubscriptionStatus.active) ...[
            const SizedBox(height: 6),
            _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Jours restants',
                value: '${latest!.daysRemaining} jours',
                highlight: latest!.isExpiringSoon),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textHint),
        const SizedBox(width: 6),
        Text('$label : ',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                highlight ? AppColors.red : AppColors.textPrimary)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SubscriptionStatus status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
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
    final n = status.name;
    return n[0].toUpperCase() + n.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: _color, borderRadius: BorderRadius.circular(20)),
      child: Text(_label,
          style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _AddSubscriptionForm extends StatelessWidget {
  final List<(String, String)> plans;
  final List<(String, String)> durations;
  final List<(String, String)> payments;
  final String selectedPlan;
  final String selectedDuration;
  final String selectedPayment;
  final DateTime? latestEndDate;
  final ValueChanged<String> onPlanChanged;
  final ValueChanged<String> onDurationChanged;
  final ValueChanged<String> onPaymentChanged;
  final VoidCallback onCancel;
  final VoidCallback? onSubmit;
  final bool loading;
  final DateFormat fmt;

  const _AddSubscriptionForm({
    required this.plans,
    required this.durations,
    required this.payments,
    required this.selectedPlan,
    required this.selectedDuration,
    required this.selectedPayment,
    required this.latestEndDate,
    required this.onPlanChanged,
    required this.onDurationChanged,
    required this.onPaymentChanged,
    required this.onCancel,
    required this.onSubmit,
    required this.loading,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = (latestEndDate != null && latestEndDate!.isAfter(now))
        ? latestEndDate!
        : now;
    final months = int.parse(selectedDuration);
    final endDate =
    DateTime(startDate.year, startDate.month + months, startDate.day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nouvel abonnement',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),

          // Chainé si abonnement actif en cours
          if (latestEndDate != null && latestEndDate!.isAfter(now))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 14, color: AppColors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Débutera après l\'abonnement actuel (${fmt.format(latestEndDate!)})',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.green),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          _FormLabel('Plan'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: plans.map((p) {
              final sel = selectedPlan == p.$1;
              return FilterChip(
                label: Text(p.$2),
                selected: sel,
                onSelected: (_) => onPlanChanged(p.$1),
                selectedColor: AppColors.green,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500),
                checkmarkColor: Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          _FormLabel('Durée'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: durations.map((d) {
              final sel = selectedDuration == d.$1;
              return ChoiceChip(
                label: Text(d.$2),
                selected: sel,
                onSelected: (_) => onDurationChanged(d.$1),
                selectedColor: AppColors.navy,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.textPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          _FormLabel('Paiement'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: payments.map((p) {
              final sel = selectedPayment == p.$1;
              return ChoiceChip(
                label: Text(p.$2),
                selected: sel,
                onSelected: (_) => onPaymentChanged(p.$1),
                selectedColor: AppColors.navy,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : AppColors.textPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Récapitulatif dates calculées
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DateInfo(label: 'Début', date: fmt.format(startDate)),
                const Icon(Icons.arrow_forward,
                    size: 14, color: AppColors.textHint),
                _DateInfo(label: 'Fin', date: fmt.format(endDate)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSubmit,
                  child: loading
                      ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Confirmer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;
  const _DateInfo({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(date,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary),
  );
}

class _SubscriptionHistoryCard extends StatelessWidget {
  final SubscriptionModel sub;
  final DateFormat fmt;
  final Future<void> Function(SubscriptionModel, String) onChangeStatus;

  const _SubscriptionHistoryCard({
    required this.sub,
    required this.fmt,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sub.plan == 'premium' ? 'Premium' : 'Standard',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: sub.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${fmt.format(sub.startDate)} → ${fmt.format(sub.endDate)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                if (sub.paymentMethod != null)
                  Text(
                    sub.paymentMethod!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
              ],
            ),
          ),
          // Menu actions rapides sur le statut
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: AppColors.textSecondary, size: 18),
            onSelected: (val) => onChangeStatus(sub, val),
            itemBuilder: (_) {
              final items = <PopupMenuEntry<String>>[];
              if (sub.status != SubscriptionStatus.active) {
                items.add(const PopupMenuItem(
                    value: 'active',
                    child: Text('Réactiver')));
              }
              if (sub.status != SubscriptionStatus.suspended) {
                items.add(const PopupMenuItem(
                    value: 'suspended',
                    child: Text('Suspendre')));
              }
              if (sub.status != SubscriptionStatus.expired) {
                items.add(const PopupMenuItem(
                    value: 'expired',
                    child: Text('Marquer expiré')));
              }
              return items;
            },
          ),
        ],
      ),
    );
  }
}