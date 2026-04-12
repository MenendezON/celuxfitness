import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/models.dart';
import '../../core/services/firestore_service.dart';

// US-016 : creation et gestion des cours du planning (admin)

class AdminPlanningScreen extends StatefulWidget {
  const AdminPlanningScreen({super.key});

  @override
  State<AdminPlanningScreen> createState() => _AdminPlanningScreenState();
}

class _AdminPlanningScreenState extends State<AdminPlanningScreen> {
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
      appBar: AppBar(
        title: const Text('Planning — Admin'),
        actions: [
          TextButton.icon(
            onPressed: () => _showCreateCourseSheet(context),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text('Cours', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
                  '${DateFormat('d MMM', 'fr_FR').format(_weekStart)} — ${DateFormat('d MMM yyyy', 'fr_FR').format(_weekStart.add(const Duration(days: 6)))}',
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
              stream: _svc.coursesForWeek(_weekStart),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.green));
                }
                final courses = snap.data ?? [];
                if (courses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_outlined, size: 52, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        const Text('Aucun cours cette semaine',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateCourseSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Creer un cours'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _AdminCourseCard(
                    course: courses[i],
                    onEdit: () => _showCreateCourseSheet(context, course: courses[i]),
                    onDelete: () => _confirmDelete(context, courses[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCourseSheet(context),
        backgroundColor: AppColors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateCourseSheet(BuildContext context, {CourseModel? course}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateCourseSheet(course: course),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CourseModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce cours ?', style: TextStyle(fontSize: 15)),
        content: Text(
          'Les membres inscrits a "${course.title}" seront notifies de la suppression.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _svc.deleteCourse(course.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cours supprime.'), backgroundColor: AppColors.red),
      );
    }
  }
}

class _AdminCourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminCourseCard({required this.course, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('EEEE d MMM', 'fr_FR');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Text(
                      '${dateFmt.format(course.schedule)} · ${timeFmt.format(course.schedule)} — ${timeFmt.format(course.schedule.add(Duration(minutes: course.durationMin)))}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text('Salle ${course.room} · Coach ${course.coachName}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(
                    children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Modifier', style: TextStyle(fontSize: 13))],
                  )),
                  const PopupMenuItem(value: 'delete', child: Row(
                    children: [Icon(Icons.delete_outline, size: 16, color: AppColors.red), SizedBox(width: 8), Text('Supprimer', style: TextStyle(fontSize: 13, color: AppColors.red))],
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Barre de remplissage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Inscrits', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${course.enrolledCount}/${course.capacity}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: course.capacity > 0 ? course.enrolledCount / course.capacity : 0,
                      backgroundColor: AppColors.bgGray,
                      color: course.isFull ? AppColors.red : AppColors.green,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (course.isFull)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Complet', style: TextStyle(fontSize: 10, color: AppColors.red, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateCourseSheet extends StatefulWidget {
  final CourseModel? course;
  const _CreateCourseSheet({this.course});

  @override
  State<_CreateCourseSheet> createState() => _CreateCourseSheetState();
}

class _CreateCourseSheetState extends State<_CreateCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _svc = FirestoreService();
  final _titleCtrl = TextEditingController();
  final _coachCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '12');
  final _durationCtrl = TextEditingController(text: '60');

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'Yoga';
  bool _loading = false;

  final _types = ['Yoga', 'Cardio', 'Boxe', 'Muscu', 'Pilates', 'Zumba', 'Autre'];

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    if (c != null) {
      _titleCtrl.text = c.title;
      _coachCtrl.text = c.coachName;
      _roomCtrl.text = c.room;
      _capacityCtrl.text = '${c.capacity}';
      _durationCtrl.text = '${c.durationMin}';
      _selectedDate = c.schedule;
      _selectedTime = TimeOfDay(hour: c.schedule.hour, minute: c.schedule.minute);
      _selectedType = c.type.isNotEmpty ? c.type : 'Yoga';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _coachCtrl.dispose();
    _roomCtrl.dispose();
    _capacityCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final schedule = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final course = CourseModel(
      id: widget.course?.id ?? '',
      title: _titleCtrl.text.trim(),
      coachId: '',
      coachName: _coachCtrl.text.trim(),
      schedule: schedule,
      durationMin: int.tryParse(_durationCtrl.text) ?? 60,
      capacity: int.tryParse(_capacityCtrl.text) ?? 12,
      enrolledCount: widget.course?.enrolledCount ?? 0,
      room: _roomCtrl.text.trim(),
      type: _selectedType,
    );

    if (widget.course != null) {
      await _svc.updateCourse(widget.course!.id, course.toMap());
    } else {
      await _svc.createCourse(course);
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.course != null ? 'Cours modifie !' : 'Cours cree !'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.course != null ? 'Modifier le cours' : 'Nouveau cours',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre du cours *'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),

              // Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type de cours'),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _coachCtrl,
                decoration: const InputDecoration(labelText: 'Coach *', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roomCtrl,
                      decoration: const InputDecoration(labelText: 'Salle *'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Capacite max'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d != null) setState(() => _selectedDate = d);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today_outlined)),
                        child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _selectedTime);
                        if (t != null) setState(() => _selectedTime = t);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Heure', prefixIcon: Icon(Icons.access_time_outlined)),
                        child: Text(_selectedTime.format(context), style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duree (minutes)', prefixIcon: Icon(Icons.timer_outlined)),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.course != null ? 'Enregistrer' : 'Creer le cours',
                      style: const TextStyle(fontSize: 15)),
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