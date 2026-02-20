class ChannelModel {
  final String id;
  final String categoryId;
  final String name;
  final String imageUrl;
  final List<VideoSource> sources;
  final int order;

  ChannelModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.sources,
    this.order = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'sources': sources.map((e) => e.toMap()).toList(),
      'order': order,
    };
  }

  factory ChannelModel.fromMap(Map<String, dynamic> map, String id) {
    return ChannelModel(
      id: id,
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      sources: (map['sources'] as List? ?? [])
          .map((e) => VideoSource.fromMap(e as Map<String, dynamic>))
          .toList(),
      order: map['order'] ?? 0,
    );
  }
}

class VideoSource {
  final String quality;
  final String url;
  final Map<String, String>? drmData; // { 'keyId': '...', 'key': '...' }
  final String? userAgent; // User-Agent header (اختياري)
  final String? referer; // Referer header (اختياري)

  VideoSource({
    required this.quality,
    required this.url,
    this.drmData,
    this.userAgent,
    this.referer,
  });

  Map<String, dynamic> toMap() {
    return {
      'quality': quality,
      'url': url,
      if (drmData != null) 'drmData': drmData,
      if (userAgent != null && userAgent!.isNotEmpty) 'userAgent': userAgent,
      if (referer != null && referer!.isNotEmpty) 'referer': referer,
    };
  }

  factory VideoSource.fromMap(Map<String, dynamic> map) {
    return VideoSource(
      quality: map['quality'] ?? '',
      url: map['url'] ?? '',
      drmData: map['drmData'] != null
          ? Map<String, String>.from(map['drmData'])
          : null,
      userAgent: map['userAgent'] as String?,
      referer: map['referer'] as String?,
    );
  }
}
