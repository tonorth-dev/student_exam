import 'package:student_exam/common/http_util.dart';

class StudentQuestionApi {

  static Future<dynamic> questionList({Map<String, dynamic>? params}) async {
    return await HttpUtil.get("/question/list", params: params);
  }

  static Future<dynamic> questionInsert({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/question/insert", params: params);
  }

  static Future<dynamic> questionDelete({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/question/delete", params: params);
  }

  static Future<dynamic> questionUpdate({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/question/update", params: params);
  }

  static Future<dynamic> questionSearch({Map<String, dynamic>? params}) async {
    return await HttpUtil.post("/question/list", params: params);
  }
}
