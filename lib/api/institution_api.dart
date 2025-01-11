import 'dart:io';

import 'package:hongshi_admin/common/http_util.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';

class InstitutionApi {

  static Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // 获取题目列表
  static Future<dynamic> institutionList({Map<String, dynamic>? params}) async {
    try {
      // 设置默认参数
      final defaultParams = {
        'page': '1',
        'pageSize': '15',
        'keyword': handleNullOrEmpty(''),
        'province': handleNullOrEmpty(''),
        'city': handleNullOrEmpty(''),
      };

      // 合并默认参数和传入的参数
      final finalParams = {...defaultParams, ...?params};

      // 最多重试3次
      const maxRetries = 3;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          // 发起请求
          final response = await HttpUtil.get("/admin/institution/institution/list", params: finalParams);
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
      print('Error in institutionList: $e');
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
  static Future<dynamic> institutionCreate(Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = ['name', 'city', 'leader'];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      return await HttpUtil.post("/admin/institution/institution", params: params);
    } catch (e) {
      print('Error in institutionCreate: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 查看题目详细
  static Future<dynamic> institutionDetail(String id) async {
    try {
      return await HttpUtil.get("/admin/institution/institution/$id");
    } catch (e) {
      print('Error in institutionDetail: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 更新题目
  static Future<dynamic> institutionUpdate(int id, Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = ['name', 'city', 'leader'];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      return await HttpUtil.put("/admin/institution/institution/$id", params: params);
    } catch (e) {
      print('Error in institutionCreate: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 删除题目
  static Future<dynamic> institutionDelete(String id) async {
    try {
      return await HttpUtil.delete("/admin/institution/institution/$id");
    } catch (e) {
      print('Error in institutionDelete: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> institutionBatchImport(File file) async {
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
      return await HttpUtil.uploadFile("/admin/institution/institution/batch-import", formData, showMsg: false);
    } catch (e) {
      print('调用导入接口时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 导出题目为 CSV
  static Future<dynamic> institutionExport({
    required String page,
    required String pageSize,
    required String search,
    required String cate,
    required String institution_id,
  }) async {
    try {
      Map<String, dynamic> params = {
        'page': page,
        'pageSize': pageSize,
        'search': search,
        'cate': cate,
        'institution_id': institution_id,
      };
      return await HttpUtil.get("/admin/institution/institution/export", params: params);
    } catch (e) {
      print('Error in institutionExport: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> auditInstitution(int institutionId, int status) async {
    try {
      return await  HttpUtil.put('/admin/institution/institution/$institutionId/audit_ret/$status');
    } catch (e) {
      throw Exception('审核请求失败: $e');
    }
  }

}
