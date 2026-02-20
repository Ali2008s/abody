import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/channel_model.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';
import '../services/playlist_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageChannelsScreen extends StatelessWidget {
  final CategoryModel category;
  const ManageChannelsScreen({super.key, required this.category});

  void _showChannelDialog(BuildContext context, {ChannelModel? channel}) {
    final nameController = TextEditingController(text: channel?.name);
    final imageController = TextEditingController(text: channel?.imageUrl);
    final userAgentController = TextEditingController(
      text: channel?.sources.isNotEmpty == true
          ? channel!.sources[0].userAgent ?? ''
          : '',
    );
    final refererController = TextEditingController(
      text: channel?.sources.isNotEmpty == true
          ? channel!.sources[0].referer ?? ''
          : '',
    );
    String streamType = 'm3u8';

    List<VideoSource> sources = channel?.sources != null
        ? List.from(channel!.sources)
        : [VideoSource(quality: 'Auto', url: '', drmData: {})];

    if (channel?.sources.isNotEmpty == true &&
        channel!.sources[0].drmData != null &&
        channel.sources[0].drmData!.isNotEmpty) {
      streamType = 'drm';
    }

    final playlistService = PlaylistService();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.darkBg,
          title: Text(
            channel == null ? 'إضافة قناة' : 'تعديل قناة',
            style: const TextStyle(color: AppTheme.primaryGold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'اسم القناة',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextField(
                    controller: imageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'رابط صورة القناة',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'نوع الرابط',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                  DropdownButton<String>(
                    value: streamType,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardBg,
                    items: const [
                      DropdownMenuItem(
                        value: 'm3u8',
                        child: Text(
                          'رابط عادي (m3u8)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'drm',
                        child: Text(
                          'رابط مشفر (DRM/MPD)',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setDialogState(() => streamType = val!);
                    },
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  const Text(
                    'قائمة الجودات / الروابط',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sources.asMap().entries.map((entry) {
                    int idx = entry.key;
                    VideoSource source = entry.value;

                    final qController = TextEditingController(
                      text: source.quality,
                    );
                    final uController = TextEditingController(text: source.url);
                    final keyController = TextEditingController(
                      text: source.drmData?['key'] ?? '',
                    );

                    return Card(
                      color: Colors.white.withAlpha(10),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'HD',
                                      hintStyle: TextStyle(
                                        color: Colors.white38,
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    controller: qController,
                                    onChanged: (val) {
                                      sources[idx] = VideoSource(
                                        quality: val,
                                        url: sources[idx].url,
                                        drmData: sources[idx].drmData,
                                        userAgent: sources[idx].userAgent,
                                        referer: sources[idx].referer,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 6,
                                  child: TextField(
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'رابط التشغيل',
                                      hintStyle: TextStyle(
                                        color: Colors.white38,
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    controller: uController,
                                    onChanged: (val) {
                                      sources[idx] = VideoSource(
                                        quality: sources[idx].quality,
                                        url: val,
                                        drmData: sources[idx].drmData,
                                        userAgent: sources[idx].userAgent,
                                        referer: sources[idx].referer,
                                      );
                                      setDialogState(() {});
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => setDialogState(
                                    () => sources.removeAt(idx),
                                  ),
                                ),
                              ],
                            ),
                            if (streamType == 'drm') ...[
                              const SizedBox(height: 8),
                              TextField(
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'DRM Key (مفتاح التشفير)',
                                  hintStyle: TextStyle(color: Colors.white38),
                                ),
                                controller: keyController,
                                onChanged: (val) {
                                  Map<String, String> drm = Map.from(
                                    sources[idx].drmData ?? {},
                                  );
                                  drm['key'] = val;
                                  sources[idx] = VideoSource(
                                    quality: sources[idx].quality,
                                    url: sources[idx].url,
                                    drmData: drm,
                                    userAgent: sources[idx].userAgent,
                                    referer: sources[idx].referer,
                                  );
                                },
                              ),
                            ],
                            if (source.url.isNotEmpty &&
                                (source.url.toLowerCase().contains('.m3u8') ||
                                    source.url.toLowerCase().contains('.mpd') ||
                                    source.url.toLowerCase().contains(
                                      '/playlist',
                                    )))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final extracted = await playlistService
                                        .extractQualities(
                                          source.url,
                                          userAgent: userAgentController.text,
                                          referer: refererController.text,
                                        );
                                    // Preserve DRM and Header data
                                    final originalDrm = source.drmData;
                                    final originalUa = source.userAgent;
                                    final originalRef = source.referer;

                                    List<VideoSource> processedExtracted =
                                        extracted.map((s) {
                                          return VideoSource(
                                            quality: s.quality,
                                            url: s.url,
                                            drmData: originalDrm,
                                            userAgent:
                                                s.userAgent ?? originalUa,
                                            referer: s.referer ?? originalRef,
                                          );
                                        }).toList();

                                    if (extracted.length > 1 ||
                                        (extracted.isNotEmpty &&
                                            extracted[0].quality !=
                                                'Original' &&
                                            extracted[0].quality != 'Auto')) {
                                      setDialogState(() {
                                        sources.removeAt(idx);
                                        sources.insertAll(
                                          idx,
                                          processedExtracted,
                                        );
                                      });
                                    } else if (extracted.isNotEmpty &&
                                        extracted[0].quality == 'Auto') {
                                      setDialogState(() {
                                        sources[idx] = processedExtracted[0];
                                      });
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'لم يتم العثور على جودات إضافية',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.auto_fix_high,
                                    size: 18,
                                  ),
                                  label: const Text('استخراج تلقائي للجودات'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.withAlpha(80),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => setDialogState(
                      () => sources.add(
                        VideoSource(
                          quality: 'Auto',
                          url: '',
                          drmData: streamType == 'drm' ? {} : null,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة رابط جودة آخر'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGold,
                      side: const BorderSide(color: AppTheme.primaryGold),
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  const Text(
                    'إعدادات الرأس (اختياري)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                  TextField(
                    controller: userAgentController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'User-Agent',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  TextField(
                    controller: refererController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Referer',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final String userAgent = userAgentController.text.trim();
                final String referer = refererController.text.trim();
                final updatedSources = sources
                    .map(
                      (s) => VideoSource(
                        quality: s.quality,
                        url: s.url,
                        drmData: s.drmData,
                        userAgent: userAgent.isNotEmpty ? userAgent : null,
                        referer: referer.isNotEmpty ? referer : null,
                      ),
                    )
                    .toList();

                if (channel == null) {
                  await FirebaseService().addChannel(
                    category.id,
                    nameController.text,
                    imageController.text,
                    updatedSources,
                  );
                } else {
                  await FirebaseService().updateChannel(
                    channel.id,
                    nameController.text,
                    imageController.text,
                    updatedSources,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ القناة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إدارة قنوات: ${category.name}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChannelDialog(context),
        backgroundColor: AppTheme.primaryGold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<List<ChannelModel>>(
        stream: FirebaseService().getChannels(category.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد قنوات حالياً'));
          }
          final channels = snapshot.data!;
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: channels.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = channels.removeAt(oldIndex);
              channels.insert(newIndex, item);
              FirebaseService().reorderChannels(channels);
            },
            itemBuilder: (context, index) {
              final ch = channels[index];
              return Card(
                key: ValueKey(ch.id),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: AppTheme.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  title: Text(
                    ch.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${ch.sources.length} جودات متوفرة',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: ch.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.white10),
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () =>
                            _showChannelDialog(context, channel: ch),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => FirebaseService().deleteChannel(ch.id),
                      ),
                      const Icon(Icons.drag_handle, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
