import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'saved_notes_screen.dart';
import 'saved_quizzes_screen.dart';
import 'translator_screen.dart';
import 'study_plan_screen.dart';
import 'notification_centre_screen.dart';
import 'profile_screen.dart';
import 'flashcard_deck_screen.dart';

import '../core/app_theme.dart';
import '../providers/quiz_provider.dart';
import '../providers/study_plan_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/quiz_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  bool _isLoading = false;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
  }



  void _showQuizSourceSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          left: 24, right: 24, top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generate AI Quiz',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choose how you want to generate your multiple choice questions.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            
            // Option 1: PDF Upload
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
              ),
              title: const Text('Upload PDF', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              subtitle: const Text('Extract MCQs directly from a PDF file', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                if (result != null && result.files.single.path != null) {
                  final path = result.files.single.path!;
                  // Show loading and process pdf
                  if (!ctx.mounted) return;
                  launchQuizGenerationFromPdf(context: ctx, path: path);
                }
              },
            ),
            const Divider(color: Color(0xFF1E3A5F), height: 32),
            
            // Option 2: Topic Description
            const Text('Or, describe a topic:', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _TopicInputArea(
              onSubmit: (topic) {
                Navigator.pop(sheetCtx);
                if (!ctx.mounted) return;
                launchQuizGenerationFromTopic(context: ctx, topic: topic);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeTab(
        onQuickQuiz: () => _showQuizSourceSheet(context),
      ),
      const SavedNotesScreen(),
      const StudyPlanScreen(),
      const SavedQuizzesScreen(),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentTab != 0) {
          setState(() => _currentTab = 0);
          return;
        }

        final now = DateTime.now();
        if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        drawer: _buildDrawer(context),
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
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.bgDeep,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppTheme.accentBlue, AppTheme.accentPurple]),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            Consumer<SettingsProvider>(
              builder: (context, provider, _) {
                final name = provider.userName.isEmpty ? 'Doctor' : provider.userName;
                return Text(
                  'Dr. $name',
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      // Already on home, maybe trigger setState to tab 0 if we passed it down
                      // For now, just close drawer.
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.note_rounded,
                    title: 'My Notes',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedNotesScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.calendar_month_rounded,
                    title: 'Study Plan',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyPlanScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.quiz_rounded,
                    title: 'Quizzes',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedQuizzesScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.psychology_outlined,
                    title: 'Flashcards (SRS)',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardDeckScreen()));
                    },
                  ),
                  _buildDrawerItem(

                    context,
                    icon: Icons.g_translate_rounded,
                    title: 'Medical Translator',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslatorScreen()));
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Notification Centre',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCentreScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textPrimary),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
      onTap: onTap,
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
  final VoidCallback onQuickQuiz;

  const _HomeTab({required this.onQuickQuiz});

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
            child: _QuickActionsGrid(onQuickQuiz: onQuickQuiz),
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
    return Consumer<StudyPlanProvider>(
      builder: (context, planProvider, _) {
        final overdueCount = planProvider.overdueTasks.length;
        return SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary, size: 26),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                ),
                const SizedBox(width: 4),
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
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppTheme.textPrimary, size: 26),
                      tooltip: 'Notifications',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationCentreScreen(),
                        ),
                      ),
                    ),
                    if (overdueCount > 0)
                      Positioned(
                        right: 6, top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            overdueCount > 9 ? '9+' : '$overdueCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    width: 38, height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppTheme.accentBlue, AppTheme.accentPurple]),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Welcome Banner ───────────────────────────────────────────────────────────
class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        final name = provider.userName.isEmpty ? 'Doctor' : provider.userName;
        final title = provider.userTitle; // e.g. "Dr.", "Mr.", "Ms.", "Mrs."
        
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
                    Text('$title $name 🩺',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
      },
    );
  }
}

// ─── Quick Actions Grid ───────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final VoidCallback onQuickQuiz;

  const _QuickActionsGrid({required this.onQuickQuiz});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ActionCardData(
        title: 'Translator',
        subtitle: 'Medical term\ntranslator',
        icon: Icons.translate_rounded,
        gradientColors: AppTheme.gradientTranslate,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TranslatorScreen())),
      ),
      _ActionCardData(
        title: 'Flashcards',
        subtitle: 'AI-Powered\nSRS Reviews',
        icon: Icons.psychology_outlined,
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFFD946EF)], // Purple/Pink gradient
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardDeckScreen())),
      ),
      _ActionCardData(
        title: 'AI Quiz',
        subtitle: 'Generate quiz\nfrom topic/PDF',
        icon: Icons.quiz_rounded,
        gradientColors: AppTheme.gradientQuiz,
        onTap: onQuickQuiz,
      ),
      _ActionCardData(
        title: 'Study Plan',
        subtitle: 'Manage your\ndaily tasks',
        icon: Icons.calendar_month_rounded,
        gradientColors: const [Color(0xFF8B5CF6), Color(0xFFC084FC)], // Purple gradient
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyPlanScreen())),
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
        // ── Today's tasks ────────────────────────────────────────────
        final todayTotal = planProvider.todaysTasks.length;
        final todayDone = planProvider.todaysCompleted.length;
        final pct = todayTotal == 0 ? 0.0 : todayDone / todayTotal;

        // ── Quizzes attempted today ──────────────────────────────────
        final today = DateTime.now();
        final quizTodayCount = quizProvider.quizzes
            .expand((q) => q.attempts)
            .where((a) =>
                a.date.year == today.year &&
                a.date.month == today.month &&
                a.date.day == today.day)
            .length;

        // ── Real consecutive-day streak ──────────────────────────────
        final streak = planProvider.streakDays;

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
              const SizedBox(height: 4),
              // Subtitle: today's task count
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  todayTotal == 0
                      ? 'No tasks scheduled today'
                      : '$todayDone of $todayTotal tasks done today',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              pct == 1.0
                                  ? AppTheme.accentGreen
                                  : AppTheme.accentBlue,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(pct * 100).round()}%',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            if (pct == 1.0 && todayTotal > 0)
                              const Text('✓',
                                  style: TextStyle(
                                      color: AppTheme.accentGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.menu_book_rounded,
                          color: AppTheme.accentBlue,
                          value: '$todayDone',
                          label: 'Topics\nToday',
                        ),
                        _StatItem(
                          icon: Icons.quiz_rounded,
                          color: AppTheme.accentPurple,
                          value: '$quizTodayCount',
                          label: 'Quizzes\nToday',
                        ),
                        _StatItem(
                          icon: Icons.local_fire_department_rounded,
                          color: streak > 0 ? Colors.orange : AppTheme.textSecondary,
                          value: '$streak',
                          label: 'Day\nStreak',
                        ),
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

class _TopicInputArea extends StatefulWidget {
  final void Function(String) onSubmit;
  const _TopicInputArea({required this.onSubmit});

  @override
  State<_TopicInputArea> createState() => _TopicInputAreaState();
}

class _TopicInputAreaState extends State<_TopicInputArea> {
  final TextEditingController _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _hasText = _ctrl.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          maxLines: 3,
          minLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g. "Cardiovascular system", "Types of anemia"...',
            hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppTheme.bgInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _hasText ? () {
            widget.onSubmit(_ctrl.text.trim());
          } : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppTheme.accentBlue,
            disabledBackgroundColor: AppTheme.bgInput,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Generate 20 MCQs',
            style: TextStyle(
              color: _hasText ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
