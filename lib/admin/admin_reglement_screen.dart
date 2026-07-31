import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AdminReglementScreen extends StatelessWidget {
  const AdminReglementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: const Text('Règlement intérieur')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _HeaderBanner(),
          SizedBox(height: 16),
          _Article(
            number: '01',
            title: 'Accès & Horaires',
            icon: Icons.access_time_outlined,
            content: [
              'La salle est ouverte du lundi au vendredi de 06h00 à 22h00, le samedi de 08h00 à 20h00 et le dimanche de 09h00 à 14h00.',
              'L\'accès est réservé aux membres en possession d\'un abonnement valide et à jour.',
              'Tout membre doit présenter sa carte ou son accès numérique à l\'entrée.',
              'L\'accès peut être refusé en cas d\'abonnement expiré, suspendu ou impayé.',
            ],
          ),
          SizedBox(height: 12),
          _Article(
            number: '02',
            title: 'Tenue & Hygiène',
            icon: Icons.checkroom_outlined,
            content: [
              'Une tenue de sport propre et adaptée est obligatoire (t-shirt, short ou legging, chaussures de sport).',
              'L\'entraînement pieds nus est interdit dans toutes les zones de la salle.',
              'Une serviette personnelle est exigée pour l\'utilisation de tout appareil.',
              'Les membres sont tenus d\'essuyer les équipements après utilisation avec les produits mis à disposition.',
              'Il est interdit de se présenter en tenue de ville (jeans, chaussures de ville, etc.).',
            ],
          ),
          SizedBox(height: 12),
          _Article(
            number: '03',
            title: 'Utilisation des Équipements',
            icon: Icons.fitness_center_outlined,
            content: [
              'Les équipements doivent être utilisés conformément aux instructions affichées.',
              'Il est interdit de monopoliser un appareil pendant plus de 30 minutes si d\'autres membres attendent.',
              'Les poids et haltères doivent être remis en place après utilisation.',
              'Tout dysfonctionnement ou dommage doit être signalé immédiatement au personnel.',
              'Il est interdit de laisser tomber les poids volontairement au sol.',
            ],
          ),
          SizedBox(height: 12),
          _Article(
            number: '04',
            title: 'Cours Collectifs',
            icon: Icons.groups_outlined,
            content: [
              'La réservation préalable est obligatoire pour tout cours collectif via l\'application.',
              'En cas d\'empêchement, l\'annulation doit être effectuée au moins 2 heures avant le début du cours.',
              'Les retards de plus de 5 minutes ne permettront pas l\'accès au cours en cours.',
              'Les annulations répétées sans préavis (3 fois ou plus) peuvent entraîner une suspension temporaire des réservations.',
              'La capacité maximale de chaque cours doit être respectée.',
            ],
          ),
          SizedBox(height: 12),
          _Article(
            number: '05',
            title: 'Comportement & Respect',
            icon: Icons.handshake_outlined,
            content: [
              'Tout comportement irrespectueux, agressif ou discriminatoire envers le personnel ou les autres membres est strictement interdit.',
              'Les conversations téléphoniques doivent être effectuées en dehors des zones d\'entraînement.',
              'La musique personnelle doit être écoutée avec des écouteurs à un volume raisonnable.',
              'Il est interdit de filmer ou photographier d\'autres membres sans leur consentement explicite.',
              'CeluxFitness se réserve le droit d\'exclure définitivement tout membre ne respectant pas ces règles.',
            ],
          ),
          SizedBox(height: 12),
          _Article(
            number: '06',
            title: 'Vestiaires & Casiers',
            icon: Icons.lock_outline,
            content: [
              'Les vestiaires sont séparés hommes/femmes et doivent être maintenus propres.',
              'Les casiers sont mis à disposition pendant la durée de l\'entraînement uniquement.',
              'CeluxFitness décline toute responsabilité en cas de vol ou perte d\'effets personnels.',
              'Il est fortement déconseillé de laisser des objets de valeur dans les casiers.',
              'Tout casier resté fermé après la fermeture de la salle sera ouvert par le personnel.',
            ],
          ),
          SizedBox(height: 12),
          _Article(
            number: '07',
            title: 'Santé & Sécurité',
            icon: Icons.health_and_safety_outlined,
            content: [
              'Il est fortement recommandé de consulter un médecin avant de débuter tout programme d\'entraînement intensif.',
              'Tout membre souffrant d\'une affection contagieuse doit s\'abstenir de fréquenter la salle.',
              'En cas de malaise, le membre doit immédiatement avertir le personnel présent.',
              'CeluxFitness dispose d\'une trousse de premiers secours et d\'un défibrillateur accessible au personnel.',
              'La consommation d\'alcool, de tabac ou de toute substance illicite est strictement interdite dans l\'enceinte.',
            ],
          ),
          SizedBox(height: 12),
          _Article(
            number: '08',
            title: 'Abonnements & Paiements',
            icon: Icons.card_membership_outlined,
            content: [
              'Tout abonnement souscrit est dû intégralement, même en cas de non-utilisation.',
              'La suspension de l\'abonnement pour raison médicale est possible sur présentation d\'un certificat médical.',
              'Le transfert d\'abonnement à un tiers est strictement interdit.',
              'Tout impayé entraînera la suspension immédiate de l\'accès jusqu\'à régularisation.',
              'Les tarifs sont révisables chaque année. Les membres seront informés 30 jours à l\'avance.',
            ],
          ),
          SizedBox(height: 12),
          _Article(
            number: '09',
            title: 'Responsabilités',
            icon: Icons.gavel_outlined,
            content: [
              'CeluxFitness décline toute responsabilité pour les accidents résultant d\'une utilisation incorrecte des équipements.',
              'Les membres s\'entraînent sous leur propre responsabilité.',
              'CeluxFitness n\'est pas responsable des dommages causés aux effets personnels laissés sans surveillance.',
              'Les mineurs de moins de 16 ans doivent être accompagnés d\'un responsable légal.',
            ],
          ),
          SizedBox(height: 16),
          _Footer(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Règlement Intérieur',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text('CeluxFitness — Edition 2026',
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'L\'adhésion à CeluxFitness implique l\'acceptation pleine et entière du présent règlement. '
                'Nous vous remercions de le lire attentivement et de le respecter pour garantir '
                'une expérience agréable à tous.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Article extends StatelessWidget {
  final String number;
  final String title;
  final IconData icon;
  final List<String> content;

  const _Article({
    required this.number,
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête article
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.borderGray, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, size: 18, color: AppColors.navy),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy),
                ),
              ],
            ),
          ),
          // Points de l'article
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.map((point) => _BulletPoint(text: point)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withOpacity(0.3), width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'En cas de non-respect du présent règlement, la direction se réserve le droit '
                  'de suspendre ou résilier l\'abonnement sans remboursement. '
                  'Pour toute question, contactez-nous à contact@celuxfitness.com.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF085041),
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}