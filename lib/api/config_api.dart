import 'package:student_exam/common/http_util.dart';

class ConfigApi {

  static Future<dynamic> configList() async {
    try {
      return await HttpUtil.get("/admin/config/config/list");
    } catch (e) {
      print('Error in configList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> configArea(String name, String level, String? parentId) async {
    try {
      return await HttpUtil.get("/admin/config/config/$name?level=$level&parent_id=$parentId");
    } catch (e) {
      print('Error in configList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> configEncr() async {
    try {
      return await HttpUtil.get("/admin/config/config/encr");
    } catch (e) {
      print('Error in configList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }
}
