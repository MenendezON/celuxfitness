import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';

// US-012 : cours du coach du jour et de la semaine
// US-013 : liste des inscrits et gestion des presences

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser!.uid;
    final pages = [
      _CoachCoursesTab(coachId: uid),
      _CoachProgramsTab(),
    ];

    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event), label: 'Mes cours'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center), label: 'Programmes'),
        ],
      ),
    );
  }
}

// US-012 : onglet cours du coach
class _CoachCoursesTab extends StatefulWidget {
  final String coachId;
  const _CoachCoursesTab({required this.coachId});

  @override
  State<_CoachCoursesTab> createState() => _CoachCoursesTabState();
}

class _CoachCoursesTabState extends State<_CoachCoursesTab> {
  final _svc = FirestoreService();
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(_weekStart.year, _weekStart.month, _weekStart.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: const Text('Mes cours')),
      body: Column(
        children: [
          // Nav semaine
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                ),
                Text(
                  '${DateFormat('d MMM', 'fr_FR').format(_weekStart)} — ${DateFormat('d MMM', 'fr_FR').format(_weekStart.add(const Duration(days: 6)))}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navy),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: StreamBuilder<List<CourseModel>>(
              stream: _svc.coachCoursesForWeek(widget.coachId, _weekStart),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.green));
                }
                final courses = snap.data ?? [];
                if (courses.isEmpty) {
                  return const Center(
                    child: Text('Aucun cours cette semaine',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CoachCourseCard(course: courses[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCourseCard extends StatelessWidget {
  final CourseModel course;
  const _CoachCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('EEEE d MMM', 'fr_FR');

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _CourseAttendeesScreen(course: course)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(
                course.type.isNotEmpty ? course.type[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text('${dateFmt.format(course.schedule)} · ${timeFmt.format(course.schedule)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('Salle ${course.room}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${course.enrolledCount}/${course.capacity}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const Text('inscrits', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// US-013 : liste inscrits + gestion presences
class _CourseAttendeesScreen extends StatelessWidget {
  final CourseModel course;
  const _CourseAttendeesScreen({required this.course});

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService();
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('EEEE d MMMM', 'fr_FR');

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: Text(course.title)),
      body: Column(
        children: [
          // Info cours
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${dateFmt.format(course.schedule)} · ${timeFmt.format(course.schedule)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text('Salle ${course.room} · ${course.durationMin} min',
                          style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${course.enrolledCount}/${course.capacity}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF085041))),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste inscrits
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: svc.courseBookingsStream(course.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.green));
                }
                final bookings = snap.data ?? [];
                if (bookings.isEmpty) {
                  return const Center(
                    child: Text('Aucun inscrit pour ce cours.',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _AttendeeCard(booking: bookings[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeCard extends StatelessWidget {
  final BookingModel booking;
  const _AttendeeCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreService();
    final isAttended = booking.status == 'attended';
    final isAbsent = booking.status == 'absent';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray, width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.greenLight,
            child: Text(
              booking.userId.substring(0, 2).toUpperCase(),
              style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Membre ${booking.userId.substring(0, 6)}...',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                Text(booking.status == 'waitlist' ? 'Liste d\'attente' : 'Confirme',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Boutons presence
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.check_circle_outline,
                    color: isAttended ? AppColors.green : AppColors.textHint, size: 24),
                onPressed: () => svc.markAttendance(booking.id, true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.cancel_outlined,
                    color: isAbsent ? AppColors.red : AppColors.textHint, size: 24),
                onPressed: () => svc.markAttendance(booking.id, false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Placeholder programmes coach
class _CoachProgramsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(title: const Text('Programmes')),
      body: const Center(
        child: Text('Programmes — Phase 2', style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}