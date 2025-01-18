import 'dart:convert';
import 'dart:io';

import 'package:student_exam/common/http_util.dart';
import 'package:dio/dio.dart';

class BookTemplateApi {

  static Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // 获取模板列表
  static Future<dynamic> templateList(Map<String, String?> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'page': params['page'] ?? '1', // 默认值为 '1'
        'pageSize': params['size'] ?? '15', // 重命名并设置默认值
        // 'keyword': handleNullOrEmpty(params['keyword']),
        // 'level': handleNullOrEmpty(params['level']),
        // 'major_id': handleNullOrEmpty(params['major_id']),
      };

      return await HttpUtil.get("/admin/book/template/list", params: finalParams);
    } catch (e) {
      print('Error in templateList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static String handleNullOrEmpty(String? value) {
    if (value == null || value == 'null') {
      return '';
    }
    return value;
  }


  // 创建模板
  static Future<dynamic> templateCreate(Map<String, dynamic> params) async {
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
      dynamic response = await HttpUtil.post('/admin/book/template', params: params);

      return response;
    } catch (e) {
      print('Error in templateCreate: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 查看模板详细
  static Future<dynamic> templateDetail(int id) async {
    try {
      return await HttpUtil.get("/admin/book/template/$id");
    } catch (e) {
      print('Error in templateDetail: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 删除模板
  static Future<dynamic> templateDelete(int id) async {
    try {
      return await HttpUtil.delete("/admin/book/template/$id");
    } catch (e) {
      print('Error in templateDelete: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }


}
