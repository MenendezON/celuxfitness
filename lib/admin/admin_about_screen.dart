import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminAboutScreen extends StatelessWidget {
  const AdminAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: const Text('À propos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Logo + nom app
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGray, width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.fitness_center,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CeluxFitness',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Plateforme de gestion fitness',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.greenLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.green,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            _SectionCard(
              title: 'Description',
              child: const Text(
                'CeluxFitness est une solution de gestion complète pour salles de sport. '
                    'Elle permet de gérer les membres, les abonnements, le planning des cours '
                    'et les communications avec les clients, le tout depuis une interface mobile intuitive.',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6),
              ),
            ),
            const SizedBox(height: 12),

            // Fonctionnalités
            _SectionCard(
              title: 'Fonctionnalités',
              child: Column(
                children: const [
                  _FeatureRow(icon: Icons.people_outline, label: 'Gestion des membres & abonnements'),
                  _FeatureRow(icon: Icons.calendar_month_outlined, label: 'Planning des cours'),
                  _FeatureRow(icon: Icons.campaign_outlined, label: 'Notifications push'),
                  _FeatureRow(icon: Icons.bar_chart_outlined, label: 'Tableau de bord & statistiques'),
                  _FeatureRow(icon: Icons.lock_outline, label: 'Contrôle d\'accès par rôle'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Infos techniques
            _SectionCard(
              title: 'Technologies',
              child: Column(
                children: const [
                  _InfoRow(label: 'Framework', value: 'Flutter 3.x'),
                  _InfoRow(label: 'Backend', value: 'Firebase (Firestore, Auth)'),
                  _InfoRow(label: 'Stockage', value: 'Cloud Firestore'),
                  _InfoRow(label: 'Authentification', value: 'Firebase Auth'),
                  _InfoRow(label: 'Plateforme', value: 'Android / iOS'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Équipe / contact
            _SectionCard(
              title: 'Contact & Support',
              child: Column(
                children: const [
                  _InfoRow(label: 'Développeur', value: 'CeluxFitness Team'),
                  _InfoRow(label: 'Email', value: 'support@celuxfitness.com'),
                  _InfoRow(label: 'Site web', value: 'www.celuxfitness.com'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Mentions légales
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray, width: 0.5),
              ),
              child: const Text(
                '© 2026 CeluxFitness. Tous droits réservés.\n'
                    'Ce logiciel est protégé par les lois sur la propriété intellectuelle.',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}