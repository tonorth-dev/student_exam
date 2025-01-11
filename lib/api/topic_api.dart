import 'dart:io';

import 'package:admin_flutter/common/http_util.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';

class TopicApi {

  static Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // 获取题目列表
  static Future<dynamic> topicList(Map<String, String?> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'page': params['page'] ?? '1', // 默认值为 '1'
        'pageSize': params['size'] ?? '15', // 重命名并设置默认值
        'keyword': handleNullOrEmpty(params['keyword']),
        'cate': handleNullOrEmpty(params['cate']),
        'level': handleNullOrEmpty(params['level']),
        'status': handleNullOrEmpty(params['status']),
        'student_id': handleNullOrEmpty(params['student_id']),
        'major_id': handleNullOrEmpty(params['major_id']),
        'all': handleNullOrEmpty(params['all']),
      };

      return await HttpUtil.get("/admin/topic/topic/list", params: finalParams);
    } catch (e) {
      print('Error in topicList: $e');
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
  static Future<dynamic> topicCreate(Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = ['title', 'author', 'answer', 'cate', 'level', 'major_id', 'status'];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      return await HttpUtil.post("/admin/topic/topic", params: params);
    } catch (e) {
      print('Error in topicCreate: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 查看题目详细
  static Future<dynamic> topicDetail(String id) async {
    try {
      return await HttpUtil.get("/admin/topic/topic/$id");
    } catch (e) {
      print('Error in topicDetail: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 更新题目
  static Future<dynamic> topicUpdate(int id, Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = ['title', 'author', 'answer', 'cate', 'level', 'major_id', 'status'];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      return await HttpUtil.put("/admin/topic/topic/$id?invite=1", params: params);
    } catch (e) {
      print('Error in topicCreate: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 删除题目
  static Future<dynamic> topicDelete(String id) async {
    try {
      return await HttpUtil.delete("/admin/topic/topic/$id");
    } catch (e) {
      print('Error in topicDelete: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> topicBatchImport(File file) async {
    try {
      // 构造 MultipartFile 对象
      MultipartFile multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: basename(file.path), // 使用文件名
      );

      // 构造 FormData
      FormData formData = FormData.fromMap({
        'file': multipartFile, // 'file' 对应后端接收的字段名
      });

      // 调用上传接口
      return await HttpUtil.uploadFile("/admin/topic/topic/batch-import", formData, showMsg: false);
    } catch (e) {
      print('调用导入接口时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 导出题目为 CSV
  static Future<dynamic> topicExport({
    required String page,
    required String pageSize,
    required String search,
    required String cate,
    required String major_id,
  }) async {
    try {
      Map<String, dynamic> params = {
        'page': page,
        'pageSize': pageSize,
        'search': search,
        'cate': cate,
        'major_id': major_id,
      };
      return await HttpUtil.get("/admin/topic/topic/export", params: params);
    } catch (e) {
      print('Error in topicExport: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> auditTopic(int topicId, int status) async {
    try {
      return await  HttpUtil.put('/admin/topic/topic/$topicId/audit_ret/$status');
    } catch (e) {
      throw Exception('审核请求失败: $e');
    }
  }

}
