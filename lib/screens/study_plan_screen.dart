import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/study_task.dart';
import '../providers/study_plan_provider.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyPlanProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Study Task'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Topic / Title *',
                  hintText: 'e.g. Cardiology: Heart Valves',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What to study...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Scheduled Time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null) return;
                  if (!ctx.mounted) return;
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(selectedDate),
                  );
                  if (time == null) return;
                  setDialogState(() {
                    selectedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 20, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEE, d MMM yyyy  HH:mm')
                            .format(selectedDate),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                final task = StudyTask(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  title: titleCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  scheduledTime: selectedDate,
                );
                context.read<StudyPlanProvider>().addTask(task);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task added & reminder scheduled!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiSuggestDialog() {
    final topicCtrl = TextEditingController();
    int days = 7;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('AI Study Plan'),
            ],
          ),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a topic and the AI will create a personalized daily study plan for you.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: topicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Study Topic *',
                  hintText: 'e.g. Pharmacology, Heart Anatomy...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book_rounded),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Number of Days',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final d in [3, 5, 7, 14])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$d days'),
                        selected: days == d,
                        onSelected: (_) => setDialogState(() => days = d),
                        selectedColor: Colors.deepPurple,
                        labelStyle: TextStyle(
                          color: days == d ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (topicCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                context.read<StudyPlanProvider>().generatePlanFromAI(
                      topic: topicCtrl.text.trim(),
                      days: days,
                    );
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'AI Suggest',
            onPressed: _showAiSuggestDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear All',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear All Tasks'),
                  content: const Text(
                      'This will delete all study tasks and cancel all reminders. Are you sure?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Clear All',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                context.read<StudyPlanProvider>().clearAllTasks();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Tasks'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<StudyPlanProvider>(
        builder: (context, provider, _) {
          if (provider.isGenerating) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'AI is creating your study plan...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (provider.generatingError != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${provider.generatingError}'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                provider.generatingError = null;
              }
            });
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _TaskList(tasks: provider.tasks),
              _TaskList(tasks: provider.pendingTasks),
              _TaskList(tasks: provider.completedTasks),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ── Task List ──────────────────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  final List<StudyTask> tasks;
  const _TaskList({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No tasks here yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "AI Suggest" or "Add Task" to get started',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    // Group tasks by date
    final Map<String, List<StudyTask>> grouped = {};
    for (final task in tasks) {
      final key = DateFormat('EEEE, d MMMM yyyy').format(task.scheduledTime);
      grouped.putIfAbsent(key, () => []).add(task);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final dateLabel = grouped.keys.elementAt(i);
        final dayTasks = grouped[dateLabel]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
            ...dayTasks.map((task) => _TaskCard(task: task)),
          ],
        );
      },
    );
  }
}

// ── Task Card ──────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final StudyTask task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(task.scheduledTime);
    final isOverdue =
        !task.isCompleted && task.scheduledTime.isBefore(DateTime.now());

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) =>
          context.read<StudyPlanProvider>().deleteTask(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? Colors.green.shade50
              : isOverdue
                  ? Colors.red.shade50
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: task.isCompleted
                ? Colors.green.shade200
                : isOverdue
                    ? Colors.red.shade200
                    : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: GestureDetector(
            onTap: () =>
                context.read<StudyPlanProvider>().toggleComplete(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isCompleted
                    ? Colors.green
                    : Colors.grey.shade200,
                border: Border.all(
                  color: task.isCompleted
                      ? Colors.green
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Icon(
                task.isCompleted
                    ? Icons.check_rounded
                    : isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.circle_outlined,
                color: task.isCompleted
                    ? Colors.white
                    : isOverdue
                        ? Colors.red
                        : Colors.transparent,
                size: 20,
              ),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              decoration:
                  task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    isOverdue && !task.isCompleted
                        ? Icons.timer_off_rounded
                        : Icons.access_time_rounded,
                    size: 14,
                    color: isOverdue && !task.isCompleted
                        ? Colors.red
                        : Colors.deepPurple,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOverdue && !task.isCompleted
                          ? Colors.red
                          : Colors.deepPurple,
                    ),
                  ),
                  if (isOverdue && !task.isCompleted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                  if (task.isCompleted) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '✓ DONE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              task.isCompleted
                  ? Icons.undo_rounded
                  : Icons.check_circle_outline_rounded,
              color: task.isCompleted ? Colors.grey : Colors.green,
            ),
            onPressed: () =>
                context.read<StudyPlanProvider>().toggleComplete(task),
            tooltip: task.isCompleted ? 'Mark Incomplete' : 'Mark Complete',
          ),
        ),
      ),
    );
  }
}
