class VersionInfo {
  final String version;
  final String downloadUrl;

  VersionInfo({
    required this.version,
    required this.downloadUrl,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json, bool isMacOS) {
    return VersionInfo(
      version: json['app_version'] as String,
      downloadUrl: isMacOS ? json['app_url_mac'] as String : json['app_url_win'] as String,
    );
  }
}