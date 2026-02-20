import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/category_model.dart';
import '../models/channel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/channel_card.dart';
import 'video_player_screen.dart';

class CategoryChannelsScreen extends StatefulWidget {
  final CategoryModel category;
  const CategoryChannelsScreen({super.key, required this.category});

  @override
  State<CategoryChannelsScreen> createState() => _CategoryChannelsScreenState();
}

class _CategoryChannelsScreenState extends State<CategoryChannelsScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: StreamBuilder<List<ChannelModel>>(
        stream: _firebaseService.getChannels(widget.category.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد قنوات في هذا القسم'));
          }

          final channels = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            cacheExtent: 1000, // Optimization for scrolling
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return ChannelCard(
                key: ValueKey(channel.id),
                channel: channel,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerScreen(channel: channel),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
