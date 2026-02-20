import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/category_model.dart';
import '../models/channel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/channel_card.dart';
import 'video_player_screen.dart';

class XtreamChannelsScreen extends StatefulWidget {
  const XtreamChannelsScreen({super.key});

  @override
  State<XtreamChannelsScreen> createState() => _XtreamChannelsScreenState();
}

class _XtreamChannelsScreenState extends State<XtreamChannelsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  CategoryModel? _activeCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _activeCategory == null ? 'أقسام IPTV' : _activeCategory!.name,
        ),
        leading: _activeCategory != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _activeCategory = null),
              )
            : null,
      ),
      body: _activeCategory == null
          ? _buildCategoriesGrid()
          : _buildChannelsGrid(_activeCategory!.id),
    );
  }

  Widget _buildCategoriesGrid() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _firebaseService.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGold),
          );
        }

        final xtreamCategories =
            snapshot.data?.where((c) => c.id.startsWith('xtream_')).toList() ??
            [];

        if (xtreamCategories.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد أقسام IPTV حالياً. يرجى المزامنة من لوحة التحكم.',
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: xtreamCategories.length,
          itemBuilder: (context, index) {
            final cat = xtreamCategories[index];
            return CategoryCard(
              category: cat,
              onTap: () => setState(() => _activeCategory = cat),
            );
          },
        );
      },
    );
  }

  Widget _buildChannelsGrid(String categoryId) {
    return StreamBuilder<List<ChannelModel>>(
      stream: _firebaseService.getChannels(categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGold),
          );
        }

        final channels = snapshot.data ?? [];
        if (channels.isEmpty) {
          return const Center(child: Text('لا توجد قنوات في هذا القسم'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 6 : 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final ch = channels[index];
            return ChannelCard(
              channel: ch,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(channel: ch),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
