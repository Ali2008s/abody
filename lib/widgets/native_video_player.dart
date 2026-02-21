import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class NativeVideoPlayer extends StatefulWidget {
  final String url;
  final String? quality;
  final Map<String, String>? drmData;
  final String? userAgent;
  final String? referer;
  final Function(bool isVisible)? onControlsVisibilityChange;
  final Function(List<int> qualities)? onTracksChanged;

  const NativeVideoPlayer({
    super.key,
    required this.url,
    this.quality,
    this.drmData,
    this.userAgent,
    this.referer,
    this.onControlsVisibilityChange,
    this.onTracksChanged,
  });

  @override
  State<NativeVideoPlayer> createState() => NativeVideoPlayerState();
}

class NativeVideoPlayerState extends State<NativeVideoPlayer> {
  // Android specific
  MethodChannel? _androidChannel;
  bool _isAndroidBuffering = true;

  // iOS specific
  VideoPlayerController? _iosController;
  bool _isIosInitialized = false;
  int _resizeMode = 0; // 0=Fit, 1=Fill, 3=Zoom

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _initIosPlayer();
    }
  }

  Future<void> _initIosPlayer() async {
    setState(() {
      _isIosInitialized = false;
    });

    try {
      final Map<String, String> headers = {};
      if (widget.userAgent != null) headers['User-Agent'] = widget.userAgent!;
      if (widget.referer != null) headers['Referer'] = widget.referer!;

      _iosController?.dispose();
      _iosController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: headers,
      );

      await _iosController!.initialize();
      _iosController!.play();
      _iosController!.setLooping(true);

      _iosController!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      setState(() {
        _isIosInitialized = true;
      });
    } catch (e) {
      debugPrint("iOS Player Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _buildAndroidPlayer();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _buildIosPlayer();
    }

    return const Center(child: Text('هذه المنصة غير مدعومة حالياً'));
  }

  Widget _buildAndroidPlayer() {
    return Stack(
      children: [
        AndroidView(
          viewType: 'native_video_player_view',
          creationParams: {
            'url': widget.url,
            'drmData': widget.drmData,
            'quality': widget.quality,
            'userAgent': widget.userAgent,
            'referer': widget.referer,
          },
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: (int id) {
            _androidChannel = MethodChannel('native_video_player_$id');
            _androidChannel?.setMethodCallHandler((call) async {
              switch (call.method) {
                case 'onPlaybackState':
                  int state = call.arguments['state'];
                  if (mounted) {
                    setState(() {
                      _isAndroidBuffering = state == 2 || state == 1;
                    });
                    if (state == 4) _reconnect();
                  }
                  break;
                case 'onError':
                  final String? message = call.arguments['message'];
                  if (mounted) {
                    setState(() => _isAndroidBuffering = true);
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) _reconnect();
                    });
                  }
                  break;
                case 'onControlsVisibilityChange':
                  final bool isVisible = call.arguments['isVisible'];
                  if (widget.onControlsVisibilityChange != null) {
                    widget.onControlsVisibilityChange!(isVisible);
                  }
                  break;
                case 'onTracksChanged':
                  final List<dynamic> qualities = call.arguments['qualities'];
                  if (widget.onTracksChanged != null) {
                    widget.onTracksChanged!(qualities.cast<int>());
                  }
                  break;
              }
            });
          },
        ),
        if (_isAndroidBuffering)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }

  Widget _buildIosPlayer() {
    if (!_isIosInitialized || _iosController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    Widget playerView = VideoPlayer(_iosController!);

    // Handle Resize Modes
    if (_resizeMode == 0) {
      // Fit
      playerView = AspectRatio(
        aspectRatio: _iosController!.value.aspectRatio,
        child: playerView,
      );
    } else if (_resizeMode == 1) {
      // Fill/Stretch
      playerView = Positioned.fill(child: playerView);
    } else if (_resizeMode == 3) {
      // Zoom/Cover
      playerView = SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _iosController!.value.size.width,
            height: _iosController!.value.size.height,
            child: playerView,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Center(child: playerView),
        if (_iosController!.value.isBuffering)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        // Invisible gesture detector to toggle controls on iOS
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (widget.onControlsVisibilityChange != null) {
                // Typical toggle logic for iOS
                // You might want to track visibility locally too
                widget.onControlsVisibilityChange!(true);
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(NativeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.drmData != widget.drmData ||
        oldWidget.quality != widget.quality ||
        oldWidget.userAgent != widget.userAgent ||
        oldWidget.referer != widget.referer) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        _androidChannel?.invokeMethod('play', {
          'url': widget.url,
          'drmData': widget.drmData,
          'quality': widget.quality,
          'userAgent': widget.userAgent,
          'referer': widget.referer,
        });
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        _initIosPlayer();
      }
    }
  }

  Future<void> setResizeMode(int mode) async {
    _resizeMode = mode;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _androidChannel?.invokeMethod('setResizeMode', {'mode': mode});
    } else {
      setState(() {});
    }
  }

  void setBuffering(bool value) {
    if (mounted) {
      setState(() {
        if (defaultTargetPlatform == TargetPlatform.android) {
          _isAndroidBuffering = value;
        }
      });
    }
  }

  Future<void> setQuality(String quality) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _androidChannel?.invokeMethod('play', {
        'url': widget.url,
        'drmData': widget.drmData,
        'quality': quality,
        'userAgent': widget.userAgent,
        'referer': widget.referer,
      });
    }
    // Note: Quality switching for iOS standard video_player is limited for HLS
    // but often HLS handles it automatically via Adaptive Bitrate.
  }

  void _reconnect() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      _androidChannel?.invokeMethod('play', {
        'url': widget.url,
        'drmData': widget.drmData,
        'quality': widget.quality,
        'userAgent': widget.userAgent,
        'referer': widget.referer,
      });
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      _initIosPlayer();
    }
  }

  @override
  void dispose() {
    _androidChannel?.invokeMethod('dispose');
    _iosController?.dispose();
    super.dispose();
  }
}
