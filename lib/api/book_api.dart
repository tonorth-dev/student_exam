import 'dart:convert';
import 'dart:io';

import 'package:hongshi_admin/common/http_util.dart';
import 'package:dio/dio.dart';

class BookApi {

  static Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // 获取题目列表
  static Future<dynamic> bookList(Map<String, String?> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'page': params['page'] ?? '1', // 默认值为 '1'
        'pageSize': params['size'] ?? '15', // 重命名并设置默认值
        'keyword': handleNullOrEmpty(params['keyword']),
        'level': handleNullOrEmpty(params['level']),
        'major_id': handleNullOrEmpty(params['major_id']),
      };

      return await HttpUtil.get("/admin/book/book/list", params: finalParams);
    } catch (e) {
      print('Error in bookList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static String handleNullOrEmpty(String? value) {
    if (value == null || value == 'null') {
      return '';
    }
    return value;
  }


  // 创建题目
  static Future<dynamic> bookCreate(Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = [
        'name',
        'major_id',
        'component',
        'unit_number',
      ];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      // 发送POST请求
      dynamic response = await HttpUtil.post('/admin/book/book', params: params);

      return response;
    } catch (e) {
      print('Error in bookCreate: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 查看题目详细
  static Future<dynamic> bookDetail(int id) async {
    try {
      return await HttpUtil.get("/admin/book/book/$id");
    } catch (e) {
      print('Error in bookDetail: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> generateBook(int bookId, {bool isTeacher = false}) async {
    try {
      // 构建查询参数
      final Map<String, String> queryParams = {
        'is_teacher': isTeacher ? '1' : '0',
      };

      // 发送GET请求
      dynamic response = await HttpUtil.get("/admin/book/book/gen/$bookId", params: queryParams);
      return response;
    } catch (e) {
      print('Error in generateBookData: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 删除题目
  static Future<dynamic> bookDelete(String id) async {
    try {
      return await HttpUtil.delete("/admin/book/book/$id");
    } catch (e) {
      print('Error in bookDelete: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> updateQuestions(int id, Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = [
        'old_question_id',
        'new_question_id',
      ];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('缺少必填字段: $field');
        }
      }

      return await HttpUtil.put("/admin/book/book/questions/$id", params: params);
    } catch (e) {
      print('更新题目时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }
}
