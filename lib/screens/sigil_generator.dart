// lib/screens/sigil_generator_screen.dart
// Full Flutter Sigil Generator – v1.0.4-Ordo.Sigilorum.FinalAesthetics
import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/video_background_scaffold.dart'; // Ensure this path is correct

class SigilGeneratorScreen extends StatefulWidget {
  const SigilGeneratorScreen({super.key});

  @override
  State<SigilGeneratorScreen> createState() => _SigilGeneratorScreenState();
}

class _SigilGeneratorScreenState extends State<SigilGeneratorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _pathAnimationController;
  late Animation<double> _pathAnimation;
  late AnimationController _circleAnimationController;
  late Animation<double> _circleAnimation;
  late AnimationController _flyingLetterMasterController;

  Path _sigilPath = Path();
  List<Offset> _circlePoints = [];
  String _reduced = '';
  String _input = '';
  bool _showReducedText = false; // Controlled visibility for glyphs text
  List<Widget> _flyingLetterWidgets = [];

  bool _showIntentionBar = true;
  double _intentionBarOpacity = 1.0;

  static const int _pathAnimationDurationMs = 5200;
  static const int _circleAnimationDurationMs = 1200;
  static const int _flyingLettersDurationMs = 1600;
  static const int _flyingLettersStaggerMs = 100;
  static const int _pauseAfterFlyingLettersMs = 200;
  static const int _pauseBeforeCircleMs = 500;
  static const int _intentionBarFadeMs = 400;
  static const int _glyphsTextFadeOutDelayMs =
      700; // Delay after path starts to fade glyphs text
  static const int _glyphsTextFadeDurationMs =
      400; // Duration for glyphs text fade

  @override
  void initState() {
    super.initState();

    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _pathAnimationDurationMs),
    );

    _circleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _circleAnimationDurationMs),
    );

    _flyingLetterMasterController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _flyingLettersDurationMs + (_flyingLettersStaggerMs * 15),
      ), // Generous estimate
    );

    _pathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pathAnimationController,
        curve: Curves.easeInOutSine,
      ),
    )..addListener(() => setState(() {}));

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _circleAnimationController,
        curve: Curves.easeOutQuint,
      ),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pathAnimationController.dispose();
    _circleAnimationController.dispose();
    _flyingLetterMasterController.dispose();
    super.dispose();
  }

  void _resetSigilState() {
    _pathAnimationController.reset();
    _circleAnimationController.reset();
    _flyingLetterMasterController.reset();
    setState(() {
      _sigilPath = Path();
      _circlePoints = [];
      _reduced = '';
      // _input variable keeps its value if _controller is not cleared
      _showReducedText = false;
      _flyingLetterWidgets = [];
      _showIntentionBar = true;
      _intentionBarOpacity = 1.0;
    });
  }

  void _generateSigil() async {
    if (_controller.text.isEmpty && _showIntentionBar) {
      // Optionally, add a little shake animation to the TextField if empty
      return;
    }

    // If sigil is already active/faded, and user clicks "Conjure Sigil" again
    if (!_showIntentionBar) {
      _resetSigilState();
      // Allow UI to update before re-evaluating if controller has text
      await Future.delayed(const Duration(milliseconds: 20));
      if (_controller.text.isEmpty)
        return; // If they cleared it while sigil was up
    }

    setState(() {
      _input = _controller.text.toUpperCase(); // Capture input
      _showIntentionBar = false; // Start fading out intention bar
      _intentionBarOpacity = 0.0;

      // Clear previous drawing elements for a clean start
      _sigilPath = Path();
      _circlePoints = [];
      _flyingLetterWidgets = [];
      _reduced = ''; // Clear reduced, will be repopulated
      _showReducedText = true; // Make glyphs text visible initially
    });
    // Ensure animation controllers are reset for new animation
    _pathAnimationController.reset();
    _circleAnimationController.reset();
    _flyingLetterMasterController.reset();

    final rawInput = _input;
    final noVowels = rawInput.replaceAll(RegExp(r'[AEIOU\s]'), '');
    final seen = <String>{};
    final reducedString =
        noVowels.split('').where((char) => seen.add(char)).join();

    // Set _reduced here so it's available for the Text widget when _showReducedText becomes true
    if (mounted) {
      setState(() {
        _reduced = reducedString;
      });
    }

    final List<String> simpleFlyingChars = [];
    Set<String> tempKeptChars = reducedString.split('').toSet();
    for (final char in rawInput.replaceAll(' ', '').split('')) {
      if (!tempKeptChars.contains(char)) {
        simpleFlyingChars.add(char);
      } else {
        tempKeptChars.remove(char);
      }
    }

    final size = MediaQuery.of(context).size;
    final screenCenterForFlyingLetters = Offset(
      size.width / 2,
      size.height / 2 - (AppBar().preferredSize.height / 2),
    );

    _flyingLetterMasterController.forward(from: 0.0);
    await Future.delayed(
      const Duration(milliseconds: _intentionBarFadeMs ~/ 3),
    ); // Start letters as bar fades

    for (int i = 0; i < simpleFlyingChars.length; i++) {
      final char = simpleFlyingChars[i];
      Future.delayed(Duration(milliseconds: i * _flyingLettersStaggerMs), () {
        if (!mounted) return;
        final angle = Random().nextDouble() * 2 * pi;
        final distance =
            (size.width / 3.5) + Random().nextDouble() * (size.width / 4.5);
        final target = Offset(
          screenCenterForFlyingLetters.dx + distance * cos(angle),
          screenCenterForFlyingLetters.dy + distance * sin(angle),
        );
        setState(
          () => _flyingLetterWidgets.add(
            FlyingLetterWidget(
              key: UniqueKey(),
              char: char,
              start: screenCenterForFlyingLetters,
              end: target,
              duration: const Duration(milliseconds: _flyingLettersDurationMs),
            ),
          ),
        );
      });
    }

    // Wait for letters to fly out a bit before next steps
    await Future.delayed(
      Duration(
        milliseconds:
            _flyingLettersDurationMs +
            (simpleFlyingChars.length * _flyingLettersStaggerMs ~/ 2) +
            _pauseAfterFlyingLettersMs,
      ),
    );

    // Clean up flying letter widgets after they've had time to fully animate and fade
    Future.delayed(
      Duration(
        milliseconds:
            _flyingLettersDurationMs +
            (simpleFlyingChars.length * _flyingLettersStaggerMs) +
            500,
      ),
      () {
        if (mounted) setState(() => _flyingLetterWidgets = []);
      },
    );

    if (reducedString.isEmpty) {
      // If no characters left for sigil
      Future.delayed(const Duration(milliseconds: 800), () {
        // Give a moment
        if (mounted) {
          setState(() {
            _showReducedText = false;
          }); // Fade out "Glyphs:"
          _resetSigilState(); // Bring back intention bar
        }
      });
      return;
    }

    const double sigilPointsRadius =
        85.0; // Inner radius for sigil connection points
    _circlePoints = _generateCirclePoints(reducedString, sigilPointsRadius);
    _sigilPath = _generateSigilPath(reducedString, _circlePoints);

    // Path and points are ready for the painter, no direct setState needed here for them
    // as the painter reads them during its paint call driven by animation.

    _pathAnimationController.forward(from: 0.0);

    // Fade out "Glyphs: ..." text shortly after path drawing starts
    Future.delayed(const Duration(milliseconds: _glyphsTextFadeOutDelayMs), () {
      if (mounted) {
        setState(() {
          _showReducedText = false;
        });
      }
    });

    await Future.delayed(
      const Duration(
        milliseconds: _pathAnimationDurationMs + _pauseBeforeCircleMs,
      ),
    );
    if (!mounted) return;
    _circleAnimationController.forward(from: 0.0);

    // Optional: Reset UI or show "New Sigil" button after full animation
    await Future.delayed(
      Duration(
        milliseconds:
            _pathAnimationDurationMs +
            _pauseBeforeCircleMs +
            _circleAnimationDurationMs +
            1500,
      ),
    );
    if (mounted) {
      // Consider adding a "New Sigil" button that calls _resetSigilState()
      // instead of automatically resetting.
      // For now, clicking "Conjure Sigil" again (if text field has content) will reset.
    }
  }

  List<Offset> _generateCirclePoints(String input, double radius) {
    final length = input.length;
    if (length == 0) return [];
    final angleStep = 2 * pi / length;
    return List.generate(length, (i) {
      final angle = angleStep * i;
      const jitter = 0.0; // Keep points perfectly on their circle
      final r = radius + jitter;
      return Offset(r * cos(angle), r * sin(angle)); // Relative to (0,0)
    });
  }

  Path _generateSigilPath(String input, List<Offset> points) {
    if (points.length < 2) return Path();
    final random = Random(input.hashCode);
    final pathOrder = <int>[];
    final Set<int> visitedIndices = {};
    int currentIndex = random.nextInt(points.length);

    while (visitedIndices.length < points.length) {
      pathOrder.add(currentIndex);
      visitedIndices.add(currentIndex);
      List<int> availableIndices =
          List.generate(
            points.length,
            (i) => i,
          ).where((i) => !visitedIndices.contains(i)).toList();
      if (availableIndices.isEmpty) break;
      List<int> farCandidates =
          availableIndices.where((i) {
            int diff = (i - currentIndex).abs();
            return diff > 1 &&
                diff < points.length - 1; // Not immediate neighbors
          }).toList();
      if (farCandidates.isNotEmpty) {
        currentIndex = farCandidates[random.nextInt(farCandidates.length)];
      } else {
        currentIndex =
            availableIndices[random.nextInt(availableIndices.length)];
      }
    }
    final path = Path();
    if (pathOrder.isNotEmpty) {
      path.moveTo(points[pathOrder[0]].dx, points[pathOrder[0]].dy);
      for (final index in pathOrder.skip(1)) {
        path.lineTo(points[index].dx, points[index].dy);
      }
    }
    return path; // Path with points relative to (0,0)
  }

  @override
  Widget build(BuildContext context) {
    return VideoBackgroundScaffold(
      videoAssetPath: 'assets/videos/red_nebula.mp4',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Sigil Generator',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.redAccent),
        ),
        body: Stack(
          alignment:
              Alignment.center, // Helps with Stack children if not Positioned
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AnimatedOpacity(
                    opacity: _intentionBarOpacity,
                    duration: const Duration(milliseconds: _intentionBarFadeMs),
                    child: Visibility(
                      visible: _showIntentionBar,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _controller,
                            enabled: _showIntentionBar,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter your intention...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.redAccent.withOpacity(0.5),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.redAccent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _generateSigil(),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                _showIntentionBar ? _generateSigil : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent.withOpacity(
                                0.85,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Conjure Sigil'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Space that appears/disappears with the intention bar
                  AnimatedCrossFade(
                    firstChild: const SizedBox(
                      height: 20 + 22 + 10,
                    ), // Height for text + padding
                    secondChild:
                        const SizedBox.shrink(), // Takes no space when intention bar is hidden
                    crossFadeState:
                        _showIntentionBar
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: _intentionBarFadeMs),
                    firstCurve: Curves.easeOut,
                    secondCurve: Curves.easeIn,
                    sizeCurve: Curves.bounceOut, // How the size animates
                  ),
                  AnimatedOpacity(
                    opacity: _showReducedText ? 1.0 : 0.0,
                    duration: const Duration(
                      milliseconds: _glyphsTextFadeDurationMs,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _reduced.isNotEmpty
                            ? 'Glyphs: $_reduced'
                            : (_input.isNotEmpty && _showIntentionBar == false
                                ? 'Processing...'
                                : ''), // Show processing or nothing
                        style: TextStyle(
                          color: Colors.redAccent.withOpacity(0.9),
                          fontSize: 18,
                          letterSpacing: 2,
                          shadows: const [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black54,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomPaint(
                      painter: AnimatedSigilPainter(
                        fullPath: _sigilPath,
                        progress: _pathAnimation.value,
                        circlePoints: _circlePoints,
                        circleProgress: _circleAnimation.value,
                      ),
                      child: Container(), // Ensure CustomPaint takes space
                    ),
                  ),
                ],
              ),
            ),
            ..._flyingLetterWidgets, // Render flying letters on top
          ],
        ),
      ),
    );
  }
}

// --- FlyingLetterWidget ---
class FlyingLetterWidget extends StatefulWidget {
  final String char;
  final Offset start;
  final Offset end;
  final Duration duration;
  final VoidCallback? onComplete;

  const FlyingLetterWidget({
    required this.char,
    required this.start,
    required this.end,
    required this.duration,
    this.onComplete,
    super.key,
  });

  @override
  State<FlyingLetterWidget> createState() => _FlyingLetterWidgetState();
}

class _FlyingLetterWidgetState extends State<FlyingLetterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });

    _position = Tween<Offset>(
      begin: widget.start,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.5,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 70,
      ),
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
        if (_opacity.value <= 0.01 &&
            (_controller.isCompleted || _controller.isDismissed)) {
          return const SizedBox.shrink();
        }
        return Positioned(
          left:
              _position.value.dx -
              (18 * _scale.value / 2), // Center scaled text
          top:
              _position.value.dy -
              (18 * _scale.value / 2), // Center scaled text
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Text(
                widget.char,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.red,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- AnimatedSigilPainter ---
class AnimatedSigilPainter extends CustomPainter {
  final Path fullPath;
  final double progress;
  final List<Offset> circlePoints; // These are for the inner sigil points
  final double circleProgress;

  AnimatedSigilPainter({
    required this.fullPath,
    required this.progress,
    required this.circlePoints,
    required this.circleProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final pointPaint =
        Paint()
          ..color = Colors.redAccent.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    const pointRadius = 1.75; // Visual size of the dots
    // Draw the sigil connection points (dots) using the _circlePoints (which are on the inner radius)
    for (final pointOffset in circlePoints) {
      canvas.drawCircle(pointOffset + center, pointRadius, pointPaint);
    }

    final pathPaint =
        Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 1.75
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final glowPaint =
        Paint()
          ..color = Colors.red.withOpacity(0.5)
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    // Draw the sigil path (lines connecting the circlePoints)
    final metrics = fullPath.computeMetrics().toList();
    for (final metric in metrics) {
      if (metric.length == 0) continue;
      final extractLength = metric.length * progress;
      if (extractLength <= 0) continue;
      final partialPath = metric.extractPath(0, extractLength);
      canvas.drawPath(partialPath.shift(center), glowPaint); // Glow first
      canvas.drawPath(partialPath.shift(center), pathPaint); // Path on top
    }

    // Draw the main enclosing circle (at radius 105.0)
    if (circleProgress > 0) {
      const double outerCircleRadius = 105.0; // Explicit outer circle radius
      const double baseStrokeWidth = 1.5;
      final double animatedStrokeWidth =
          baseStrokeWidth +
          (1.0 * Curves.easeOutExpo.transform(circleProgress));
      final circleOpacity = Curves.easeInOutCubic.transform(circleProgress);
      final enclosingCirclePaint =
          Paint()
            ..color = Colors.redAccent.withOpacity(circleOpacity * 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = animatedStrokeWidth
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      canvas.drawCircle(center, outerCircleRadius, enclosingCirclePaint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedSigilPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.circleProgress != circleProgress ||
      !listEquals(oldDelegate.circlePoints, circlePoints) ||
      oldDelegate.fullPath != fullPath;
}

// --- listEquals Helper ---
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
