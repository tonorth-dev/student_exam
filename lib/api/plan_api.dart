import 'package:hongshi_admin/common/http_util.dart';

class PlanApi {

  static Future<dynamic> planList({Map<String, dynamic>? params}) async {
    return await HttpUtil.get("/plan/list", params: params);
  }

  static Future<dynamic> planInsert({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/plan/insert", params: params);
  }

  static Future<dynamic> planDelete({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/plan/delete", params: params);
  }

  static Future<dynamic> planUpdate({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/plan/update", params: params);
  }

  static Future<dynamic> planSearch({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/plan/list", params: params);
  }
}
