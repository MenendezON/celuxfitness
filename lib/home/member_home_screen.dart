import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';

// ─────────────────────────────────────────────────────────────
// MEMBER DASHBOARD
// ─────────────────────────────────────────────────────────────

class MemberHomeScreen extends StatefulWidget {
  final UserModel user;
  const MemberHomeScreen({super.key, required this.user});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  final _svc = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async => setState(() {}),
        child: CustomScrollView(
          slivers: [
            _HeaderSliver(user: widget.user),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ① Abonnement
                  _SubscriptionSection(uid: widget.user.uid, svc: _svc),
                  const SizedBox(height: 16),
                  // ② Message coach
                  if (('').isNotEmpty)
                    _CoachMessageCard(message: ''),
                  if (('').isNotEmpty)
                    const SizedBox(height: 16),
                  // ③ Activité & progression
                  _ActivitySection(
                    uid: widget.user.uid,
                    monthlyGoal: 10,
                    bestStreak: 3,
                    svc: _svc,
                  ),
                  const SizedBox(height: 16),
                  // ④ Planning & réservations
                  _PlanningSection(uid: widget.user.uid, svc: _svc),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════

class _HeaderSliver extends StatelessWidget {
  final UserModel user;
  const _HeaderSliver({required this.user});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppColors.navy,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.navy, Color(0xFF1A3A5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.greenLight,
                backgroundImage: (user.photoUrl?.isNotEmpty == true)
                    ? NetworkImage(user.photoUrl!) : null,
                child: (user.photoUrl?.isNotEmpty != true)
                    ? Text(user.initials,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour, ${user.firstName} 👋',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    Text(user.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    _LevelBadge(level: user.level),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  String get _label => switch (level) {
    'intermediaire' => 'Intermédiaire',
    'avance' => 'Avancé',
    _ => 'Débutant',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.green.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withOpacity(0.5)),
      ),
      child: Text(_label,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ① ABONNEMENT
// ═══════════════════════════════════════════════════════════════

class _SubscriptionSection extends StatelessWidget {
  final String uid;
  final FirestoreService svc;
  const _SubscriptionSection({required this.uid, required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionModel?>(
      stream: svc.activeSubscriptionStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Shimmer(height: 140);
        }
        final sub = snap.data;

        if (sub == null) {
          return _InfoCard(
            icon: Icons.card_membership_outlined,
            iconColor: AppColors.textHint,
            title: 'Aucun abonnement actif',
            subtitle: 'Contactez l\'accueil pour renouveler.',
            action: OutlinedButton(
              onPressed: () {},
              child: const Text('Renouveler'),
            ),
          );
        }

        final days = sub.daysRemaining;
        final urgent = days <= 7;
        final barColor = urgent ? AppColors.red : AppColors.green;
        final fmt = DateFormat('dd MMM yyyy', 'fr_FR');

        return _Card(
          borderColor: urgent ? AppColors.red.withOpacity(0.4) : null,
          borderWidth: urgent ? 1.5 : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle('Abonnement'),
                  _Chip(
                    label: sub.status.name[0].toUpperCase() +
                        sub.status.name.substring(1),
                    color: sub.statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _SubItem(
                          icon: Icons.star_outline,
                          label: 'Plan',
                          value: sub.plan == 'premium' ? 'Premium' : 'Standard')),
                  Expanded(
                      child: _SubItem(
                          icon: Icons.event_outlined,
                          label: 'Expire le',
                          value: fmt.format(sub.endDate))),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (days / 30).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.borderGray,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    urgent
                        ? '⚠️ Expire dans $days jour${days > 1 ? 's' : ''} !'
                        : '$days jours restants',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: barColor),
                  ),
                  if (urgent)
                    TextButton(
                      onPressed: () {},
                      child: Text('Renouveler',
                          style: TextStyle(
                              color: barColor, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const Divider(height: 20),
              // Historique paiements
              _PaymentHistory(uid: uid, svc: svc),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  final String uid;
  final FirestoreService svc;
  const _PaymentHistory({required this.uid, required this.svc});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SubscriptionModel>>(
      future: svc.subscriptionHistory(uid),
      builder: (context, snap) {
        final history = snap.data ?? [];
        if (history.isEmpty) return const SizedBox.shrink();
        final fmt = DateFormat('dd/MM/yy');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historique paiements',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            ...history.take(3).map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${s.plan == 'premium' ? 'Premium' : 'Standard'} · ${fmt.format(s.startDate)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    s.plan == 'premium' ? '20 000 F' : '15 000 F',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
            )),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ② MESSAGE COACH
// ═══════════════════════════════════════════════════════════════

class _CoachMessageCard extends StatelessWidget {
  final String message;
  const _CoachMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.record_voice_over_outlined,
              color: AppColors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Message de votre coach',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ③ ACTIVITÉ & PROGRESSION
// ═══════════════════════════════════════════════════════════════

class _ActivitySection extends StatelessWidget {
  final String uid;
  final int monthlyGoal;
  final int bestStreak;
  final FirestoreService svc;

  const _ActivitySection({
    required this.uid,
    required this.monthlyGoal,
    required this.bestStreak,
    required this.svc,
  });

  static String _fmtDuree(int min) {
    if (min == 0) return '0min';
    final h = min ~/ 60;
    final m = min % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: svc.memberStatsStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Shimmer(height: 300);
        }

        final data = snap.data ?? {};
        final seances = data['seances'] as int? ?? 0;
        final dureeMin = data['dureeMin'] as int? ?? 0;
        final streak = data['streak'] as int? ?? 0;
        final seancesMois = data['seancesMoisCourant'] as int? ?? 0;
        final seancesMoisPrec = data['seancesMoisPrecedent'] as int? ?? 0;
        final topType = data['typeFavori'] as String? ?? '—';

        // weekActivity : Map<String, int> depuis le service
        final weekMap = (data['weekActivity'] as Map<String, dynamic>?) ?? {};
        const dayKeys = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        final weekActivity = dayKeys
            .map((k) => (weekMap[k] as int?) ?? 0)
            .toList();

        final goalPct = monthlyGoal > 0
            ? (seancesMois / monthlyGoal).clamp(0.0, 1.0)
            : 0.0;
        final diff = seancesMois - seancesMoisPrec;

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Activité & Progression'),
              const SizedBox(height: 14),

              // KPIs
              Row(
                children: [
                  _KpiBox(
                      label: 'Total\nséances',
                      value: '$seances',
                      icon: Icons.fitness_center_outlined,
                      color: AppColors.green),
                  const SizedBox(width: 8),
                  _KpiBox(
                      label: 'Durée\ntotale',
                      value: _fmtDuree(dureeMin),
                      icon: Icons.timer_outlined,
                      color: AppColors.navy),
                  const SizedBox(width: 8),
                  _KpiBox(
                      label: 'Streak\nactuel',
                      value: streak > 7 ? '🔥 ${streak}j' : '${streak}j',
                      icon: Icons.local_fire_department_outlined,
                      color: streak > 0 ? AppColors.amber : AppColors.textHint),
                ],
              ),
              const SizedBox(height: 14),

              // Record streak
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Record personnel',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        Text('$bestStreak jours consécutifs',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                    const Spacer(),
                    if (streak >= bestStreak && streak > 0)
                      _Chip(label: 'Nouveau record !', color: AppColors.amber),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Objectif mensuel
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Objectif : $seancesMois / $monthlyGoal séances',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text(
                        diff >= 0 ? '+$diff vs mois préc.' : '$diff vs mois préc.',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: diff >= 0 ? AppColors.green : AppColors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: goalPct,
                      minHeight: 10,
                      backgroundColor: AppColors.borderGray,
                      valueColor:
                      const AlwaysStoppedAnimation(AppColors.green),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goalPct >= 1.0
                        ? '🎯 Objectif atteint !'
                        : '${(goalPct * 100).toInt()}% — encore ${monthlyGoal - seancesMois} séance(s)',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Type favori
              Row(
                children: [
                  const Icon(Icons.emoji_events_outlined,
                      size: 16, color: AppColors.amber),
                  const SizedBox(width: 6),
                  const Text('Cours favori : ',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(topType,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 14),

              // Graphique hebdomadaire
              _WeekBarChart(weekActivity: weekActivity),
            ],
          ),
        );
      },
    );
  }
}

class _KpiBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiBox(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _WeekBarChart extends StatelessWidget {
  final List<int> weekActivity;
  const _WeekBarChart({required this.weekActivity});

  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final maxVal =
    weekActivity.fold(0, (a, b) => a > b ? a : b).toDouble();
    final todayIdx = DateTime.now().weekday - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activité cette semaine',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final val = weekActivity[i].toDouble();
              final ratio = maxVal > 0 ? val / maxVal : 0.0;
              final isToday = i == todayIdx;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (val > 0)
                        Text('${weekActivity[i]}',
                            style: const TextStyle(
                                fontSize: 9, color: AppColors.textSecondary)),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 40 * ratio + (val > 0 ? 4 : 2),
                          color: isToday
                              ? AppColors.green
                              : AppColors.green.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_labels[i],
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: isToday
                                  ? AppColors.green
                                  : AppColors.textHint)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ④ PLANNING & RÉSERVATIONS
// ═══════════════════════════════════════════════════════════════

class _PlanningSection extends StatelessWidget {
  final String uid;
  final FirestoreService svc;
  const _PlanningSection({required this.uid, required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.upcomingBookingsStream(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Shimmer(height: 200);
        }

        final entries = snap.data ?? [];

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Planning & Réservations'),
              const SizedBox(height: 14),

              if (entries.isEmpty)
                Column(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 40, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    const Text('Aucune séance réservée',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    TextButton(
                        onPressed: () {},
                        child: const Text('Voir le planning')),
                  ],
                )
              else ...[
                // Prochaine séance avec countdown
                _NextSessionCard(
                    booking: entries.first['booking'] as BookingModel,
                    course: entries.first['course'] as CourseModel),
                const SizedBox(height: 10),

                // Alerte si cours dans < 24h
                _Alert24h(course: entries.first['course'] as CourseModel),

                // À venir
                if (entries.length > 1) ...[
                  const SizedBox(height: 12),
                  const Text('Prochaines séances',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  ...entries.skip(1).take(4).map((e) => _UpcomingRow(
                      course: e['course'] as CourseModel)),
                ],
              ],

              const Divider(height: 24),
              // Historique
              _PastCoursesHistory(uid: uid, svc: svc),
            ],
          ),
        );
      },
    );
  }
}

class _NextSessionCard extends StatefulWidget {
  final BookingModel booking;
  final CourseModel course;
  const _NextSessionCard({required this.booking, required this.course});

  @override
  State<_NextSessionCard> createState() => _NextSessionCardState();
}

class _NextSessionCardState extends State<_NextSessionCard> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.course.schedule.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = widget.course.schedule.difference(DateTime.now());
        if (_remaining.isNegative) _remaining = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    final d = _remaining;
    if (d.inDays > 0) return '${d.inDays}j ${d.inHours.remainder(24)}h';
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}min';
    }
    return '${d.inMinutes}min ${d.inSeconds.remainder(60).toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE d MMM · HH:mm', 'fr_FR');
    final course = widget.course;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.play_circle_outline,
                  color: Colors.white60, size: 14),
              SizedBox(width: 6),
              Text('Prochaine séance',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(course.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(fmt.format(course.schedule),
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: AppColors.green, size: 14),
              const SizedBox(width: 4),
              Text(_countdown,
                  style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              const Icon(Icons.person_outline,
                  color: Colors.white54, size: 13),
              const SizedBox(width: 4),
              Text(course.coachName,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 10),
              const Icon(Icons.room_outlined,
                  color: Colors.white54, size: 13),
              const SizedBox(width: 4),
              Text(course.room,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Alert24h extends StatelessWidget {
  final CourseModel course;
  const _Alert24h({required this.course});

  @override
  Widget build(BuildContext context) {
    final diff = course.schedule.difference(DateTime.now());
    if (diff.inHours > 24 || diff.isNegative) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withOpacity(0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_active_outlined,
              color: AppColors.amber, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rappel : séance dans moins de 24h. Préparez votre tenue !',
              style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  final CourseModel course;
  const _UpcomingRow({required this.course});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM · HH:mm', 'fr_FR');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Icon(Icons.fitness_center,
                size: 16, color: AppColors.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(fmt.format(course.schedule),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(course.room,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _PastCoursesHistory extends StatelessWidget {
  final String uid;
  final FirestoreService svc;
  const _PastCoursesHistory({required this.uid, required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: svc.pastBookingsStream(uid),
      builder: (context, snap) {
        final entries = snap.data ?? [];
        if (entries.isEmpty) return const SizedBox.shrink();
        final fmt = DateFormat('dd MMM yyyy', 'fr_FR');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cours passés',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...entries.take(5).map((e) {
              final booking = e['booking'] as BookingModel;
              final course = e['course'] as CourseModel;
              final attended = booking.status == 'attended';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: attended
                            ? AppColors.green
                            : AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${course.title} · ${fmt.format(course.schedule)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                    _Chip(
                      label: attended
                          ? 'Présent'
                          : booking.status == 'absent'
                          ? 'Absent'
                          : 'Annulé',
                      color: attended ? AppColors.green : AppColors.textHint,
                      small: true,
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COMPOSANTS RÉUTILISABLES
// ═══════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double? borderWidth;
  const _Card({required this.child, this.borderColor, this.borderWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? AppColors.borderGray,
          width: borderWidth ?? 0.5,
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy));
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const _Chip({required this.label, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: small ? 9 : 11,
              color: Colors.white,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _SubItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SubItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? action;
  const _InfoCard(
      {required this.icon,
        required this.iconColor,
        required this.title,
        required this.subtitle,
        this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGray, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double height;
  const _Shimmer({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.borderGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
          child: CircularProgressIndicator(color: AppColors.green)),
    );
  }
}