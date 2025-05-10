// Full Flutter Sigil Generator – v1.0.0-Ordo.Sigilorum
import 'package:flutter/material.dart';
import 'dart:math';

class SigilGeneratorScreen extends StatefulWidget {
  const SigilGeneratorScreen({super.key});

  @override
  State<SigilGeneratorScreen> createState() => _SigilGeneratorScreenState();
}

class _SigilGeneratorScreenState extends State<SigilGeneratorScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _pathAnimationController;
  late Animation<double> _pathAnimation;
  late AnimationController _circleAnimationController;
  late Animation<double> _circleAnimation;

  Path _sigilPath = Path();
  List<Offset> _circlePoints = [];
  String _reduced = '';
  String _input = '';
  bool _showReduction = false;
  List<Widget> _flyingLetterWidgets = [];

  @override
  void initState() {
    super.initState();

    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    );

    _circleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_pathAnimationController)
      ..addListener(() {
        setState(() {});
      });

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_circleAnimationController)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pathAnimationController.dispose();
    _circleAnimationController.dispose();
    super.dispose();
  }

  void _generateSigil() async {
    final input = _controller.text.toUpperCase();
    final noVowels = input.replaceAll(RegExp(r'[AEIOU\s]'), '');
    final seen = <String>{};
    final reduced = noVowels.split('').where((char) => seen.add(char)).join();

    final removedChars = input.split('').where((char) => !reduced.contains(char) && char != ' ').toList();

    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random();

    setState(() {
      _input = input;
      _reduced = reduced;
      _showReduction = true;
      _circlePoints.clear();
      _sigilPath = Path();
      _flyingLetterWidgets = removedChars.map((char) {
        final angle = random.nextDouble() * 2 * pi;
        final distance = 200 + random.nextDouble() * 300;
        final target = Offset(
          center.dx + distance * cos(angle),
          center.dy + distance * sin(angle) + 100,
        );
        return FlyingLetterWidget(
          char: char,
          start: center,
          end: target,
          duration: const Duration(milliseconds: 1800),
        );
      }).toList();
    });

    await Future.delayed(const Duration(milliseconds: 1900));

    setState(() {
      _flyingLetterWidgets = [];
    });

    await Future.delayed(const Duration(milliseconds: 300));

    _circlePoints = generateCirclePoints(reduced);
    final path = generateSigilPath(reduced, _circlePoints);

    setState(() {
      _sigilPath = path;
      _showReduction = false;
    });

    _pathAnimationController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 8000));
    _circleAnimationController.forward(from: 0.0);
  }

  List<Offset> generateCirclePoints(String input) {
    final length = input.length;
    final angleStep = 2 * pi / length;
    final radius = 100.0;
    final random = Random(input.hashCode);

    return List.generate(length, (i) {
      final angle = angleStep * i;
      final jitter = random.nextDouble() * 10;
      final r = radius + jitter;
      return Offset(r * cos(angle), r * sin(angle));
    });
  }

  Path generateSigilPath(String input, List<Offset> points) {
    if (points.length < 2) return Path();
    final random = Random(input.hashCode);
    final visited = <int>{};
    final pathOrder = <int>[];
    int current = random.nextInt(points.length);

    while (visited.length < points.length) {
      pathOrder.add(current);
      visited.add(current);
      final candidates = List.generate(points.length, (i) => i).where((i) => !visited.contains(i)).toList();
      if (candidates.isEmpty) break;
      final farCandidates = candidates.where((i) => (i - current).abs() >= points.length ~/ 3).toList();
      current = farCandidates.isNotEmpty ? farCandidates[random.nextInt(farCandidates.length)] : candidates[random.nextInt(candidates.length)];
    }

    final path = Path()..moveTo(points[pathOrder[0]].dx, points[pathOrder[0]].dy);
    for (final i in pathOrder.skip(1)) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Sigil Generator', style: TextStyle(color: Colors.redAccent)),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your intention...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _generateSigil,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('Create Sigil'),
                ),
                const SizedBox(height: 12),
                if (_showReduction)
                  Text(_reduced, style: const TextStyle(color: Colors.redAccent, fontSize: 22)),
                Expanded(
                  child: CustomPaint(
                    painter: AnimatedSigilPainter(
                      fullPath: _sigilPath,
                      progress: _pathAnimation.value,
                      circlePoints: _circlePoints,
                      circleProgress: _circleAnimation.value,
                    ),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),
          ..._flyingLetterWidgets,
        ],
      ),
    );
  }
}

class FlyingLetterWidget extends StatefulWidget {
  final String char;
  final Offset start;
  final Offset end;
  final Duration duration;

  const FlyingLetterWidget({required this.char, required this.start, required this.end, required this.duration, super.key});

  @override
  State<FlyingLetterWidget> createState() => _FlyingLetterWidgetState();
}

class _FlyingLetterWidgetState extends State<FlyingLetterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _position = Tween<Offset>(
      begin: widget.start,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 0.5),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 0.5),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _position.value.dx,
          top: _position.value.dy,
          child: Opacity(
            opacity: _opacity.value,
            child: Text(widget.char, style: const TextStyle(color: Colors.redAccent, fontSize: 18)),
          ),
        );
      },
    );
  }
}

class AnimatedSigilPainter extends CustomPainter {
  final Path fullPath;
  final double progress;
  final List<Offset> circlePoints;
  final double circleProgress;

  AnimatedSigilPainter({
    required this.fullPath,
    required this.progress,
    required this.circlePoints,
    required this.circleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final pointPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    for (final point in circlePoints) {
      canvas.drawCircle(point + center, 3, pointPaint);
    }

    final metrics = fullPath.computeMetrics().toList();
    for (final metric in metrics) {
      final extractLength = metric.length * progress;
      final partialPath = metric.extractPath(0, extractLength);

      final glowPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawPath(partialPath.shift(center), glowPaint);
    }

    if (circleProgress > 0) {
      final circlePaint = Paint()
        ..color = Colors.redAccent.withOpacity(circleProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 + 2 * circleProgress;

      canvas.drawCircle(center, 120, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedSigilPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.circleProgress != circleProgress || oldDelegate.circlePoints != circlePoints;
}
