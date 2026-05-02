import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/flashcard_provider.dart';
import 'flashcard_review_screen.dart';

class FlashcardDeckScreen extends StatefulWidget {
  const FlashcardDeckScreen({super.key});

  @override
  State<FlashcardDeckScreen> createState() => _FlashcardDeckScreenState();
}

class _FlashcardDeckScreenState extends State<FlashcardDeckScreen> {
  final TextEditingController _topicController = TextEditingController();

  void _showCreateDeckSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generate Flashcards',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Describe a medical topic to generate a new set of high-yield flashcards.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                hintText: 'e.g. Cranial Nerves, Type 2 Diabetes...',
                prefixIcon: Icon(Icons.psychology_outlined, color: AppTheme.accentPurple),
              ),
              onSubmitted: (val) => _handleGenerate(val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _handleGenerate(_topicController.text),
              child: const Text('Generate with AI ✦'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerate(String topic) async {
    if (topic.trim().isEmpty) return;
    Navigator.pop(context);
    _topicController.clear();

    try {
      await context.read<FlashcardProvider>().generateFlashcardsFromTopic(topic);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated new flashcards for $topic!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate cards: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Flashcard Decks'),
        centerTitle: true,
      ),
      body: Consumer<FlashcardProvider>(
        builder: (context, provider, _) {
          final decks = provider.getDecks();
          final dueCards = provider.getDueCards();

          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentPurple),
                  SizedBox(height: 16),
                  Text('Generating high-yield cards...', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Summary Card ──────────────────────────────────────
                _ReviewSummaryCard(
                  dueCount: dueCards.length,
                  onStartReview: () {
                    if (dueCards.isEmpty) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlashcardReviewScreen(cards: dueCards, deckTitle: 'Daily Review'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                const Text('My Decks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),

                if (decks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Column(
                        children: [
                          Icon(Icons.library_books_outlined, color: AppTheme.textSecondary.withValues(alpha: 0.3), size: 64),
                          const SizedBox(height: 16),
                          const Text('No decks yet.\nGenerate some to start studying!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: decks.length,
                    itemBuilder: (ctx, i) {
                      final title = decks.keys.elementAt(i);
                      final cards = decks[title]!;
                      final dueCount = provider.getDueCount(title);

                      return _DeckCard(
                        title: title,
                        cardCount: cards.length,
                        dueCount: dueCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FlashcardReviewScreen(cards: cards, deckTitle: title),
                            ),
                          );
                        },
                        onDelete: () => provider.deleteDeck(title),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDeckSheet,
        label: const Text('New Deck'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final int dueCount;
  final VoidCallback onStartReview;

  const _ReviewSummaryCard({required this.dueCount, required this.onStartReview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.accentPurple, Color(0xFFC084FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Due for Review', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('$dueCount Cards', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: dueCount > 0 ? onStartReview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.accentPurple,
              elevation: 0,
            ),
            child: const Text('Start Daily Review'),
          ),
        ],
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final String title;
  final int cardCount;
  final int dueCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeckCard({
    required this.title,
    required this.cardCount,
    required this.dueCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Deck?'),
            content: Text('Are you sure you want to delete the "$title" deck?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(onPressed: () {
                onDelete();
                Navigator.pop(ctx);
              }, child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E3A5F)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.topic_rounded, color: AppTheme.accentPurple, size: 20),
            ),
            const Spacer(),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('$cardCount cards', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                if (dueCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text('$dueCount due', style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
