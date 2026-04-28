import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'add_note_screen.dart';
import 'saved_notes_screen.dart';
import 'saved_quizzes_screen.dart';
import 'translator_screen.dart';
import 'study_plan_screen.dart';
import '../core/app_theme.dart';
import '../providers/quiz_provider.dart';
import '../providers/study_plan_provider.dart';
import '../services/extraction_service.dart';
import '../utils/quiz_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  // ─── file extraction ──────────────────────────────────────────────────────
  Future<void> _handleFileExtraction(BuildContext ctx) async {
    final svc = ExtractionService();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.single.path == null) return;
      setState(() => _isLoading = true);
      final path = result.files.single.path!;
      final ext = path.split('.').last.toLowerCase();
      final text = ext == 'pdf'
          ? await svc.extractTextFromPdf(path)
          : await svc.extractTextFromImage(path);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('No text could be extracted.')),
        );
        return;
      }
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => AddNoteScreen(initialContent: text)));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), duration: const Duration(seconds: 6)),
        );
      }
    } finally {
      svc.dispose();
    }
  }

  void _showQuickQuizDialog(BuildContext ctx) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Quick Quiz'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your study text below:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(controller: ctrl, maxLines: 5, minLines: 3,
              decoration: const InputDecoration(hintText: 'Paste study material here...')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(dialogCtx);
              launchQuizGeneration(context: ctx, text: ctrl.text, sourceTitle: 'Quick Quiz');
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        onExtract: () => _handleFileExtraction(context),
        onQuickQuiz: () => _showQuickQuizDialog(context),
      ),
      const SavedNotesScreen(),
      const StudyPlanScreen(),
      const SavedQuizzesScreen(),
    ];
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          IndexedStack(index: _currentTab, children: pages),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(20)),
                  child: const Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: AppTheme.accentBlue),
                    SizedBox(height: 20),
                    Text('Extracting text...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 6),
                    Text('Scanned PDFs may take longer', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ]),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
      ),
    );
  }
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.note_rounded, 'Notes'),
      (Icons.calendar_month_rounded, 'Plan'),
      (Icons.quiz_rounded, 'Quizzes'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        border: const Border(top: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == current;
              final isCenter = i == 1; // "Notes" gets the big pill treatment... actually let's keep simple
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: selected
                      ? BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.accentBlue, AppTheme.accentPurple]),
                          borderRadius: BorderRadius.circular(20),
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, color: selected ? Colors.white : AppTheme.textSecondary, size: 24),
                      const SizedBox(height: 4),
                      Text(items[i].$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppTheme.textSecondary,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final VoidCallback onExtract;
  final VoidCallback onQuickQuiz;
  const _HomeTab({required this.onExtract, required this.onQuickQuiz});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          _Header(),
          // ── Welcome Banner ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _WelcomeBanner(),
          ),
          const SizedBox(height: 28),
          // ── Quick Actions ────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text('Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _QuickActionsGrid(onExtract: onExtract, onQuickQuiz: onQuickQuiz),
          ),
          const SizedBox(height: 28),
          // ── Today's Progress ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _TodayProgress(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── App Header ───────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Row(
          children: [
            const Icon(Icons.menu_rounded, color: AppTheme.textPrimary, size: 26),
            const SizedBox(width: 12),
            // Logo text
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(text: 'Smart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextSpan(text: 'Med', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.accentBlue)),
                  TextSpan(text: ' ✦', style: TextStyle(fontSize: 16, color: AppTheme.accentBlue)),
                ],
              ),
            ),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary, size: 26),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppTheme.accentBlue, AppTheme.accentPurple]),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Welcome Banner ───────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.gradientBanner,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(right: -20, top: -20,
            child: Container(width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ))),
          Positioned(right: 40, bottom: -30,
            child: Container(width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ))),
          // Stethoscope icon area
          Positioned(
            right: 16, top: 0, bottom: 0,
            child: Center(
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.local_hospital_rounded, size: 48, color: Colors.white),
              ),
            ),
          ),
          // Text
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 110, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Future Doctor 🩺',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text("Let's achieve your study goals for today!",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const StudyPlanScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('View Study Plan',
                            style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, color: Color(0xFF1E3A8A), size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Grid ───────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onExtract;
  final VoidCallback onQuickQuiz;
  const _QuickActionsGrid({required this.onExtract, required this.onQuickQuiz});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ActionCardData(
        title: 'Translate',
        subtitle: 'Russian/Kazakh\nto English',
        icon: Icons.translate_rounded,
        gradientColors: AppTheme.gradientTranslate,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslatorScreen())),
      ),
      _ActionCardData(
        title: 'AI Quiz',
        subtitle: 'Generate quiz\nfrom notes',
        icon: Icons.quiz_rounded,
        gradientColors: AppTheme.gradientQuiz,
        onTap: onQuickQuiz,
      ),
      _ActionCardData(
        title: 'PDF to MCQs',
        subtitle: 'Extract MCQs from\nPDFs',
        icon: Icons.picture_as_pdf_rounded,
        gradientColors: AppTheme.gradientPdf,
        onTap: onExtract,
      ),
      _ActionCardData(
        title: 'My Notes',
        subtitle: 'View and manage\nyour notes',
        icon: Icons.note_rounded,
        gradientColors: AppTheme.gradientNotes,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedNotesScreen())),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.95,
      children: cards.map((c) => _ActionCard(data: c)).toList(),
    );
  }
}

class _ActionCardData {
  final String title, subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  const _ActionCardData({
    required this.title, required this.subtitle,
    required this.icon, required this.gradientColors, required this.onTap,
  });
}

class _ActionCard extends StatefulWidget {
  final _ActionCardData data;
  const _ActionCard({required this.data});
  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120),
        lowerBound: 0.95, upperBound: 1.0, value: 1.0);
    _scale = _ctrl;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) { _ctrl.forward(); widget.data.onTap(); },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.data.gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.data.gradientColors.last.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              // Decorative circle
              Positioned(right: -10, bottom: -10,
                child: Container(width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.data.icon, color: Colors.white, size: 26),
                  ),
                  const Spacer(),
                  Text(widget.data.title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.data.subtitle,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Today's Progress ─────────────────────────────────────────────────────────
class _TodayProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<StudyPlanProvider, QuizProvider>(
      builder: (context, planProvider, quizProvider, _) {
        final total = planProvider.tasks.length;
        final done = planProvider.completedTasks.length;
        final pct = total == 0 ? 0.0 : done / total;
        final quizCount = quizProvider.quizzes.length;
        // streak: days with at least one completed task (simplified)
        final streak = done > 0 ? min(done, 7) : 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF1E3A5F)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text("Today's Progress",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyPlanScreen())),
                    child: const Row(children: [
                      Text('View Details', style: TextStyle(color: AppTheme.accentBlue, fontSize: 13)),
                      Icon(Icons.chevron_right_rounded, color: AppTheme.accentBlue, size: 18),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Circular progress
                  SizedBox(
                    width: 72, height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72, height: 72,
                          child: CircularProgressIndicator(
                            value: pct,
                            strokeWidth: 6,
                            backgroundColor: const Color(0xFF1E3A5F),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                          ),
                        ),
                        Text('${(pct * 100).round()}%',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(icon: Icons.menu_book_rounded, color: AppTheme.accentBlue,
                            value: '$done', label: 'Topics\nStudied'),
                        _StatItem(icon: Icons.quiz_rounded, color: AppTheme.accentPurple,
                            value: '$quizCount', label: 'Quizzes\nSolved'),
                        _StatItem(icon: Icons.local_fire_department_rounded, color: Colors.orange,
                            value: '$streak', label: 'Day\nStreak'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  const _StatItem({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}
