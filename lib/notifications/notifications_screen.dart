import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';

// US-011 : notifications push — historique et gestion

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser!.uid;
    final svc = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<NotificationModel>>(
        stream: svc.notificationsStream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.green));
          }
          final notifs = snap.data ?? [];
          if (notifs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 52, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('Aucune notification', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _NotifTile(notif: notifs[i]),
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  const _NotifTile({required this.notif});

  Color get _dotColor {
    switch (notif.type) {
      case 'payment_confirmed': return AppColors.green;
      case 'payment_failed': return AppColors.red;
      case 'booking': return AppColors.navy;
      case 'subscription': return const Color(0xFFEF9F27);
      case 'order': return AppColors.green;
      default: return AppColors.textHint;
    }
  }

  IconData get _icon {
    switch (notif.type) {
      case 'payment_confirmed': return Icons.check_circle_outline;
      case 'payment_failed': return Icons.error_outline;
      case 'booking': return Icons.event_available_outlined;
      case 'subscription': return Icons.card_membership_outlined;
      case 'order': return Icons.shopping_bag_outlined;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notif.read ? AppColors.white : AppColors.greenLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notif.read ? AppColors.borderGray : AppColors.green.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _dotColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(_icon, color: _dotColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(notif.title,
                          style: TextStyle(
                            fontWeight: notif.read ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          )),
                    ),
                    if (!notif.read)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(notif.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 5),
                Text(
                  timeago.format(notif.createdAt, locale: 'fr'),
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}