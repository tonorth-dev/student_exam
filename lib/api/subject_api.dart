import 'package:student_exam/common/http_util.dart';

/// 专业题库API
class SubjectApi {
  /// 获取学生的subject_category列表
  static Future<dynamic> getSubjectCategories() async {
    try {
      return await HttpUtil.get("/student/subject/categories");
    } catch (e) {
      print('Error getting subject categories: $e');
      rethrow;
    }
  }

  /// 获取题目列表（学生端，按category分页）
  static Future<dynamic> getSubjectList({
    required int subjectCategory,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return await HttpUtil.get("/student/subject/list", params: {
        'subject_category': subjectCategory,
        'page': page,
        'pageSize': pageSize,
      });
    } catch (e) {
      print('Error getting subject list: $e');
      rethrow;
    }
  }

  /// 对题目进行评分
  static Future<dynamic> rateSubject({
    required int subjectId,
    required int rating,
  }) async {
    try {
      return await HttpUtil.post("/student/subject/rate", params: {
        'subject_id': subjectId,
        'rating': rating,
      });
    } catch (e) {
      print('Error rating subject: $e');
      rethrow;
    }
  }

  /// 获取红师AI题库列表（学生端）
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
