import 'package:http/http.dart' as http;
import '../models/channel_model.dart';

class PlaylistService {
  /// Extract qualities from a URL (supports m3u8, mpd, and dynamic php links)
  Future<List<VideoSource>> extractQualities(
    String url, {
    String? userAgent,
    String? referer,
  }) async {
    String cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return [];

    Map<String, String> headers = {
      'User-Agent': userAgent?.isNotEmpty == true
          ? userAgent!
          : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    if (referer != null && referer.isNotEmpty) headers['Referer'] = referer;

    try {
      // Step 1: Head request or fast GET to check content type if extension is missing
      final initialResponse = await http
          .get(Uri.parse(cleanUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (initialResponse.statusCode != 200) {
        return [VideoSource(quality: 'Auto', url: cleanUrl)];
      }

      final body = initialResponse.body;
      final contentType =
          initialResponse.headers['content-type']?.toLowerCase() ?? '';
      final effectiveUrl = initialResponse.request?.url.toString() ?? cleanUrl;

      // Check if it's an M3U8 (by header or content)
      if (body.contains('#EXTM3U') ||
          contentType.contains('application/x-mpegurl') ||
          contentType.contains('vnd.apple.mpegurl') ||
          effectiveUrl.contains('.m3u8')) {
        return await _parseM3U8Content(body, effectiveUrl, headers);
      }
      // Check if it's an MPD
      else if (body.contains('<MPD') ||
          contentType.contains('application/dash+xml') ||
          effectiveUrl.contains('.mpd')) {
        return _parseMpdContent(body, effectiveUrl);
      }

      // If it's just a direct video link or unknown
      return [VideoSource(quality: 'Original', url: effectiveUrl)];
    } catch (e) {
      print('Extraction Error: $e');
      return [VideoSource(quality: 'Auto', url: cleanUrl)];
    }
  }

  Future<List<VideoSource>> _parseM3U8Content(
    String body,
    String effectiveUrl,
    Map<String, String> headers,
  ) async {
    final lines = body.split('\n');
    List<VideoSource> sources = [];

    // Master Playlist detection
    if (body.contains('#EXT-X-STREAM-INF')) {
      sources.add(VideoSource(quality: 'Auto', url: effectiveUrl));

      for (int i = 0; i < lines.length; i++) {
        String line = lines[i].trim();
        if (line.startsWith('#EXT-X-STREAM-INF')) {
          String quality = _parseM3U8Metadata(line);

          // Next line that isn't a comment/empty is the URL
          int nextIdx = i + 1;
          while (nextIdx < lines.length &&
              (lines[nextIdx].trim().isEmpty ||
                  lines[nextIdx].trim().startsWith('#'))) {
            nextIdx++;
          }

          if (nextIdx < lines.length) {
            String streamUrl = lines[nextIdx].trim();
            Uri baseUri = Uri.parse(effectiveUrl);
            Uri resolvedUri = baseUri.resolve(streamUrl);

            // Re-apply query params for tokens
            if (baseUri.hasQuery && !resolvedUri.hasQuery) {
              resolvedUri = resolvedUri.replace(
                queryParameters: baseUri.queryParameters,
              );
            }

            String finalUrl = resolvedUri.toString();

            // Avoid adding same quality twice
            if (!sources.any((s) => s.quality == quality)) {
              sources.add(VideoSource(quality: quality, url: finalUrl));
            } else {
              sources.add(
                VideoSource(quality: '$quality (alt)', url: finalUrl),
              );
            }
          }
        }
      }
    } else {
      // Single Quality Playlist
      sources.add(VideoSource(quality: 'Original', url: effectiveUrl));
    }

    return sources;
  }

  String _parseM3U8Metadata(String line) {
    // 1. Resolution
    final resMatch = RegExp(r'RESOLUTION=(\d+x\d+)').firstMatch(line);
    if (resMatch != null) {
      String res = resMatch.group(1)!;
      int height = int.parse(res.split('x').last);
      if (height >= 1080) return '1080p';
      if (height >= 720) return '720p';
      if (height >= 480) return '480p';
      if (height >= 360) return '360p';
      return '${height}p';
    }

    // 2. Name
    final nameMatch = RegExp(r'NAME="([^"]+)"').firstMatch(line);
    if (nameMatch != null) return nameMatch.group(1)!;

    // 3. Bandwidth
    final bandMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
    if (bandMatch != null) {
      int bw = int.parse(bandMatch.group(1)!);
      if (bw > 5000000) return '1080p';
      if (bw > 2500000) return '720p';
      if (bw > 1000000) return '480p';
    }

    return 'HD';
  }

  List<VideoSource> _parseMpdContent(String body, String effectiveUrl) {
    List<VideoSource> sources = [];
    sources.add(VideoSource(quality: 'Auto', url: effectiveUrl));

    // Regex to find Representation tags and extract attributes
    // We look for width, height, bandwidth

    // This regex is a bit simplistic, let's try a better approach iterating matches
    // We want to capture the whole tag to extract attributes from it
    final tagRegex = RegExp(
      r'<Representation([^>]+)>',
      caseSensitive: false,
      multiLine: true,
    );

    final matches = tagRegex.allMatches(body);
    for (final match in matches) {
      String attributes = match.group(1) ?? '';

      int? height;
      int? bandwidth;

      // Extract height
      final heightMatch = RegExp(r'height="(\d+)"').firstMatch(attributes);
      if (heightMatch != null) {
        height = int.tryParse(heightMatch.group(1)!);
      }

      // Extract bandwidth
      final bandwidthMatch = RegExp(
        r'bandwidth="(\d+)"',
      ).firstMatch(attributes);
      if (bandwidthMatch != null) {
        bandwidth = int.tryParse(bandwidthMatch.group(1)!);
      }

      if (height != null) {
        String quality;
        if (height >= 2160)
          quality = '4K';
        else if (height >= 1440)
          quality = '2K';
        else if (height >= 1080)
          quality = '1080p';
        else if (height >= 720)
          quality = '720p';
        else if (height >= 480)
          quality = '480p';
        else if (height >= 360)
          quality = '360p';
        else
          quality = '${height}p';

        // Check if we already have this quality
        if (!sources.any((s) => s.quality == quality)) {
          sources.add(VideoSource(quality: quality, url: effectiveUrl));
        }
      } else if (bandwidth != null) {
        // Fallback to bandwidth if height is missing
        String quality;
        if (bandwidth > 10000000)
          quality = '4K'; // > 10Mbps
        else if (bandwidth > 5000000)
          quality = '1080p'; // > 5Mbps
        else if (bandwidth > 2500000)
          quality = '720p'; // > 2.5Mbps
        else if (bandwidth > 1000000)
          quality = '480p'; // > 1Mbps
        else
          quality = 'Low';

        if (!sources.any((s) => s.quality == quality)) {
          sources.add(VideoSource(quality: quality, url: effectiveUrl));
        }
      }
    }

    // Sort by quality (high to low)
    // We can't easily sort without parsing back to numbers, but typically they appear in some order.
    // Let's just leave them as found or user can sort.
    // Actually, UI sorts them.

    return sources.isEmpty
        ? [VideoSource(quality: 'Auto', url: effectiveUrl)]
        : sources;
  }
}
