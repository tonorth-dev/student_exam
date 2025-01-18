import 'dart:convert';
import 'dart:io';

import 'package:student_exam/common/http_util.dart';
import 'package:dio/dio.dart';

class LectureApi {
  static Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // 创建讲义
  static Future<dynamic> lectureCreate(Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = [
        'name',
        'sort',
      ];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      // 发送POST请求
      dynamic response = await HttpUtil.post('/admin/lecture/lecture', params: params);

      return response;
    } catch (e) {
      print('Error in createLecture: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 获取讲义列表
  static Future<dynamic> lectureList(Map<String, String?> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'page': params['page'] ?? '1', // 默认值为 '1'
        'pageSize': params['size'] ?? '15', // 重命名并设置默认值
        'keyword': handleNullOrEmpty(params['keyword']),
        'major_id': handleNullOrEmpty(params['major_id']),
        'job_code': handleNullOrEmpty(params['job_code']),
      };

      return await HttpUtil.get("/admin/lecture/lecture", params: finalParams);
    } catch (e) {
      print('Error in getLectureList: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 查看单个讲义
  static Future<dynamic> getLectureByID(int id) async {
    try {
      return await HttpUtil.get("/admin/lecture/lecture/$id");
    } catch (e) {
      print('Error in getLectureByID: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 更新讲义
  static Future<dynamic> lectureUpdate(int id, Map<String, dynamic> params) async {
    try {
      // 发送PUT请求
      dynamic response = await HttpUtil.put("/admin/lecture/lecture/$id", params: params);

      return response;
    } catch (e) {
      print('Error in updateLecture: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 删除讲义
  static Future<dynamic> lectureDelete(String id) async {
    try {
      return await HttpUtil.delete("/admin/lecture/lecture/$id");
    } catch (e) {
      print('Error in deleteLecture: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 获取讲义目录树
  static Future<dynamic> getLectureDirectoryTree(String id) async {
    try {
      return await HttpUtil.get("/admin/lecture/directory/$id");
    } catch (e) {
      print('Error in getLectureDirectoryTree: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 添加目录
  static Future<dynamic> addDirectory(String id, Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = [
        'parent_id',
        'name',
      ];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      // 发送POST请求
      dynamic response = await HttpUtil.post("/admin/lecture/directory/$id", params: params);

      return response;
    } catch (e) {
      print('Error in addDirectory: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> updateDirectory(String id, Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = [
        'name',
      ];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('Missing required field: $field');
        }
      }

      // 发送POST请求
      dynamic response = await HttpUtil.put("/admin/lecture/directory/$id", params: params);

      return response;
    } catch (e) {
      print('Error in updateDirectory: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 删除目录
  static Future<dynamic> deleteDirectory(String id) async {
    try {
      return await HttpUtil.delete("/admin/lecture/directory/$id");
    } catch (e) {
      print('Error in deleteDirectory: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 导入目录，要求文件为word或pdf
  static Future<dynamic> importFileToNode(int nodeId, File file) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      dynamic response = await HttpUtil.uploadFile("/admin/lecture/directory/file_import/$nodeId", formData);

      return response;
    } catch (e) {
      print('Error in importDirectory : $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

    static Future<dynamic> importFileToDir(int lectureId,int nodeId, File file) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      dynamic response = await HttpUtil.uploadFile("/admin/lecture/directory/dir_import/$lectureId/$nodeId", formData);

      return response;
    } catch (e) {
      print('Error in importDirectory : $e');
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
