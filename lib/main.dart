import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'admin/admin_home_screen.dart';
import 'auth/login_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/models/models.dart';
import 'home/coach_home_screen.dart';
import 'home/member_home_screen.dart';

// US-002 : session persistante — l'utilisateur reste connecte jusqu'a deconnexion volontaire

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await initializeDateFormatting('fr', null); // ✅ remove `null`

  runApp(const CeluxGymApp());
}

class CeluxGymApp extends StatelessWidget {
  const CeluxGymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Celux Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

// Ecoute authStateChanges() pour session persistante (US-002)
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Chargement initial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SplashLogo(),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: AppColors.green, strokeWidth: 2),
                ],
              ),
            ),
          );
        }

        // Pas de session -> ecran de connexion
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Session active -> redirection selon le role
        return _RoleRouter(uid: snapshot.data!.uid);
      },
    );
  }
}

class _RoleRouter extends StatelessWidget {
  final String uid;
  const _RoleRouter({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<UserModel?>(
      future: authService.fetchUserProfile(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.white,
            body: Center(child: CircularProgressIndicator(color: AppColors.green)),
          );
        }

        final user = snap.data;
        if (user == null) return const LoginScreen();

        switch (user.role) {
          case UserRole.admin:
            return const AdminHomeScreen();
          case UserRole.coach:
            return const CoachHomeScreen();
          default:
            return const MemberHomeScreen();
        }
      },
    );
  }
}

// Logo splash screen
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(painter: _SplashLogoPainter()),
        ),
        const SizedBox(height: 10),
        const Text(
          'Celux Fitness',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _SplashLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.58;
    final navyPaint = Paint()..color = AppColors.navy..style = PaintingStyle.stroke..strokeWidth = 2.5;
    final greenPaint = Paint()..color = AppColors.green..style = PaintingStyle.stroke..strokeWidth = 2.5;
    final navyFill = Paint()..color = AppColors.navy..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 52, height: 28), navyPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 36, height: 20), greenPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 20, height: 11), navyPaint);

    final gPainter = TextPainter(
      text: const TextSpan(text: 'G', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.navy)),
      textDirection: TextDirection.ltr,
    )..layout();
    gPainter.paint(canvas, Offset(cx - gPainter.width / 2, cy - gPainter.height / 2));

    final wingPath = Path()
      ..moveTo(cx, cy - 9)
      ..quadraticBezierTo(cx - 20, cy - 18, cx - 40, cy - 12)
      ..moveTo(cx, cy - 9)
      ..quadraticBezierTo(cx + 20, cy - 18, cx + 40, cy - 12);
    canvas.drawPath(wingPath, navyPaint..strokeWidth = 3.5);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 22), width: 10, height: 12), navyFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
