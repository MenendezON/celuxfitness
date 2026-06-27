import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';

// US-ADMIN : modifier le profil d'un membre

class AdminEditMemberScreen extends StatefulWidget {
  final UserModel member;
  const AdminEditMemberScreen({super.key, required this.member});

  @override
  State<AdminEditMemberScreen> createState() => _AdminEditMemberScreenState();
}

class _AdminEditMemberScreenState extends State<AdminEditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = FirestoreService();
  bool _loading = false;

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late String _selectedGender;
  late String _selectedLevel;

  final _levels = [
    ('debutant', 'Débutant'),
    ('intermediaire', 'Intermédiaire'),
    ('avance', 'Avancé'),
  ];

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.member.firstName);
    _lastNameCtrl = TextEditingController(text: widget.member.lastName);
    _phoneCtrl = TextEditingController(text: widget.member.phone ?? '');
    _selectedGender = widget.member.gender ?? 'homme';
    _selectedLevel = widget.member.level;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await _svc.updateUserProfile(widget.member.uid, {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'gender': _selectedGender,
        'level': _selectedLevel,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: AppColors.green,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar + email (non modifiable)
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.greenLight,
                      backgroundImage: (widget.member.photoUrl != null &&
                          widget.member.photoUrl!.isNotEmpty)
                          ? NetworkImage(widget.member.photoUrl!)
                          : const AssetImage('assets/images/default_avatar.jpg')
                      as ImageProvider,
                    ),
                    const SizedBox(height: 8),
                    Text(widget.member.email,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.member.role.name == 'member' ? 'Membre' : 'Coach',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.green,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _SectionLabel('Nom & Prénom'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'Prénom *'),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom *'),
                      validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+221 7X XXX XX XX',
                ),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Sexe'),
              const SizedBox(height: 8),
              Row(
                children: ['homme', 'femme'].map((g) {
                  final sel = _selectedGender == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(g == 'homme' ? 'Homme' : 'Femme'),
                      selected: sel,
                      onSelected: (_) => setState(() => _selectedGender = g),
                      selectedColor: AppColors.green,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w500),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Niveau'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _levels.map((l) {
                  final sel = _selectedLevel == l.$1;
                  return ChoiceChip(
                    label: Text(l.$2),
                    selected: sel,
                    onSelected: (_) => setState(() => _selectedLevel = l.$1),
                    selectedColor: AppColors.navy,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : AppColors.textPrimary),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Enregistrer les modifications',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary),
  );
}