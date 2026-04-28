import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mcq.dart';
import '../models/quiz.dart';
import '../models/quiz_attempt.dart';
import '../providers/quiz_provider.dart';
import '../core/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final List<McqQuestion> questions;
  final String sourceTitle;
  final String? quizId;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.sourceTitle,
    this.quizId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String? _selectedOption;
  bool _answered = false;
  int _score = 0;
  bool _showResults = false;

  late final AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  McqQuestion get _current => widget.questions[_currentIndex];
  int get _total => widget.questions.length;

  void _selectOption(String option) {
    if (_answered) return;
    final correct = option == _current.answer;
    setState(() {
      _selectedOption = option;
      _answered = true;
      if (correct) _score++;
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < _total - 1) {
      await _animController.reverse();
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
      _animController.forward();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    setState(() => _showResults = true);

    if (widget.quizId != null) {
      final attempt = QuizAttempt(
        score: _score,
        totalQuestions: _total,
        date: DateTime.now(),
      );
      Provider.of<QuizProvider>(context, listen: false)
          .logAttempt(widget.quizId!, attempt);
    }
  }

  void _restartQuiz() {
    _animController.forward(from: 0);
    setState(() {
      _currentIndex = 0;
      _selectedOption = null;
      _answered = false;
      _score = 0;
      _showResults = false;
    });
  }

  Color _optionColor(String option) {
    if (!_answered) return Colors.white;
    if (option == _current.answer) return const Color(0xFF10B981); // correct = emerald
    if (option == _selectedOption) return const Color(0xFFEF4444); // wrong = red
    return Colors.white;
  }

  Color _optionTextColor(String option) {
    if (!_answered) return AppTheme.textPrimary;
    if (option == _current.answer || option == _selectedOption) {
      return Colors.white;
    }
    return AppTheme.textSecondary;
  }

  IconData? _optionIcon(String option) {
    if (!_answered) return null;
    if (option == _current.answer) return Icons.check_circle_rounded;
    if (option == _selectedOption) return Icons.cancel_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showResults ? _buildResults() : _buildQuiz(),
    );
  }

  // ── Quiz Body ──────────────────────────────────────────────────────────────

  Widget _buildQuiz() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionCard(),
                    const SizedBox(height: 20),
                    ..._current.options.map(_buildOptionTile),
                    const SizedBox(height: 24),
                    if (_answered) _buildNextButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final progress = (_currentIndex + 1) / _total;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _confirmExit(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.sourceTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / $_total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Question ${_currentIndex + 1}',
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _current.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String option) {
    final isSelected = _selectedOption == option;
    final bgColor = _optionColor(option);
    final textColor = _optionTextColor(option);
    final icon = _optionIcon(option);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectOption(option),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _answered && option == _current.answer
                      ? const Color(0xFF10B981)
                      : _answered && option == _selectedOption
                          ? const Color(0xFFEF4444)
                          : isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.grey.shade200,
                  width: isSelected || (_answered && option == _current.answer)
                      ? 2
                      : 1,
                ),
                boxShadow: (_answered &&
                        (option == _current.answer ||
                            option == _selectedOption))
                    ? [
                        BoxShadow(
                          color: bgColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 20),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentIndex == _total - 1;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _nextQuestion,
        icon: Icon(isLast ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded),
        label: Text(isLast ? 'See Results' : 'Next Question'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  // ── Results Body ───────────────────────────────────────────────────────────

  Widget _buildResults() {
    final percent = (_score / _total * 100).round();
    final grade = _getGrade(percent);

    return Scaffold(
      body: Column(
        children: [
          // Results header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: grade.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.sourceTitle,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      grade.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      grade.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      grade.message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Score card
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatBubble(
                          value: '$_score',
                          label: 'Correct',
                          color: const Color(0xFF10B981),
                        ),
                        _StatBubble(
                          value: '${_total - _score}',
                          label: 'Wrong',
                          color: const Color(0xFFEF4444),
                        ),
                        _StatBubble(
                          value: '$percent%',
                          label: 'Score',
                          color: const Color(0xFF6366F1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // Progress arc (simple linear)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _score / _total,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            grade.gradientColors.first),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _restartQuiz,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(
                                  color: Color(0xFF6366F1), width: 2),
                              foregroundColor: const Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (widget.quizId == null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _saveQuiz(context),
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Save Quiz'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.home_rounded),
                              label: const Text('Done'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _Grade _getGrade(int percent) {
    if (percent >= 90) {
      return _Grade(
        emoji: '🏆',
        label: 'Excellent!',
        message: 'Outstanding performance. You\'ve mastered this topic!',
        gradientColors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
      );
    } else if (percent >= 70) {
      return _Grade(
        emoji: '🎉',
        label: 'Great Job!',
        message: 'You have a solid understanding of the material.',
        gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
      );
    } else if (percent >= 50) {
      return _Grade(
        emoji: '📚',
        label: 'Good Effort',
        message: 'Review the material and try again for a better score.',
        gradientColors: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      );
    } else {
      return _Grade(
        emoji: '💪',
        label: 'Keep Going!',
        message: 'Don\'t give up — revisit the notes and try again.',
        gradientColors: const [Color(0xFF64748B), Color(0xFF475569)],
      );
    }
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text('Your current progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Quiz'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Quit', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _saveQuiz(BuildContext context) {
    final titleController = TextEditingController(text: widget.sourceTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Quiz Title',
                border: OutlineInputBorder(),
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
              final title = titleController.text.trim();
              if (title.isEmpty) return;

              final attempt = QuizAttempt(
                score: _score,
                totalQuestions: _total,
                date: DateTime.now(),
              );

              final quiz = Quiz(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title,
                questions: widget.questions,
                createdAt: DateTime.now(),
                attempts: [attempt],
              );

              Provider.of<QuizProvider>(context, listen: false).addQuiz(quiz);

              Navigator.pop(ctx);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quiz saved successfully!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _StatBubble extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBubble({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Grade {
  final String emoji;
  final String label;
  final String message;
  final List<Color> gradientColors;

  const _Grade({
    required this.emoji,
    required this.label,
    required this.message,
    required this.gradientColors,
  });
}
