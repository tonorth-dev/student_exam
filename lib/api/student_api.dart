import 'dart:io';

import 'package:student_exam/common/http_util.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';

class StudentApi {

  static Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // 获取题目
  static Future<dynamic> questionPull({Map<String, dynamic>? params}) async {
    try {
      // 最多重试3次
      const maxRetries = 3;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          // 发起请求
          final response = await HttpUtil.get("student/psyc/pull", params: params);
          return response;
        } catch (e) {
          if (attempt < maxRetries) {
            // 如果不是最后一次尝试，等待一段时间后重试
            await Future.delayed(Duration(seconds: 2));
            print('Attempt $attempt failed, retrying...');
          } else {
            // 最后一次尝试失败，抛出异常
            print('All attempts failed: $e');
            throw e;
          }
        }
      }
    } catch (e) {
      print('Error in studentList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 获取题目
  static Future<dynamic> studentRecord({Map<String, dynamic>? params}) async {
    try {

      // 最多重试3次
      const maxRetries = 3;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          // 发起请求
          final response = await HttpUtil.get("student/psyc/pull", params: params);
          return response;
        } catch (e) {
          if (attempt < maxRetries) {
            // 如果不是最后一次尝试，等待一段时间后重试
            await Future.delayed(Duration(seconds: 2));
            print('Attempt $attempt failed, retrying...');
          } else {
            // 最后一次尝试失败，抛出异常
            print('All attempts failed: $e');
            throw e;
          }
        }
      }
    } catch (e) {
      print('Error in studentList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 创建题目
  static Future<dynamic> submit(Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = ['question_id', 'answer'];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      return await HttpUtil.post("/student/psyc/submit", params: params);
    } catch (e) {
      print('Error in psyc submit: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

}
