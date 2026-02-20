import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  MethodChannel? _channel;
  bool _isBuffering = true;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
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
              _channel = MethodChannel('native_video_player_$id');
              _channel?.setMethodCallHandler((call) async {
                switch (call.method) {
                  case 'onPlaybackState':
                    int state = call.arguments['state'];
                    // States: 1=Idle, 2=Buffering, 3=Ready, 4=Ended
                    if (mounted) {
                      setState(() {
                        _isBuffering = state == 2 || state == 1;
                      });

                      // Auto-reconnect if playback ends (State 4 = ENDED)
                      if (state == 4) {
                        debugPrint("Stream ended (State 4), reconnecting...");
                        _reconnect();
                      }
                    }
                    break;
                  case 'onError':
                    final String? message = call.arguments['message'];
                    debugPrint("Player Error: $message. Reconnecting...");
                    if (mounted) {
                      setState(() {
                        _isBuffering =
                            true; // Show buffering while reconnecting
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'انقطع الاتصال، جاري إعادة المحاولة... ($message)',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      // Wait a bit to avoid tight loops, then reconnect
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
          if (_isBuffering)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    }
    return const Center(child: Text('هذا المشغل يعمل فقط على أجهزة أندرويد'));
  }

  @override
  void didUpdateWidget(NativeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.drmData != widget.drmData ||
        oldWidget.quality != widget.quality ||
        oldWidget.userAgent != widget.userAgent ||
        oldWidget.referer != widget.referer) {
      _channel?.invokeMethod('play', {
        'url': widget.url,
        'drmData': widget.drmData,
        'quality': widget.quality,
        'userAgent': widget.userAgent,
        'referer': widget.referer,
      });
    }
  }

  Future<void> setResizeMode(int mode) async {
    await _channel?.invokeMethod('setResizeMode', {'mode': mode});
  }

  void setBuffering(bool value) {
    if (mounted) {
      setState(() {
        _isBuffering = value;
      });
    }
  }

  Future<void> setQuality(String quality) async {
    await _channel?.invokeMethod('play', {
      'url': widget.url,
      'drmData': widget.drmData,
      'quality': quality,
      'userAgent': widget.userAgent,
      'referer': widget.referer,
    });
  }

  void _reconnect() {
    _channel?.invokeMethod('play', {
      'url': widget.url,
      'drmData': widget.drmData,
      'quality': widget.quality,
      'userAgent': widget.userAgent,
      'referer': widget.referer,
    });
  }

  @override
  void dispose() {
    _channel?.invokeMethod('dispose');
    super.dispose();
  }
}
