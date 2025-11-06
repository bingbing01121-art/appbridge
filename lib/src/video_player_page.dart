import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerPage({super.key, required this.videoUrl});

  @override
  VideoPlayerPageState createState() => VideoPlayerPageState();
}

enum _DragType { none, brightness, volume }

class VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isDragging = false;
  Duration _currentSeekPosition = Duration.zero;

  // For auto-hiding controls
  bool _showControls = true;
  Timer? _hideControlsTimer;

  // For brightness and volume control
  _DragType _dragType = _DragType.none;
  double _initialBrightness = 0.5;
  double _initialVolume = 0.5;
  double _currentVolume = 0.5;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;

  // Hardcoded thumbnail data for demonstration.
  final Map<String, dynamic> _thumbnailData = {
    'spriteSheetUrl':
        'https://i.imgur.com/2zY4000.png', // Example sprite sheet URL
    'thumbnailWidth': 160.0,
    'thumbnailHeight': 90.0,
    'thumbnailsPerRow': 10,
    'totalThumbnails': 100,
    'durationPerThumbnail': 10,
  };

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // Start auto-hide timer once video is initialized
      _startHideControlsTimer();
      setState(() {});
    });
    _controller.setLooping(true);
    _controller.play();

    // Initialize volume
    VolumeController.instance
        .getVolume()
        .then((volume) => setState(() => _currentVolume = volume));
    VolumeController.instance.addListener((volume) {
      if (mounted) {
        setState(() => _currentVolume = volume);
      }
    });
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideControlsTimer?.cancel();
    VolumeController.instance.removeListener();
    super.dispose();
  }

  void _handleTap() {
    if (_showControls) {
      // If controls are visible, a tap toggles play/pause
      setState(() {
        if (_controller.value.isPlaying) {
          _controller.pause();
        } else {
          _controller.play();
        }
      });
    } else {
      // If controls are hidden, a tap shows them
      setState(() {
        _showControls = true;
      });
    }
    // Always restart the timer on tap
    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频播放示例'),
      ),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            double screenWidth = MediaQuery.of(context).size.width;
            double desiredHeight = screenWidth * 3 / 4;

            return GestureDetector(
              onTap: _handleTap,
              onVerticalDragStart: (details) async {
                _hideControlsTimer?.cancel(); // Cancel timer during drag
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 2) {
                  _dragType = _DragType.brightness;
                  _initialBrightness = await ScreenBrightness().system;
                } else {
                  _dragType = _DragType.volume;
                  _initialVolume = await VolumeController.instance.getVolume();
                }
              },
              onVerticalDragUpdate: (details) async {
                // Added async here
                if (_dragType == _DragType.brightness &&
                    !_showBrightnessIndicator) {
                  setState(() => _showBrightnessIndicator = true);
                }
                if (_dragType == _DragType.volume && !_showVolumeIndicator) {
                  setState(() => _showVolumeIndicator = true);
                }

                final dragDistance = details.primaryDelta! / -200;
                if (_dragType == _DragType.brightness) {
                  final newBrightness =
                      (_initialBrightness + dragDistance).clamp(0.0, 1.0);
                  await ScreenBrightness().setApplicationScreenBrightness(
                      newBrightness); // Changed here
                  setState(() => _initialBrightness = newBrightness);
                } else if (_dragType == _DragType.volume) {
                  final newVolume =
                      (_initialVolume + dragDistance).clamp(0.0, 1.0);
                  await VolumeController.instance.setVolume(newVolume);
                  setState(() => _initialVolume = newVolume);
                }
              },
              onVerticalDragEnd: (details) {
                _startHideControlsTimer(); // Restart timer after drag
                setState(() {
                  _showBrightnessIndicator = false;
                  _showVolumeIndicator = false;
                  _dragType = _DragType.none;
                });
              },
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    width: screenWidth,
                    height: desiredHeight,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  // Animated Play/Pause Icon
                  AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white.withAlpha((255 * 0.7).round()),
                        size: 60.0,
                      ),
                    ),
                  ),
                  // Brightness Indicator
                  if (_showBrightnessIndicator)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((255 * 0.6).round()),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.brightness_6,
                                  color: Colors.white),
                              const SizedBox(height: 8),
                              FutureBuilder<double>(
                                future: ScreenBrightness().system,
                                builder: (context, snapshot) {
                                  return Text(
                                      '${((snapshot.data ?? 0) * 100).toInt()}%',
                                      style:
                                          const TextStyle(color: Colors.white));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Volume Indicator
                  if (_showVolumeIndicator)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((255 * 0.6).round()),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.volume_up, color: Colors.white),
                              const SizedBox(height: 8),
                              Text('${(_currentVolume * 100).toInt()}%',
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Controls Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (context, VideoPlayerValue value, child) {
                          // Format duration
                          String formatDuration(Duration duration) {
                            String twoDigits(int n) =>
                                n.toString().padLeft(2, '0');
                            final hours = twoDigits(duration.inHours);
                            final minutes =
                                twoDigits(duration.inMinutes.remainder(60));
                            final seconds =
                                twoDigits(duration.inSeconds.remainder(60));
                            if (duration.inHours > 0) {
                              return '$hours:$minutes:$seconds';
                            }
                            return '$minutes:$seconds';
                          }

                          // Calculate thumbnail position
                          int thumbnailIndex = (_currentSeekPosition
                                      .inSeconds ~/
                                  (_thumbnailData['durationPerThumbnail']
                                      as int))
                              .clamp(
                                  0,
                                  (_thumbnailData['totalThumbnails'] as int) -
                                      1);
                          int row = thumbnailIndex ~/
                              (_thumbnailData['thumbnailsPerRow'] as int);
                          int col = thumbnailIndex %
                              (_thumbnailData['thumbnailsPerRow'] as int);

                          double offsetX = col *
                              (_thumbnailData['thumbnailWidth'] as double);
                          double offsetY = row *
                              (_thumbnailData['thumbnailHeight'] as double);

                          return Container(
                            color: Colors.black.withAlpha((255 * 0.4).round()),
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isDragging) // Show thumbnail preview only when dragging
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    width: (_thumbnailData['thumbnailWidth']
                                        as double),
                                    height: (_thumbnailData['thumbnailHeight']
                                        as double),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 4.0)
                                      ],
                                    ),
                                    child: ClipRect(
                                      child: OverflowBox(
                                        maxWidth: (_thumbnailData[
                                                'thumbnailWidth'] as double) *
                                            (_thumbnailData['thumbnailsPerRow']
                                                as int),
                                        maxHeight: (_thumbnailData[
                                                'thumbnailHeight'] as double) *
                                            ((_thumbnailData['totalThumbnails']
                                                        as int) /
                                                    (_thumbnailData[
                                                            'thumbnailsPerRow']
                                                        as int))
                                                .ceilToDouble(),
                                        child: Transform.translate(
                                          offset: Offset(-offsetX, -offsetY),
                                          child: CachedNetworkImage(
                                            imageUrl: _thumbnailData[
                                                'spriteSheetUrl'],
                                            fit: BoxFit.fill,
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                          formatDuration(value.position),
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: _isDragging
                                            ? _currentSeekPosition.inSeconds
                                                .toDouble()
                                            : value.position.inSeconds
                                                .toDouble(),
                                        min: 0.0,
                                        max:
                                            value.duration.inSeconds.toDouble(),
                                        activeColor: Colors.blue,
                                        inactiveColor: Colors.white30,
                                        secondaryActiveColor: Colors.lightBlue,
                                        secondaryTrackValue: value
                                                .buffered.isNotEmpty
                                            ? value.buffered.last.end.inSeconds
                                                .toDouble()
                                            : 0.0,
                                        onChanged: (newPosition) {
                                          setState(() {
                                            _currentSeekPosition = Duration(
                                                seconds: newPosition.toInt());
                                            _isDragging = true;
                                          });
                                        },
                                        onChangeStart: (startPosition) {
                                          _hideControlsTimer?.cancel();
                                          setState(() {
                                            _isDragging = true;
                                            _currentSeekPosition = Duration(
                                                seconds: startPosition.toInt());
                                          });
                                        },
                                        onChangeEnd: (endPosition) {
                                          _startHideControlsTimer();
                                          setState(() {
                                            _isDragging = false;
                                            _controller.seekTo(Duration(
                                                seconds: endPosition.toInt()));
                                          });
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                          formatDuration(value.duration),
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Mini Progress Bar (appears when controls are hidden)
                  if (!_showControls && _controller.value.isInitialized)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (context, VideoPlayerValue value, child) {
                          return SizedBox(
                            height: 3.0, // Height of the mini progress bar
                            child: LinearProgressIndicator(
                              value: value.position.inMilliseconds /
                                  value.duration.inMilliseconds,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.blue),
                              backgroundColor: Colors.transparent,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
