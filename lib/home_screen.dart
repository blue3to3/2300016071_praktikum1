import 'dart:math' as math;
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'question_screen.dart';

const Color kTealDark = Color(0xFF02315E);
const Color kTeal = Color(0xFF0175C2);
const Color kCyan = Color(0xFF54C5F8);
const Color kOrange = Color(0xFFFF6D00);
const Color kOrangeLight = Color(0xFFFFA726);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Animasi masuk (sekali jalan)
  late final AnimationController _entry;
  // Animasi looping (background, ikon melayang, cincin, panah)
  late final AnimationController _loop;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconRotation;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _chipsFade;
  late final Animation<Offset> _chipsSlide;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonFade;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    Animation<double> interval(double a, double b, Curve c) =>
        CurvedAnimation(parent: _entry, curve: Interval(a, b, curve: c));

    _iconScale = Tween<double>(begin: 0.3, end: 1.0)
        .animate(interval(0.0, 0.5, Curves.elasticOut));
    _iconRotation = Tween<double>(begin: -0.12, end: 0.0)
        .animate(interval(0.0, 0.5, Curves.easeOutBack));

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(interval(0.25, 0.65, Curves.easeOutCubic));
    _titleFade = Tween<double>(begin: 0, end: 1)
        .animate(interval(0.25, 0.6, Curves.easeIn));

    _chipsSlide = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero)
        .animate(interval(0.5, 0.85, Curves.easeOutCubic));
    _chipsFade = Tween<double>(begin: 0, end: 1)
        .animate(interval(0.5, 0.8, Curves.easeIn));

    _buttonSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(interval(0.7, 1.0, Curves.easeOutBack));
    _buttonFade = Tween<double>(begin: 0, end: 1)
        .animate(interval(0.7, 0.95, Curves.easeIn));

    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _startGame(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const QuestionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.scaled,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ================= BACKGROUND =================
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kTealDark, kTeal],
                ),
              ),
            ),
          ),
          _buildFloatingBlobs(context),

          // ================= KONTEN =================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 16),
                    _buildTitle(),
                    const SizedBox(height: 28),
                    _buildChips(),
                    const SizedBox(height: 40),
                    _buildButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lingkaran-lingkaran dekoratif yang melayang pelan
  Widget _buildFloatingBlobs(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) {
        final t = _loop.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              left: -60 + math.sin(t) * 20,
              top: size.height * 0.08 + math.cos(t) * 25,
              child: _blob(200, kCyan.withValues(alpha: 0.18)),
            ),
            Positioned(
              right: -80 + math.cos(t) * 25,
              top: size.height * 0.45 + math.sin(t) * 30,
              child: _blob(240, kOrange.withValues(alpha: 0.14)),
            ),
            Positioned(
              left: size.width * 0.2 + math.sin(t + 2) * 30,
              bottom: -70 + math.cos(t + 1) * 20,
              child: _blob(180, Colors.white.withValues(alpha: 0.08)),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // Ikon petir: muncul membal, lalu melayang + cincin berdenyut
  Widget _buildIcon() {
    return ScaleTransition(
      scale: _iconScale,
      child: RotationTransition(
        turns: _iconRotation,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, child) {
            final float = math.sin(_loop.value * 2 * math.pi) * 8;
            return SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _ring((_loop.value * 2) % 1),
                  _ring((_loop.value * 2 + 0.5) % 1),
                  Transform.translate(offset: Offset(0, float), child: child),
                ],
              ),
            );
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kOrangeLight, kOrange],
              ),
              boxShadow: [
                BoxShadow(
                  color: kOrange.withValues(alpha: 0.45),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, size: 70, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Satu cincin yang membesar lalu memudar (t = 0..1)
  Widget _ring(double t) {
    final diameter = 120 + 100 * t;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: kOrangeLight.withValues(alpha: (1 - t) * 0.6),
          width: 3,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _titleFade,
      child: SlideTransition(
        position: _titleSlide,
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFBFE9FF)],
              ).createShader(bounds),
              child: const Text(
                'Quiz Kilat',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uji pengetahuan Flutter-mu!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChips() {
    return FadeTransition(
      opacity: _chipsFade,
      child: SlideTransition(
        position: _chipsSlide,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: const [
            _FeatureChip(
              icon: Icons.shuffle_rounded,
              label: 'Soal acak',
              info: 'Urutan soal diacak setiap kali kamu bermain.',
            ),
            _FeatureChip(
              icon: Icons.bolt_rounded,
              label: 'Skor petir',
              info: 'Setiap jawaban benar menyalakan satu petir.',
            ),
            _FeatureChip(
              icon: Icons.animation_rounded,
              label: 'Animasi',
              info: 'Getar saat salah, skor menghitung naik, dan lainnya.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return FadeTransition(
      opacity: _buttonFade,
      child: SlideTransition(
        position: _buttonSlide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _startGame(context);
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.93 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kOrange, kOrangeLight]),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: kOrange.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mulai Kuis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Panah yang bergerak terus ke kanan
                  AnimatedBuilder(
                    animation: _loop,
                    builder: (context, child) {
                      final dx = math.sin(_loop.value * 4 * math.pi) * 5;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final String info;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.info,
  });

  @override
  State<_FeatureChip> createState() => _FeatureChipState();
}

class _FeatureChipState extends State<_FeatureChip> {
  bool _pressed = false;

  void _showInfo() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.info),
          behavior: SnackBarBehavior.floating,
          backgroundColor: kTealDark,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showInfo();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _pressed ? 0.25 : 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: kOrangeLight),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}