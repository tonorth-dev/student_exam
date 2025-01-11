import 'dart:convert';
import 'dart:io';

import 'package:admin_flutter/common/http_util.dart';
import 'package:dio/dio.dart';

class ExamTopicApi {
  static Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // 创建练习题
  static Future<dynamic> examTopicCreate(Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = [
        'class_id',
        'question_count',
      ];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      // 发送POST请求
      dynamic response = await HttpUtil.post('/admin/exam/topic', params: params);

      return response;
    } catch (e) {
      print('Error in createExam: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 获取练习题列表
  static Future<dynamic> examTopicList(Map<String, String> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'page': params['page'] ?? '1', // 默认值为 '1'
        'pageSize': params['size'] ?? '15', // 重命名并设置默认值
        'keyword': handleNullOrEmpty(params['keyword']),
        'exam_id': handleNullOrEmpty(params['exam_id']),
        'student_id': handleNullOrEmpty(params['student_id']),
      };

      return await HttpUtil.get("/admin/exam/topic/list", params: finalParams);
    } catch (e) {
      print('Error in getExamList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> examUnitList(Map<String, String> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'exam_id': handleNullOrEmpty(params['exam_id']),
      };

      return await HttpUtil.get("/admin/exam/unit/list", params: finalParams);
    } catch (e) {
      print('Error in getExamList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 查看单个练习题
  static Future<dynamic> getExamByID(int id) async {
    try {
      return await HttpUtil.get("/admin/exam/topic/$id");
    } catch (e) {
      print('Error in getExamByID: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 更新练习题
  static Future<dynamic> examTopicUpdate(int id, Map<String, dynamic> params) async {
    try {
      // 发送PUT请求
      dynamic response = await HttpUtil.put("/admin/exam/topic/$id", params: params);

      return response;
    } catch (e) {
      print('Error in updateExam: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 删除练习题
  static Future<dynamic> examTopicDelete(String id) async {
    try {
      return await HttpUtil.delete("/admin/exam/topic/$id");
    } catch (e) {
      print('Error in deleteExam: $e');
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
