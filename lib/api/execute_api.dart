import 'package:admin_flutter/common/http_util.dart';

class ExecuteApi {

  static Future<dynamic> executeList({Map<String, dynamic>? params}) async {
    return await HttpUtil.get("/execute/list", params: params);
  }

  static Future<dynamic> executeInsert({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/execute/insert", params: params);
  }

  static Future<dynamic> executeDelete({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/execute/delete", params: params);
  }

  static Future<dynamic> executeUpdate({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/execute/update", params: params);
  }

  static Future<dynamic> executeSearch({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/execute/list", params: params);
  }
}
