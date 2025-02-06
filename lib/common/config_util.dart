class ConfigUtil {
  static const String baseUrl = "https://admin.81hongshi.com";
  // static const String baseUrl = "http://127.0.0.1";
  static const String httpPort = "";
  static final String fullUrl = _buildFullUrl();
  static const String ossUrl = "https://oss.81hongshi.com";
  static const String ossPort = "9000";
  static const String ossPrefix = "/hongshi";
  // static const String wsUrl = "ws://127.0.0.1";
  static const String wsUrl = "ws://47.94.139.86";
  static const String wsPort = "13921";

  static String _buildFullUrl() {
    return httpPort.isEmpty ? baseUrl : "$baseUrl:$httpPort";
  }
}
