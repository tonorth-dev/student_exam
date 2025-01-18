class ConfigUtil {
  // static const String baseUrl = "https://admin.81hongshi.com";
  static const String baseUrl = "http://127.0.0.1";
  static const String httpPort = "13921";
  static final String fullUrl = _buildFullUrl();
  static const String ossUrl = "http://123.56.83.210"; // todo 暂时使用ip
  static const String ossPort = "9000";
  static const String ossPrefix = "/hongshi";
  static const String wsUrl = "ws://127.0.0.1";

  static String _buildFullUrl() {
    return httpPort.isEmpty ? baseUrl : "$baseUrl:$httpPort";
  }
}
