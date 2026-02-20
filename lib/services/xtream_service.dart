import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/xtream_config.dart';
import '../models/category_model.dart';
import '../models/channel_model.dart';

class XtreamService {
  String _normalizeBaseUrl(String url) {
    if (!url.endsWith('/')) {
      return '$url/';
    }
    return url;
  }

  Future<List<CategoryModel>> getCategories(XtreamConfig config) async {
    final baseUrl = _normalizeBaseUrl(config.baseUrl);
    final url =
        '${baseUrl}player_api.php?username=${config.username}&password=${config.password}&action=get_live_categories';

    try {
      print('Fetching Xtream categories from: $url');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Found ${data.length} categories from Xtream');
        return data.map((item) {
          final id = item['category_id'].toString();
          final name = item['category_name'].toString();
          // Helper to safely extract image
          String getImage(Map<String, dynamic> data, List<String> keys) {
            for (var key in keys) {
              if (data[key] != null && data[key].toString().isNotEmpty) {
                final url = data[key].toString().trim();
                if (url.startsWith('http')) return url;
              }
            }
            return '';
          }

          final icon = getImage(item, [
            'category_icon',
            'category_image',
            'logo',
            'icon',
          ]);

          return CategoryModel(
            id: 'xtream_$id',
            name: name,
            imageUrl: icon,
            order: 0,
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching Xtream categories: $e');
    }
    return [];
  }

  Future<List<ChannelModel>> getChannels(
    XtreamConfig config,
    String? xtreamCategoryId,
  ) async {
    final baseUrl = _normalizeBaseUrl(config.baseUrl);
    final url =
        '${baseUrl}player_api.php?username=${config.username}&password=${config.password}&action=get_live_streams${xtreamCategoryId != null ? '&category_id=$xtreamCategoryId' : ''}';

    try {
      print('Fetching Xtream channels for category $xtreamCategoryId');
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Found ${data.length} channels for category $xtreamCategoryId');
        return data.map((item) {
          final streamId = item['stream_id'];

          // Helper to safely extract image
          String getImage(Map<String, dynamic> data, List<String> keys) {
            for (var key in keys) {
              if (data[key] != null && data[key].toString().isNotEmpty) {
                final url = data[key].toString().trim();
                if (url.startsWith('http')) return url;
              }
            }
            return '';
          }

          final imageUrl = getImage(item, [
            'stream_icon',
            'stream_logo',
            'logo',
            'icon',
            'thumb',
          ]);

          // 1. Auto Quality (HLS/M3U8) - Best for adaptive streaming
          final m3u8Url =
              '${baseUrl}live/${config.username}/${config.password}/$streamId.m3u8';

          // 2. Original Quality (MPEG-TS) - Backup
          final tsUrl =
              '${baseUrl}live/${config.username}/${config.password}/$streamId.ts';

          return ChannelModel(
            id: 'xtream_$streamId',
            categoryId: 'xtream_${item['category_id']}',
            name: item['name'] ?? 'Unknown Channel',
            imageUrl: imageUrl,
            sources: [
              VideoSource(
                quality: 'Auto',
                url: m3u8Url,
                userAgent: 'IPTVSmartersPro',
                referer: baseUrl,
              ),
              VideoSource(
                quality: 'Original (TS)',
                url: tsUrl,
                userAgent: 'IPTVSmartersPro',
                referer: baseUrl,
              ),
            ],

            order: 0,
          );
        }).toList();
      }
    } catch (e) {
      print('Error fetching Xtream channels: $e');
    }
    return [];
  }
}
