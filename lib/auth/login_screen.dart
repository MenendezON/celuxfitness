import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../home/member_home_screen.dart';
import '../../home/coach_home_screen.dart';
import '../../admin/admin_home_screen.dart';
import '../../../core/models/models.dart';

// US-001 : connexion email + mot de passe
// US-002 : session persistante (gestion dans main.dart via authStateChanges)
// US-003 : reinitialisation mot de passe

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final cred = await _authService.signIn(_emailCtrl.text, _passwordCtrl.text);
      final user = await _authService.fetchUserProfile(cred.user!.uid);
      if (!mounted) return;
      _navigateByRole(user);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMsg = _mapFirebaseError(e.code);
        _loading = false;
      });
    }
  }

  void _navigateByRole(UserModel? user) {
    if (user == null) return;
    Widget dest;
    switch (user.role) {
      case UserRole.admin:
        dest = const AdminHomeScreen();
        break;
      case UserRole.coach:
        dest = const CoachHomeScreen();
        break;
      default:
        dest = const MemberHomeScreen();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dest));
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte associe a cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Compte temporairement verrouille.';
      case 'invalid-email':
        return 'Format email invalide.';
      default:
        return 'Une erreur est survenue. Reessayez.';
    }
  }

  void _showResetDialog() {
    final ctrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reinitialisation', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Saisissez votre email pour recevoir un lien de reinitialisation.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              await _authService.sendPasswordReset(ctrl.text);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email envoye. Verifiez votre boite.'),
                  backgroundColor: AppColors.green,
                ),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 52),
                // Logo Celux Gym
                //Center(child: _CeluxLogo()),
                Image.asset(
                  'assets/images/celux_logo.png',
                  width: 100,
                  fit: BoxFit.cover, // Options: contain, cover, fill, etc.
                ),
                const SizedBox(height: 28),
                Text(
                  'Bienvenue',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Connectez-vous a votre espace',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Email requis' : null,
                ),
                const SizedBox(height: 14),

                // Mot de passe
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                ),
                const SizedBox(height: 10),

                // Mot de passe oublie (US-003)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showResetDialog,
                    child: const Text('Mot de passe oublie ?',
                        style: TextStyle(color: AppColors.green, fontSize: 13)),
                  ),
                ),

                // Message erreur
                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMsg!,
                              style: const TextStyle(color: AppColors.red, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                const SizedBox(height: 8),

                // Bouton connexion (US-001)
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Se connecter', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),

                // Info session persistante (US-002)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_clock_outlined, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 5),
                    Text('Session maintenue jusqu\'a deconnexion',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget logo Celux (SVG-like with CustomPainter)
class _CeluxLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: CustomPaint(painter: _LogoPainter()),
        ),
        const SizedBox(height: 8),
        const Text(
          'CELUX GYM',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.58;

    final navyPaint = Paint()..color = AppColors.navy..style = PaintingStyle.stroke..strokeWidth = 2.5;
    final greenPaint = Paint()..color = AppColors.green..style = PaintingStyle.stroke..strokeWidth = 2.5;
    final navyFill = Paint()..color = AppColors.navy..style = PaintingStyle.fill;

    // Cercles du badge
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 58, height: 32), navyPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 22), greenPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 22, height: 12), navyPaint);

    // G au centre
    final gPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.navy),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gPainter.paint(canvas, Offset(cx - gPainter.width / 2, cy - gPainter.height / 2));

    // Ailes (lignes courbes simplifiees)
    final wingPath = Path()
      ..moveTo(cx, cy - 10)
      ..quadraticBezierTo(cx - 22, cy - 20, cx - 44, cy - 14)
      ..moveTo(cx, cy - 10)
      ..quadraticBezierTo(cx + 22, cy - 20, cx + 44, cy - 14);
    canvas.drawPath(wingPath, navyPaint..strokeWidth = 4);

    // Tete
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy - 24), width: 12, height: 14), navyFill);

    // Bec rouge
    final beakPath = Path()
      ..moveTo(cx - 6, cy - 18)
      ..lineTo(cx - 10, cy - 16)
      ..lineTo(cx + 6, cy - 18)
      ..lineTo(cx + 10, cy - 16);
    canvas.drawPath(beakPath, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}