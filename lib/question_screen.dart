import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'view_model.dart';

// Palet: biru Flutter + aksen oranye (private di file ini)
const Color _bgDark = Color(0xFF070D18);
const Color _cardColor = Color(0xFF0B2B55);
const Color _blue = Color(0xFF0175C2);
const Color _orange = Color(0xFFFF6D00);
const Color _tile = Color(0xFF111B2B);
const Color _correct = Color(0xFF3DDC84);
const Color _urgent = Color(0xFFFF5252);

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen>
    with SingleTickerProviderStateMixin {
  static const int _seconds = 20;

  late final QuizViewModel viewModel = QuizViewModel(
    onGameOver: _handleGameOver,
  );

  // Timer 20 detik (AnimationController 0 -> 1)
  late final AnimationController _timer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: _seconds),
  );

  final Set<int> _eliminated = {};
  bool _hintUsed = false;

  @override
  void initState() {
    super.initState();
    _timer.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        viewModel.timeUp();
      }
    });
    _timer.forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    viewModel.dispose();
    super.dispose();
  }

  void _onAnswer(int index) {
    if (viewModel.didAnswerQuestion) return;
    _timer.stop();
    viewModel.checkAnswer(index);
  }

  void _onNext() {
    setState(() => _eliminated.clear());
    viewModel.getNextQuestion();
    _timer.forward(from: 0);
  }

  // Hint 50:50: hilangkan dua jawaban salah (sekali per permainan)
  void _useHint() {
    final q = viewModel.currentQuestion;
    if (q == null || _hintUsed || viewModel.didAnswerQuestion) return;
    final wrong = [
      for (var i = 0; i < q.possibleAnswers.length; i++)
        if (i != q.correctAnswer) i,
    ]..shuffle();
    setState(() {
      _eliminated.addAll(wrong.take(2));
      _hintUsed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        final q = viewModel.currentQuestion;
        final answered = viewModel.didAnswerQuestion;
        final canNext = viewModel.hasNextQuestion && answered;

        return Scaffold(
          backgroundColor: _bgDark,
          body: Stack(
            children: [
              // Latar biru dengan tepi melengkung
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipPath(
                  clipper: _HeaderClipper(),
                  child: Container(height: 260, color: _blue),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Bar atas: tombol kembali + judul
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: Colors.white,
                            onPressed: () => Navigator.maybePop(context),
                          ),
                          const Text(
                            'Quiz Kilat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Perkiraan tinggi kartu soal + jarak (disisakan untuk jawaban)
                          const reserved = 330.0;
                          final count = (q?.possibleAnswers.length ?? 4).clamp(1, 6);
                          final tileHeight = ((constraints.maxHeight - reserved - 12 * count) /
                                  count)
                              .clamp(62.0, 112.0);

                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                QuestionCard(
                                  question: q?.question,
                                  number: viewModel.answeredQuestionCount,
                                  total: viewModel.totalQuestions,
                                  score: viewModel.score,
                                  timer: _timer,
                                  totalSeconds: _seconds,
                                  hintEnabled: !_hintUsed && !answered,
                                  onHint: _useHint,
                                ),
                                const SizedBox(height: 20),
                                AnswerList(
                                  question: q?.question ?? '',
                                  answers: q?.possibleAnswers ?? [],
                                  correctAnswer: answered ? q?.correctAnswer : null,
                                  selectedAnswer: viewModel.selectedAnswer,
                                  eliminated: _eliminated,
                                  tileHeight: tileHeight,
                                  onTapped: _onAnswer,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Tombol Next
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: _NextButton(enabled: canNext, onTap: _onNext),
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

  // Dialog akhir: muncul membal, skor menghitung naik.
  void _handleGameOver() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Game over',
        transitionDuration: const Duration(milliseconds: 600),
        transitionBuilder: (context, animation, secondary, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        pageBuilder: (context, animation, secondary) {
          final isWin = viewModel.score == viewModel.totalQuestions;
          return AlertDialog(
            backgroundColor: _cardColor,
            title: Row(
              children: [
                Icon(
                  isWin ? Icons.emoji_events_rounded : Icons.bolt_rounded,
                  color: _orange,
                  size: 30,
                ),
                const SizedBox(width: 8),
                Text(
                  isWin ? 'You Win!' : 'Game Over!',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: viewModel.score),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return Text(
                  '$value / ${viewModel.totalQuestions}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: _orange,
                        fontWeight: FontWeight.w800,
                      ),
                );
              },
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }
}

// ============================================================
// Pemotong latar biru (tepi bawah melengkung)
// ============================================================
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 50)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + 30,
        size.width,
        size.height - 50,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ============================================================
// KARTU SOAL (timer di atas, hint kiri, skor kanan)
// ============================================================
class QuestionCard extends StatelessWidget {
  final String? question;
  final int number;
  final int total;
  final int score;
  final Animation<double> timer;
  final int totalSeconds;
  final bool hintEnabled;
  final VoidCallback onHint;

  const QuestionCard({
    required this.question,
    required this.number,
    required this.total,
    required this.score,
    required this.timer,
    required this.totalSeconds,
    required this.hintEnabled,
    required this.onHint,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentKey = ValueKey(question);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 42),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _HintChip(enabled: hintEnabled, onTap: onHint),
                  _ScoreChip(score: score),
                ],
              ),
              const SizedBox(height: 6),
              // Isi kartu berganti dengan geser + fade
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final isIncoming = child.key == currentKey;
                    final begin = isIncoming
                        ? const Offset(1, 0)
                        : const Offset(-1, 0);
                    return SlideTransition(
                      position: Tween<Offset>(begin: begin, end: Offset.zero)
                          .animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: SizedBox(
                    key: currentKey,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Text.rich(
                          TextSpan(
                            text: 'Question ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                            children: [
                              TextSpan(
                                text: number.toString().padLeft(2, '0'),
                                style: const TextStyle(color: _orange),
                              ),
                              TextSpan(
                                text: ' / ${total.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Flutter Quiz',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        const _DashedLine(),
                        const SizedBox(height: 14),
                        Text(
                          question ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        TimerBadge(animation: timer, totalSeconds: totalSeconds),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(width: dashWidth, height: 1, color: Colors.white24),
          ),
        );
      },
    );
  }
}

class _HintChip extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _HintChip({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.35,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x33FF6D00),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_rounded, size: 16, color: _orange),
              SizedBox(width: 4),
              Text(
                'Hint',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Chip skor: ikon petir + angka yang membal saat bertambah
class _ScoreChip extends StatelessWidget {
  final int score;

  const _ScoreChip({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 18, color: _orange),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.elasticOut,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Text(
              '$score',
              key: ValueKey(score),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TIMER MELINGKAR (animasi eksplisit, buatan sendiri)
// ============================================================
class TimerBadge extends StatelessWidget {
  final Animation<double> animation;
  final int totalSeconds;

  const TimerBadge({
    required this.animation,
    required this.totalSeconds,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final remaining = 1 - animation.value;
        final secondsLeft = (remaining * totalSeconds).ceil();
        final isUrgent = secondsLeft <= 5 && remaining > 0;
        final color = isUrgent ? _urgent : _orange;
        // Berdenyut sekali per detik saat waktu hampir habis
        final pulse = isUrgent
            ? 1 + 0.07 * math.sin(remaining * totalSeconds * 2 * math.pi)
            : 1.0;

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _blue,
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _bgDark,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: CircularProgressIndicator(
                        value: remaining,
                        strokeWidth: 5,
                        color: color,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ),
                  Text(
                    '$secondsLeft',
                    style: TextStyle(
                      color: isUrgent ? _urgent : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// DAFTAR JAWABAN
// ============================================================
enum AnswerState { idle, correct, wrong }

class AnswerList extends StatelessWidget {
  final String question;
  final List<String> answers;
  final int? correctAnswer;
  final int? selectedAnswer;
  final Set<int> eliminated;
  final ValueChanged<int> onTapped;
  final double tileHeight;

  const AnswerList({
    required this.question,
    required this.answers,
    required this.correctAnswer,
    required this.selectedAnswer,
    required this.eliminated,
    required this.tileHeight,
    required this.onTapped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(answers.length, (index) {
        var state = AnswerState.idle;
        if (correctAnswer != null) {
          if (index == correctAnswer) {
            state = AnswerState.correct;
          } else if (index == selectedAnswer) {
            state = AnswerState.wrong;
          }
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: tileHeight,
            child: AnswerTile(
              // Key berisi soal supaya animasi masuk jalan lagi tiap soal baru
              key: ValueKey('$question#$index'),
              index: index,
              text: answers[index],
              state: state,
              eliminated: eliminated.contains(index),
              onTap: () => onTapped(index),
            ),
          ),
        );
      }),
    );
  }
}

class AnswerTile extends StatefulWidget {
  final int index;
  final String text;
  final AnswerState state;
  final bool eliminated;
  final VoidCallback onTap;

  const AnswerTile({
    required this.index,
    required this.text,
    required this.state,
    required this.eliminated,
    required this.onTap,
    super.key,
  });

  @override
  State<AnswerTile> createState() => _AnswerTileState();
}

class _AnswerTileState extends State<AnswerTile> with TickerProviderStateMixin {
  // Animasi masuk bertahap (staggered)
  late final AnimationController _enter;
  late final Animation<double> _enterAnim;

  // Getar saat salah
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final start = math.min(widget.index * 0.12, 0.4);
    _enterAnim = CurvedAnimation(
      parent: _enter,
      curve: Interval(start, start + 0.6, curve: Curves.easeOutCubic),
    );
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _enter.forward();
  }

  @override
  void didUpdateWidget(covariant AnswerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state && widget.state == AnswerState.wrong) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _shake.dispose();
    super.dispose();
  }

  Widget _trailing() {
    if (widget.state == AnswerState.correct) {
      return _iconCircle(const ValueKey('ok'), _correct, Icons.check_rounded);
    }
    if (widget.state == AnswerState.wrong) {
      return _iconCircle(const ValueKey('no'), _orange, Icons.close_rounded);
    }
    return Container(
      key: const ValueKey('idle'),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
    );
  }

  Widget _iconCircle(Key key, Color color, IconData icon) {
    return Container(
      key: key,
      width: 28,
      height: 28,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color fill = _tile;
    Color border = Colors.white12;
    Color textColor = Colors.white;
    if (widget.state == AnswerState.correct) {
      fill = const Color(0xFF123524);
      border = _correct;
      textColor = _correct;
    } else if (widget.state == AnswerState.wrong) {
      fill = const Color(0xFF3A1F0C);
      border = _orange;
      textColor = _orange;
    }

    return FadeTransition(
      opacity: _enterAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.25, 0),
          end: Offset.zero,
        ).animate(_enterAnim),
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final dx =
                math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: AnimatedOpacity(
            opacity: widget.eliminated ? 0.25 : 1,
            duration: const Duration(milliseconds: 400),
            child: IgnorePointer(
              ignoring: widget.eliminated,
              child: AnimatedScale(
                scale: widget.state == AnswerState.correct
                    ? 1.03
                    : (widget.eliminated ? 0.96 : 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: widget.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: widget.eliminated
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: Colors.white54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              switchInCurve: Curves.elasticOut,
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: _trailing(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TOMBOL NEXT
// ============================================================
class _NextButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _NextButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: double.infinity,
      decoration: BoxDecoration(
        color: enabled ? _orange : const Color(0xFF2A3547),
        borderRadius: BorderRadius.circular(30),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: _orange.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white38,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
                child: const Text('Next'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}