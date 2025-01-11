import 'package:admin_flutter/common/http_util.dart';

class UserApi {

  static Future<dynamic> login(Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = [
        'username',
        'password',
        'captcha',
        'captchaId',
      ];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      // 发送POST请求
      dynamic response = await HttpUtil.post('/base/login', params: params);

      return response;
    } catch (e) {
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> captcha() async {
    try {
      // 发送POST请求
      dynamic response = await HttpUtil.post('/base/captcha');

      return response;
    } catch (e) {
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> userList({Map<String, dynamic>? params}) async {
    return await HttpUtil.get("/user/list", params: params);
  }

  static Future<dynamic> userInsert({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/user/insert", params: params);
  }

  static Future<dynamic> userDelete({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/user/delete", params: params);
  }

  static Future<dynamic> userUpdate({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/user/update", params: params);
  }
}
