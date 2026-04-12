// lib/features/widgets/course_item_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';

class CourseItemTile extends StatelessWidget {
  final String bookingId;
  final String courseId;

  const CourseItemTile({super.key, required this.bookingId, required this.courseId});

  @override
  Widget build(BuildContext context) {
    // En production: fetch le cours depuis Firestore via courseId
    // Ici affichage simplifie
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Icon(Icons.fitness_center_outlined, color: AppColors.green, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cours #${courseId.substring(0, 6)}...',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const Text('Reservation confirmee',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(20)),
            child: const Text('Reserve', style: TextStyle(fontSize: 10, color: Color(0xFF0F6E56), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// lib/features/widgets/subscription_banner.dart
class SubscriptionBanner extends StatelessWidget {
  final SubscriptionModel subscription;

  const SubscriptionBanner({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF9F27).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: Color(0xFFBA7517), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Votre abonnement expire dans ${subscription.daysRemaining} jour(s) !',
              style: const TextStyle(fontSize: 12, color: Color(0xFF633806), fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Renouveler', style: TextStyle(fontSize: 11, color: Color(0xFF854F0B), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}