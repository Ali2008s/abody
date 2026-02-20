class XtreamConfig {
  final String serverUrl;
  final String username;
  final String password;

  XtreamConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {'serverUrl': serverUrl, 'username': username, 'password': password};
  }

  factory XtreamConfig.fromMap(Map<String, dynamic> map) {
    return XtreamConfig(
      serverUrl: map['serverUrl'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
    );
  }

  String get baseUrl {
    String url = serverUrl.trim();
    if (url.endsWith('player_api.php')) {
      url = url.substring(0, url.length - 'player_api.php'.length);
    }
    return url.endsWith('/') ? url : '$url/';
  }
}
