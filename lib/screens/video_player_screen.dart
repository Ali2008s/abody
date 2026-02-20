import 'package:flutter/material.dart';
import '../models/channel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/native_video_player.dart';
import 'package:flutter/services.dart';

class VideoPlayerScreen extends StatefulWidget {
  final ChannelModel channel;
  const VideoPlayerScreen({super.key, required this.channel});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  int _currentSourceIndex = 0;
  late List<VideoSource> _sortedSources;
  bool _showControls = true;

  // Focus nodes for managing TV remote navigation
  final FocusNode _backButtonNode = FocusNode();
  final FocusNode _resizeButtonNode = FocusNode();
  final FocusNode _qualityButtonNode = FocusNode();
  final List<FocusNode> _serverNodes = [];

  List<int> _availableStreamQualities = [];
  String _selectedStreamQuality = 'Auto';
  bool _showQualityMenu = false;

  @override
  void initState() {
    super.initState();
    _sortedSources = widget.channel.sources
        .where((s) => s.url.trim().isNotEmpty)
        .toList();
    _sortedSources.sort((a, b) {
      if (a.quality.toLowerCase() == 'auto') return -1;
      if (b.quality.toLowerCase() == 'auto') return 1;
      return 0;
    });

    // Default to 'Auto' quality if available
    int autoIndex = _sortedSources.indexWhere(
      (s) => s.quality.toLowerCase() == 'auto',
    );
    _currentSourceIndex = autoIndex != -1 ? autoIndex : 0;

    // Initialize focus nodes for server chips
    for (int i = 0; i < _sortedSources.length; i++) {
      _serverNodes.add(FocusNode());
    }

    // Hide system bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Request focus on back button initially after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _backButtonNode.requestFocus();
      }
    });
  }

  void _changeQuality(int index) {
    if (index == _currentSourceIndex) return;
    setState(() {
      _currentSourceIndex = index;
      _availableStreamQualities = [];
      _selectedStreamQuality = 'Auto';
      _showQualityMenu = false;
    });
  }

  void _onControlsVisibilityChange(bool isVisible) {
    if (mounted) {
      setState(() {
        _showControls = isVisible;
      });

      if (isVisible) {
        // Regain focus when controls reappear
        _backButtonNode.requestFocus();
      }
    }
  }

  void _onTracksChanged(List<int> qualities) {
    if (mounted) {
      setState(() {
        _availableStreamQualities = qualities;
      });
    }
  }

  void _changeStreamQuality(String quality) {
    setState(() {
      _selectedStreamQuality = quality;
      _showQualityMenu = false;
    });
    _playerKey.currentState?.setQuality(quality);
  }

  @override
  void dispose() {
    // Dispose focus nodes
    _backButtonNode.dispose();
    _resizeButtonNode.dispose();
    _qualityButtonNode.dispose();
    for (var node in _serverNodes) {
      node.dispose();
    }

    // Show system bars and restore orientations
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sortedSources.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('لا توجد روابط لهذه القناة')),
      );
    }

    final currentSource = _sortedSources[_currentSourceIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: NativeVideoPlayer(
              key: _playerKey,
              url: currentSource.url,
              quality: currentSource.quality,
              drmData: currentSource.drmData,
              userAgent: currentSource.userAgent,
              referer: currentSource.referer,
              onControlsVisibilityChange: _onControlsVisibilityChange,
              onTracksChanged: _onTracksChanged,
            ),
          ),
          // Use FocusScope to keep focus within controls when visible
          if (_showControls)
            FocusScope(
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Stack(
                  children: [
                    // Back Button
                    Positioned(
                      top: 20,
                      left: 20,
                      child: _FocusableControl(
                        focusNode: _backButtonNode,
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    // Resize Mode Toggle (Bottom Right)
                    Positioned(
                      bottom: 30,
                      right: 30,
                      child: _FocusableControl(
                        focusNode: _resizeButtonNode,
                        onPressed: () {
                          setState(() {
                            // Cycle: 3 (Zoom) -> 0 (Fit) -> 1 (Fill/Stretch)
                            if (_resizeMode == 3)
                              _resizeMode = 0;
                            else if (_resizeMode == 0)
                              _resizeMode = 1;
                            else
                              _resizeMode = 3;
                          });
                          _playerKey.currentState?.setResizeMode(_resizeMode);
                        },
                        child: _buildResizeModeIcon(),
                      ),
                    ),
                    // LIVE Indicator
                    Positioned(
                      top: 25,
                      left: 70,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Quality Selection Button (Bottom Right - Beside Resize)
                    Positioned(
                      bottom: 30,
                      right: 90,
                      child: _FocusableControl(
                        focusNode: _qualityButtonNode,
                        onPressed: () {
                          setState(() {
                            _showQualityMenu = !_showQualityMenu;
                          });
                        },
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    // Quality Menu
                    if (_showQualityMenu)
                      Positioned(
                        bottom: 75,
                        right: 30,
                        child: Container(
                          width: 150,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryGold,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "جودة الفيديو",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const Divider(color: Colors.white24, height: 12),
                              _buildQualityItem(
                                "Auto",
                                _selectedStreamQuality == "Auto",
                              ),
                              ..._availableStreamQualities.map(
                                (h) => _buildQualityItem(
                                  "${h}p",
                                  _selectedStreamQuality == "${h}p",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Servers Selection at the Top Right (Only if more than one server exists)
                    if (_sortedSources.length > 1)
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: _sortedSources.asMap().entries.map((
                                    entry,
                                  ) {
                                    int idx = entry.key;
                                    bool isSelected =
                                        idx == _currentSourceIndex;
                                    String serverLabel = "السيرفر ${idx + 1}";

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      child: _ServerChip(
                                        focusNode: idx < _serverNodes.length
                                            ? _serverNodes[idx]
                                            : null,
                                        label: serverLabel,
                                        isSelected: isSelected,
                                        onPressed: () => _changeQuality(idx),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  final GlobalKey<NativeVideoPlayerState> _playerKey =
      GlobalKey<NativeVideoPlayerState>();
  int _resizeMode = 0; // Default to Fit

  Widget _buildQualityItem(String label, bool isSelected) {
    return _QualityMenuItem(
      label: label,
      isSelected: isSelected,
      onPressed: () => _changeStreamQuality(label),
    );
  }

  Widget _buildResizeModeIcon() {
    IconData icon;
    switch (_resizeMode) {
      case 0:
        icon = Icons.fit_screen;
        break;
      case 1:
        icon = Icons.unfold_more;
        break;
      case 3:
        icon = Icons.fullscreen;
        break;
      default:
        icon = Icons.aspect_ratio;
    }
    return Icon(icon, color: Colors.white, size: 24);
  }
}

class _FocusableControl extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  const _FocusableControl({
    required this.child,
    required this.onPressed,
    this.focusNode,
  });

  @override
  State<_FocusableControl> createState() => _FocusableControlState();
}

class _FocusableControlState extends State<_FocusableControl> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isFocused
                ? AppTheme.primaryGold
                : Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryGold,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(8),
          child: AnimatedScale(
            scale: _isFocused ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ServerChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  const _ServerChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.focusNode,
  });

  @override
  State<_ServerChip> createState() => _ServerChipState();
}

class _ServerChipState extends State<_ServerChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryGold
                : (_isFocused
                      ? AppTheme.primaryGold.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGold,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: AnimatedScale(
            scale: _isFocused ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isSelected || _isFocused
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QualityMenuItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _QualityMenuItem({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  State<_QualityMenuItem> createState() => _QualityMenuItemState();
}

class _QualityMenuItemState extends State<_QualityMenuItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isFocused || widget.isSelected
                ? AppTheme.primaryGold
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (widget.isSelected)
                const Icon(Icons.check, size: 14, color: Colors.black)
              else
                const SizedBox(width: 14),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: _isFocused || widget.isSelected
                      ? Colors.black
                      : Colors.white,
                  fontSize: 13,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
