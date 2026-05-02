import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/flashcard.dart';
import '../providers/flashcard_provider.dart';

class FlashcardReviewScreen extends StatefulWidget {
  final List<Flashcard> cards;
  final String deckTitle;

  const FlashcardReviewScreen({super.key, required this.cards, required this.deckTitle});

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> with SingleTickerProviderStateMixin {
  late List<Flashcard> _reviewQueue;
  int _currentIndex = 0;
  bool _isFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _reviewQueue = List.from(widget.cards)..shuffle();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _handleScore(int quality) async {
    final currentCard = _reviewQueue[_currentIndex];
    await context.read<FlashcardProvider>().reviewCard(currentCard, quality);

    if (_currentIndex < _reviewQueue.length - 1) {
      // Move to next card
      _flipController.reverse();
      setState(() {
        _isFlipped = false;
        _currentIndex++;
      });
    } else {
      // Session finished
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Complete! 🎉'),
        content: const Text('Great job! You\'ve finished reviewing this deck. Your progress has been saved.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Back to Decks'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewQueue.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bgDeep,
        appBar: AppBar(title: Text(widget.deckTitle)),
        body: const Center(child: Text('No cards to review!')),
      );
    }

    final currentCard = _reviewQueue[_currentIndex];
    final progress = (_currentIndex + 1) / _reviewQueue.length;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text(widget.deckTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF1E3A5F),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentPurple),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (ctx, child) {
                    final isBack = _flipAnimation.value > pi / 2;
                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_flipAnimation.value),
                      alignment: Alignment.center,
                      child: isBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _CardSide(text: currentCard.back, isBack: true),
                            )
                          : _CardSide(text: currentCard.front, isBack: false),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (!_isFlipped)
              const Text('Tap card to flip', style: TextStyle(color: AppTheme.textSecondary))
            else
              _ActionButtons(onScore: _handleScore),
          ],
        ),
      ),
    );
  }
}

class _CardSide extends StatelessWidget {
  final String text;
  final bool isBack;

  const _CardSide({required this.text, required this.isBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isBack ? AppTheme.accentPurple.withValues(alpha: 0.5) : const Color(0xFF1E3A5F),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: isBack ? FontWeight.w500 : FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Function(int) onScore;

  const _ActionButtons({required this.onScore});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('How well did you know this?',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreButton(label: 'Again', color: Colors.redAccent, score: 1, onTap: () => onScore(1)),
            _ScoreButton(label: 'Hard', color: Colors.orangeAccent, score: 3, onTap: () => onScore(3)),
            _ScoreButton(label: 'Good', color: AppTheme.accentBlue, score: 4, onTap: () => onScore(4)),
            _ScoreButton(label: 'Easy', color: AppTheme.accentGreen, score: 5, onTap: () => onScore(5)),
          ],
        ),
      ],
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final String label;
  final Color color;
  final int score;
  final VoidCallback onTap;

  const _ScoreButton({required this.label, required this.color, required this.score, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(child: Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
