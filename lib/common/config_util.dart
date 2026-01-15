import '../api/config_api.dart';

class ConfigUtil {
  // static const String baseUrl = "https://admin.81hongshi.com";
  // static const String httpPort = "";
  static const String baseUrl = "http://127.0.0.1";
  static const String httpPort = "13921";
  static final String fullUrl = _buildFullUrl();
  static final String appVersion = "1.3.0";

  static String _buildFullUrl() {
    return httpPort.isEmpty ? baseUrl : "$baseUrl:$httpPort";
  }

  // 默认值，在成功获取服务端配置前使用
  static String _ossUrl = "";
  static String _wsUrl = "";
  static String _wsPort = "";

  static String get ossUrl => _ossUrl;
  static String get wsUrl => _wsUrl;
  static String get wsPort => _wsPort;

  // 在 App 启动时调用此方法初始化配置
  static Future<void> initialize() async {
    try {
      final data = await ConfigApi.configProto();
      if (data != null && data["oss_url"] != null) {
        _ossUrl = data["oss_url"];
      }
      if (data != null && data["ws_url"] != null) {
        _wsUrl = data["ws_url"];
      }
      if (data != null && data["ws_port"] != null) {
        _wsPort = data["ws_port"];
      }
    } catch (e) {
      print('Failed to fetch ossUrl from server: $e');
      // 保持使用默认值
    }
  }
}
