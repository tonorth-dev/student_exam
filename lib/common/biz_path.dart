import 'app_data.dart';
import 'biz_type.dart';

class BizPath {
  static Future<String> apply(String url) async {
    final data = await LoginData.read();
    if (data.bizType != BizType.directOfficer) {
      return url;
    }
    if (url.startsWith("/base/") ||
        url.startsWith("/jwt/") ||
        url.startsWith("/admin/config")) {
      return url;
    }
    if (url.startsWith("/student") || url.startsWith("/teacher")) {
      return "/officer$url";
    }
    return url;
  }

  static Future<String> socketPath() async {
    final data = await LoginData.read();
    if (data.bizType == BizType.directOfficer) {
      return "/officer/ws/dialogue";
    }
    return "/ws/dialogue";
  }
}
