import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

// US-018 : envoi de notifications push ciblees (admin)

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _target = 'all';
  bool _loading = false;

  final _targets = [
    ('all', 'Tous les membres', Icons.groups_outlined),
    ('premium', 'Membres Premium', Icons.star_outline),
    ('active', 'Membres actifs', Icons.check_circle_outline),
    ('expiring', 'Abonnements expirant', Icons.warning_amber_outlined),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // En production : appel Cloud Function qui cible les tokens FCM
    // Simulation : ecriture dans Firestore notifications
    try {
      final adminId = AuthService().currentUser!.uid;
      await FirebaseFirestore.instance.collection('admin_notifications').add({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'target': _target,
        'sentBy': adminId,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      if (!mounted) return;
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() { _loading = false; _target = 'all'; });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.green, size: 22),
              SizedBox(width: 8),
              Text('Notification envoyee !', style: TextStyle(fontSize: 15)),
            ],
          ),
          content: Text(
            'La notification a ete envoyee a la cible : ${_targetLabel(_target)}.',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.red),
      );
    }
  }

  String _targetLabel(String t) {
    return _targets.firstWhere((x) => x.$1 == t, orElse: () => ('', 'Tous', Icons.groups_outlined)).$2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: const Text('Envoyer une notification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ciblage (US-018)
              const Text('Cibler',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              ..._targets.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _target = t.$1),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _target == t.$1 ? AppColors.navy : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _target == t.$1 ? AppColors.navy : AppColors.borderGray,
                        width: _target == t.$1 ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(t.$3, color: _target == t.$1 ? Colors.white : AppColors.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text(t.$2,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _target == t.$1 ? Colors.white : AppColors.textPrimary,
                            )),
                        const Spacer(),
                        if (_target == t.$1)
                          const Icon(Icons.check_circle, color: AppColors.green, size: 18),
                      ],
                    ),
                  ),
                ),
              )),

              const SizedBox(height: 20),

              // Contenu
              const Text('Contenu',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  hintText: 'Ex : Fermeture exceptionnelle',
                ),
                maxLength: 60,
                validator: (v) => (v == null || v.isEmpty) ? 'Titre requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Message *',
                  hintText: 'Ex : La salle sera fermee samedi 20 avril pour maintenance.',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 200,
                validator: (v) => (v == null || v.isEmpty) ? 'Message requis' : null,
              ),

              // Apercu
              const SizedBox(height: 16),
              if (_titleCtrl.text.isNotEmpty || _bodyCtrl.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Apercu notification',
                          style: TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: const Text('CG', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_titleCtrl.text.isEmpty ? 'Titre...' : _titleCtrl.text,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(_bodyCtrl.text.isEmpty ? 'Message...' : _bodyCtrl.text,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _sendNotification,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_outlined),
                  label: Text(_loading ? 'Envoi en cours...' : 'Envoyer la notification',
                      style: const TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}