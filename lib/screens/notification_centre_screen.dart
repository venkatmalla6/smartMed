import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/study_task.dart';
import '../providers/study_plan_provider.dart';
import '../services/notification_service.dart';

/// In-app notification centre shown when the bell icon is tapped.
/// Shows upcoming scheduled study sessions and overdue tasks.
class NotificationCentreScreen extends StatefulWidget {
  const NotificationCentreScreen({super.key});

  @override
  State<NotificationCentreScreen> createState() =>
      _NotificationCentreScreenState();
}

class _NotificationCentreScreenState extends State<NotificationCentreScreen> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final pending =
        await NotificationService().getPendingNotifications();
    if (mounted) setState(() => _pendingCount = pending.length);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyPlanProvider>();
    final now = DateTime.now();

    final overdue = provider.tasks
        .where((t) => !t.isCompleted && t.scheduledTime.isBefore(now))
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    final upcoming = provider.tasks
        .where((t) => !t.isCompleted && t.scheduledTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    final completed = provider.tasks
        .where((t) => t.isCompleted)
        .toList()
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.accentPurple.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '$_pendingCount scheduled',
                    style: const TextStyle(
                        color: AppTheme.accentPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: provider.tasks.isEmpty
          ? _emptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (overdue.isNotEmpty) ...[
                  _sectionHeader(
                      '⏰ Overdue', overdue.length, Colors.redAccent),
                  const SizedBox(height: 8),
                  ...overdue.map((t) => _TaskNotifCard(
                        task: t,
                        type: _CardType.overdue,
                      )),
                  const SizedBox(height: 20),
                ],
                if (upcoming.isNotEmpty) ...[
                  _sectionHeader(
                      '📅 Upcoming', upcoming.length, AppTheme.accentBlue),
                  const SizedBox(height: 8),
                  ...upcoming.map((t) => _TaskNotifCard(
                        task: t,
                        type: _CardType.upcoming,
                      )),
                  const SizedBox(height: 20),
                ],
                if (completed.isNotEmpty) ...[
                  _sectionHeader(
                      '✅ Completed', completed.length, AppTheme.accentGreen),
                  const SizedBox(height: 8),
                  ...completed
                      .take(5)
                      .map((t) => _TaskNotifCard(
                            task: t,
                            type: _CardType.completed,
                          )),
                ],
              ],
            ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 72,
              color: AppTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text(
            'No study tasks yet',
            style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go to Study Plan to add tasks.\nYou\'ll get reminders here.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, int count, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

enum _CardType { overdue, upcoming, completed }

class _TaskNotifCard extends StatelessWidget {
  final StudyTask task;
  final _CardType type;

  const _TaskNotifCard({required this.task, required this.type});

  @override
  Widget build(BuildContext context) {
    final Color accent = type == _CardType.overdue
        ? Colors.redAccent
        : type == _CardType.completed
            ? AppTheme.accentGreen
            : AppTheme.accentBlue;

    final IconData icon = type == _CardType.overdue
        ? Icons.warning_amber_rounded
        : type == _CardType.completed
            ? Icons.check_circle_rounded
            : Icons.schedule_rounded;

    final String timeLabel = type == _CardType.overdue
        ? 'Was due ${_formatRelative(task.scheduledTime)}'
        : type == _CardType.completed
            ? 'Completed · ${_formatDate(task.scheduledTime)}'
            : 'Due ${_formatRelative(task.scheduledTime)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  timeLabel,
                  style: TextStyle(
                      color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (type != _CardType.completed)
            IconButton(
              icon: const Icon(Icons.check_circle_outline_rounded,
                  color: AppTheme.accentGreen, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Mark complete',
              onPressed: () {
                context.read<StudyPlanProvider>().toggleComplete(task);
              },
            ),
        ],
      ),
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) {
      final ago = diff.abs();
      if (ago.inMinutes < 60) return '${ago.inMinutes}m ago';
      if (ago.inHours < 24) return '${ago.inHours}h ago';
      return '${ago.inDays}d ago';
    } else {
      if (diff.inMinutes < 60) return 'in ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'in ${diff.inHours}h';
      return DateFormat('MMM dd, hh:mm a').format(dt);
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('MMM dd • hh:mm a').format(dt);
  }
}
