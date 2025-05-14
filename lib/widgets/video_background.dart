import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  final String videoPath;
  final Widget child;
  final bool loop;
  final bool autoPlay;
  final bool overlayDarken;

  const VideoBackground({
    super.key,
    required this.videoPath,
    required this.child,
    this.loop = true,
    this.autoPlay = true,
    this.overlayDarken = true,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        if (widget.loop) _controller.setLooping(true);
        if (widget.autoPlay) _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_controller.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        if (widget.overlayDarken)
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
        widget.child,
      ],
    );
  }
}
