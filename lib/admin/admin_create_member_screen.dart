import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';

// US-014 : creation d'un compte membre par l'admin

class CreateMemberScreen extends StatefulWidget {
  const CreateMemberScreen({super.key});

  @override
  State<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends State<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.member;
  String _selectedPlan = 'standard';
  String _selectedDuration = '1';
  bool _loading = false;

  final _plans = ['standard', 'premium'];
  final _durations = ['1', '3', '6', '12'];
  final _durationLabels = {'1': '1 mois', '3': '3 mois', '6': '6 mois', '12': '1 an'};

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _createMember() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Creer le compte Firebase Auth avec mot de passe temporaire
      final tempPassword = _generateTempPassword();
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_emailCtrl.text.trim());
      if (methods.isNotEmpty) {
        setState(() => _loading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cet email est déjà utilisé.'), backgroundColor: AppColors.red),
        );
        return;
      }

      // Creer via Firebase Admin (en production, appeler une Cloud Function)

      // Ici simulation avec createUserWithEmailAndPassword
      final adminAuth = AuthService();
      final currentAdmin = adminAuth.currentUser!.uid;

      final adminUid = FirebaseAuth.instance.currentUser!.uid;

      final secondaryApp = await Firebase.initializeApp(
        name: 'Secondary',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: tempPassword,
      );

      final uid = userCredential.user!.uid;
      final now = DateTime.now();

      final user = UserModel(
        uid: uid,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        role: _selectedRole,
        createdAt: now,
        createdByAdmin: currentAdmin,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set(user.toMap());

      await secondaryApp.delete();

      // Creation du profil Firestore directement
      // Créer le user (ça switch de session)


      final newAuth = userCredential.user!.uid;
      // (en production : Cloud Function cree le compte Auth + profile)
      final months = int.parse(_selectedDuration);

      final svc = FirestoreService();
      await svc.createMemberProfile(user);

      // Creer l'abonnement initial
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': uid,
        'plan': _selectedPlan,
        'startDate': now,
        'endDate': DateTime(now.year, now.month + months, now.day),
        'status': 'active',
        'paymentMethod': 'admin',
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compte cree ! Email envoye a ${_emailCtrl.text.trim()}'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur-: $e'), backgroundColor: AppColors.red),
      );
    }
  }

  String _generateTempPassword() {
    const chars = 'ABCDEFGHJKMNPQRSTWXYZabcdefghjkmnpqrstwxyz23456789';
    return List.generate(10, (i) => chars[DateTime.now().microsecond % chars.length]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: const Text('Nouveau membre')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner (US-014 : seul l'admin peut creer)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: AppColors.green, width: 3)),
                ),
                child: const Text(
                  'Seul l\'administrateur peut creer un compte membre.\nUn mot de passe temporaire sera envoye par email.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF085041)),
                ),
              ),
              const SizedBox(height: 20),

              // Informations personnelles
              _SectionTitle(title: 'Informations personnelles'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'Prenom *'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom *'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telephone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+221 7X XXX XX XX',
                ),
              ),

              const SizedBox(height: 20),
              _SectionTitle(title: 'Role'),
              const SizedBox(height: 10),

              // Role selector
              Row(
                children: UserRole.values.where((r) => r != UserRole.admin).map((r) {
                  final selected = _selectedRole == r;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(r.name == 'member' ? 'Membre' : 'Coach'),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedRole = r),
                      selectedColor: AppColors.navy,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              _SectionTitle(title: 'Abonnement initial'),
              const SizedBox(height: 10),

              // Plan
              Row(
                children: _plans.map((p) {
                  final selected = _selectedPlan == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: FilterChip(
                      label: Text(p == 'standard' ? 'Standard' : 'Premium'),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedPlan = p),
                      selectedColor: AppColors.green,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Duree
              Wrap(
                spacing: 8,
                children: _durations.map((d) {
                  final selected = _selectedDuration == d;
                  return ChoiceChip(
                    label: Text(_durationLabels[d]!),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDuration = d),
                    selectedColor: AppColors.navy,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _createMember,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Creer le compte', style: TextStyle(fontSize: 16)),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
  );
}