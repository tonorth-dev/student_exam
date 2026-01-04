import 'package:student_exam/common/http_util.dart';

/// 自研题库API
class SubjectApi {
  /// 获取题目列表（学生端）
  /// 根据学生的job_code获取对应学科类别的随机题目
  static Future<dynamic> getSubjectList({Map<String, dynamic>? params}) async {
    return await HttpUtil.get("/student/subject/list", params: params);
  }

  /// 获取AI题库列表（学生端）
  /// 根据学生的job_code获取AI推荐题目
  /// type: 1-岗位题目, 2-专业题目
  static Future<dynamic> getAISubjectList({Map<String, dynamic>? params}) async {
    return await HttpUtil.get(
      "/student/subject/ai",
      params: params,
      timeout: const Duration(seconds: 60),
    );
  }
}
