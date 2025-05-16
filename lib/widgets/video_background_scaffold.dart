// lib/widgets/video_background_scaffold.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackgroundScaffold extends StatefulWidget {
  final String videoAssetPath;
  final Widget child; // The actual content of your screen
  final Color? fallbackBackgroundColor; // Optional fallback color

  const VideoBackgroundScaffold({
    super.key,
    required this.videoAssetPath,
    required this.child,
    this.fallbackBackgroundColor = Colors.black, // Default fallback
  });

  @override
  State<VideoBackgroundScaffold> createState() =>
      _VideoBackgroundScaffoldState();
}

class _VideoBackgroundScaffoldState extends State<VideoBackgroundScaffold> {
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void didUpdateWidget(VideoBackgroundScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the video asset path changes, re-initialize the player
    if (widget.videoAssetPath != oldWidget.videoAssetPath) {
      _videoController.dispose(); // Dispose old controller
      _initializeVideoPlayer(); // Initialize with new video
    }
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset(widget.videoAssetPath)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {
              _videoInitialized = true;
            });
            _videoController.play();
            _videoController.setLooping(true);
            _videoController.setVolume(0.0); // Muted by default for backgrounds
          })
          .catchError((error) {
            if (!mounted) return;
            print(
              "Error initializing video player (${widget.videoAssetPath}): $error",
            );
            setState(() {
              _videoInitialized = false;
            });
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We don't set a backgroundColor here directly on Scaffold,
      // as the Stack will handle covering the area.
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // --- Video Player Background ---
          if (_videoInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            Container(
              color: widget.fallbackBackgroundColor,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // --- Screen Content Overlay ---
          // The 'child' widget passed to VideoBackgroundScaffold will be displayed here
          widget.child,
        ],
      ),
    );
  }
}
