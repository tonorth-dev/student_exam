import 'package:student_exam/common/http_util.dart';

class UserApi {
  static Future<dynamic> login(Map<String, dynamic> params) async {
    List<String> requiredFields = ['phone', 'code'];
    for (var field in requiredFields) {
      if (!params.containsKey(field) || params[field] == null) {
        throw ArgumentError('Missing required field: $field');
      }
    }
    return await HttpUtil.post('/base/student/login', params: params);
  }

  static Future<dynamic> sendSms(String phone) async {
    return await HttpUtil.post('/base/student/sms', params: {'phone': phone});
  }

  static Future<dynamic> userList({Map<String, dynamic>? params}) async {
    return await HttpUtil.get("/user/student/info", params: params);
  }

  static Future<dynamic> userInfo() async {
    return await HttpUtil.get("/jwt/valid_user");
  }
}
