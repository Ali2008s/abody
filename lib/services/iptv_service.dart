import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel_model.dart';

class IptvService {
  Future<List<ChannelModel>> fetchIptvChannels({
    required String host,
    required String username,
    required String password,
    required String categoryId,
  }) async {
    try {
      String baseUrl = host.trim();
      if (!baseUrl.startsWith('http')) {
        baseUrl = 'http://$baseUrl';
      }
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }

      final url = Uri.parse(
        '$baseUrl/player_api.php?username=$username&password=$password&action=get_live_streams',
      );

      print('Fetching IPTV channels from: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.map((stream) {
          final String streamId = stream['stream_id']?.toString() ?? '';
          final String name = stream['name'] ?? 'بث مباشر';
          final String streamIcon = stream['stream_icon'] ?? '';

          // Construct the stream URL
          // Typically: http://host:port/live/username/password/stream_id.m3u8
          final String streamUrl =
              '$baseUrl/live/$username/$password/$streamId.m3u8';

          return ChannelModel(
            id: '', // Will be set by Firestore
            categoryId: categoryId,
            name: name,
            imageUrl: streamIcon,
            sources: [VideoSource(quality: 'Auto', url: streamUrl)],
          );
        }).toList();
      } else {
        throw Exception('Failed to load channels: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching IPTV channels: $e');
      return [];
    }
  }
}
