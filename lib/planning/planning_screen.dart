import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';

// US-007 : consulter le planning hebdomadaire
// US-008 : reserver un cours en un tap
// US-009 : annuler une reservation

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final _svc = FirestoreService();
  final _auth = AuthService();
  late DateTime _selectedDay;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _weekStart = _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
  }

  void _goWeek(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: offset * 7));
      _selectedDay = _weekStart;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      appBar: AppBar(
        title: const Text('Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _selectedDay = DateTime(now.year, now.month, now.day);
                _weekStart = _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Selecteur de semaine
          _WeekSelector(
            weekStart: _weekStart,
            selectedDay: _selectedDay,
            onDaySelected: (d) => setState(() => _selectedDay = d),
            onWeekChange: _goWeek,
          ),
          const Divider(height: 1),

          // Liste des cours du jour selectionne
          Expanded(
            child: StreamBuilder<List<CourseModel>>(
              stream: _svc.coursesForWeek(_weekStart),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.green));
                }
                final all = snap.data ?? [];
                final dayCourses = all.where((c) {
                  final d = c.schedule;
                  return d.year == _selectedDay.year &&
                      d.month == _selectedDay.month &&
                      d.day == _selectedDay.day;
                }).toList();

                if (dayCourses.isEmpty) {
                  return _EmptyDay(day: _selectedDay);
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: dayCourses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CourseCard(
                    course: dayCourses[i],
                    uid: _auth.currentUser!.uid,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekSelector extends StatelessWidget {
  final DateTime weekStart;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<int> onWeekChange;

  const _WeekSelector({
    required this.weekStart,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onWeekChange,
  });

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final monthFmt = DateFormat('MMMM yyyy', 'fr_FR');

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => onWeekChange(-1)),
              Text(monthFmt.format(weekStart),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navy)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => onWeekChange(1)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: days.map((d) {
              final isSelected = d == selectedDay;
              final isToday = d == todayDate;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDaySelected(d),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E', 'fr_FR').format(d)[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday ? AppColors.green : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.navy : isToday ? AppColors.greenLight : Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : isToday ? AppColors.green : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatefulWidget {
  final CourseModel course;
  final String uid;
  const _CourseCard({required this.course, required this.uid});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  final _svc = FirestoreService();
  bool _booked = false;
  String? _bookingId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkBooked();
  }

  Future<void> _checkBooked() async {
    final booked = await _svc.hasBooked(widget.uid, widget.course.id);
    if (mounted) setState(() => _booked = booked);
  }

  Future<void> _onBook() async {
    setState(() => _loading = true);
    await _svc.bookCourse(
      userId: widget.uid,
      courseId: widget.course.id,
      isFull: widget.course.isFull,
    );
    if (mounted) {
      setState(() { _booked = true; _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.course.isFull
              ? 'Inscrit en liste d\'attente !'
              : 'Reservation confirmee !'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  Future<void> _onCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annuler la reservation ?', style: TextStyle(fontSize: 15)),
        content: Text('Annuler votre reservation pour "${widget.course.title}" ?',
            style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    if (_bookingId != null) {
      await _svc.cancelBooking(_bookingId!, widget.course.id);
    }
    if (mounted) setState(() { _booked = false; _loading = false; });
  }

  Color get _typeColor {
    switch (widget.course.type.toLowerCase()) {
      case 'yoga': return AppColors.greenLight;
      case 'boxe': return const Color(0xFFFAEEDA);
      case 'cardio': return const Color(0xFFE6F1FB);
      default: return AppColors.bgGray;
    }
  }

  Color get _typeTextColor {
    switch (widget.course.type.toLowerCase()) {
      case 'yoga': return const Color(0xFF085041);
      case 'boxe': return const Color(0xFF854F0B);
      case 'cardio': return const Color(0xFF185FA5);
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final timeFmt = DateFormat('HH:mm');
    final endTime = c.schedule.add(Duration(minutes: c.durationMin));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _booked ? AppColors.green.withOpacity(0.4) : AppColors.borderGray,
          width: _booked ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // Icone type cours
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _typeColor, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(c.type.isNotEmpty ? c.type[0].toUpperCase() : '?',
                style: TextStyle(color: _typeTextColor, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const SizedBox(width: 12),

          // Infos cours
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text('${timeFmt.format(c.schedule)} - ${timeFmt.format(endTime)} · ${c.room}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text('Coach ${c.coachName} · ${c.enrolledCount}/${c.capacity} inscrits',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),

          // Bouton action
          _loading
              ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green))
              : _booked
              ? OutlinedButton(
            onPressed: _onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: const Text('Annuler', style: TextStyle(fontSize: 11)),
          )
              : ElevatedButton(
            onPressed: _onBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.isFull ? AppColors.textHint : AppColors.green,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(c.isFull ? 'Attente' : 'Reserver',
                style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final DateTime day;
  const _EmptyDay({required this.day});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_outlined, size: 52, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('Aucun cours ce jour', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(DateFormat('EEEE d MMMM', 'fr_FR').format(day),
              style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
        ],
      ),
    );
  }
}