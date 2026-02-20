import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/services.dart';

class CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
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
          child: Container(
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
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
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
                      child: (widget.category.imageUrl.startsWith('http'))
                          ? CachedNetworkImage(
                              imageUrl: widget.category.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              ),
                            )
                          : Image.asset('assets/logo.png', fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 4,
                  ),
                  child: Text(
                    widget.category.name,
                    style: TextStyle(
                      color: _isFocused ? AppTheme.primaryGold : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
