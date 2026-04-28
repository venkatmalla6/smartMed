import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/quiz_provider.dart';
import 'quiz_screen.dart';
import '../core/app_theme.dart';

class SavedQuizzesScreen extends StatelessWidget {
  const SavedQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quizzes'),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          final quizzes = quizProvider.quizzes;

          if (quizzes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No saved quizzes yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          questions: quiz.questions,
                          sourceTitle: quiz.title,
                          quizId: quiz.id,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                quiz.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () => _confirmDelete(context, quiz.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created: ${DateFormat('MMM dd, yyyy').format(quiz.createdAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildChip(
                              Icons.format_list_numbered_rounded,
                              '${quiz.totalQuestions} Questions',
                              Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            _buildChip(
                              Icons.star_rounded,
                              'Best: ${quiz.bestScore}/${quiz.totalQuestions}',
                              Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            _buildChip(
                              Icons.history_rounded,
                              '${quiz.attempts.length} Attempts',
                              Colors.purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String quizId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz?'),
        content: const Text('Are you sure you want to delete this quiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<QuizProvider>(context, listen: false).deleteQuiz(quizId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
