import 'package:flutter/material.dart';
import '../models/channel_model.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/services.dart';

class ChannelCard extends StatefulWidget {
  final ChannelModel channel;
  final VoidCallback onTap;

  const ChannelCard({super.key, required this.channel, required this.onTap});

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    // Get quality from first source if exists
    String quality = widget.channel.sources.isNotEmpty
        ? widget.channel.sources.first.quality
        : "LIVE";

    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _isFocused ? AppTheme.primaryGold : Colors.white10,
                    width: _isFocused ? 2.5 : 0.5,
                  ),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryGold.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isFocused
                                ? AppTheme.primaryGold
                                : AppTheme.primaryGold.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: (widget.channel.imageUrl.startsWith('http'))
                              ? CachedNetworkImage(
                                  imageUrl: widget.channel.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Image.asset(
                                    'assets/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                        'assets/logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                )
                              : Image.asset(
                                  'assets/logo.png',
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        widget.channel.name,
                        style: TextStyle(
                          color: _isFocused
                              ? AppTheme.primaryGold
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      'بث مباشر',
                      style: TextStyle(color: Colors.grey, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              // Badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    quality,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
