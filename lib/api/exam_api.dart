import 'dart:convert';
import 'dart:io';

import 'package:student_exam/common/http_util.dart';
import 'package:dio/dio.dart';

class ExamApi {
  static Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Future<dynamic> pullExam() async {
    try {
      // 发送POST请求
      dynamic response = await HttpUtil.get('/teacher/exam/pull', params: {});

      return response;
    } catch (e) {
      print('Error in createExam: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> examQuestions(Map<String, dynamic> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'student_id': handleNullOrEmpty(params['student_id'].toString()),
        'exam_id': handleNullOrEmpty(params['exam_id'].toString()),
        'unit_id': handleNullOrEmpty(params['unit_id'].toString()),
      };
      dynamic response = await HttpUtil.get('/teacher/exam/questions', params: finalParams);

      return response;
    } catch (e) {
      print('Error in examQuestions: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> examUnits(Map<String, dynamic> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'student_id': handleNullOrEmpty(params['student_id'].toString()),
        'exam_id': handleNullOrEmpty(params['exam_id'].toString()),
      };
      dynamic response = await HttpUtil.get('/teacher/exam/units', params: finalParams);

      return response;
    } catch (e) {
      print('Error in examQuestions: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 获取试卷列表
  static Future<dynamic> examList(Map<String, String?> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'page': params['page'] ?? '1', // 默认值为 '1'
        'pageSize': params['size'] ?? '15', // 重命名并设置默认值
        'keyword': handleNullOrEmpty(params['keyword']),
        'major_id': handleNullOrEmpty(params['major_id']),
        'job_code': handleNullOrEmpty(params['job_code']),
      };

      return await HttpUtil.get("/admin/exam/exam", params: finalParams);
    } catch (e) {
      print('Error in getExamList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 查看单个试卷
  static Future<dynamic> getExamByID(int id) async {
    try {
      return await HttpUtil.get("/admin/exam/exam/$id");
    } catch (e) {
      print('Error in getExamByID: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 更新试卷
  static Future<dynamic> examUpdate(int id, Map<String, dynamic> params) async {
    try {
      // 发送PUT请求
      dynamic response = await HttpUtil.put("/admin/exam/exam/$id", params: params);

      return response;
    } catch (e) {
      print('Error in updateExam: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 删除试卷
  static Future<dynamic> examDelete(String id) async {
    try {
      return await HttpUtil.delete("/admin/exam/exam/$id");
    } catch (e) {
      print('Error in deleteExam: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 获取试卷目录树
  static Future<dynamic> getExamDirectoryTree(String id) async {
    try {
      return await HttpUtil.get("/admin/exam/directory/$id");
    } catch (e) {
      print('Error in getExamDirectoryTree: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static String handleNullOrEmpty(String? value) {
    if (value == null || value == 'null') {
      return '';
    }
    return value;
  }
}
