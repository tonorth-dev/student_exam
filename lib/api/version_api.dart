import 'package:student_exam/common/http_util.dart';

class VersionApi {
  static const String VERSION_CHECK_URL = '/admin/config/version';

  static Future<Map<String, dynamic>> checkVersion() async {
    try {
      return await HttpUtil.get(VERSION_CHECK_URL, params: {"app": "student"});
    } catch (e) {
      rethrow; // 重新抛出异常以便调用者处理
    }
  }
}
