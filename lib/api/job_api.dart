import 'dart:io';
import 'package:hongshi_admin/common/http_util.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';

class JobApi {

  static Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // 获取题目列表
  static Future<dynamic> jobList(Map<String, String?> params) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'page': params['page'] ?? '1', // 默认值为 '1'
        'pageSize': params['size'] ?? '15', // 重命名并设置默认值
        'keyword': handleNullOrEmpty(params['keyword']),
        'cate': handleNullOrEmpty(params['cate']),
        'level': handleNullOrEmpty(params['level']),
        'status': handleNullOrEmpty(params['status']),
        'major_id': handleNullOrEmpty(params['major_id']),
        'all': handleNullOrEmpty(params['all']),
      };

      return await HttpUtil.get("/admin/job/job/list", params: finalParams);
    } catch (e) {
      print('获取题目列表时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static String handleNullOrEmpty(String? value) {
    if (value == null || value == 'null') {
      return '';
    }
    return value;
  }

  // 创建岗位
  static Future<dynamic> jobCreate(Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = [
        'code',
        'name',
        'desc',
        'cate',
        'company_code',
        'company_name',
        'enrollment_num',
        'enrollment_ratio',
      ];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('缺少必填字段: $field');
        }
      }

      return await HttpUtil.post("/admin/job/job", params: params);
    } catch (e) {
      print('创建岗位时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 查看题目详细
  static Future<dynamic> jobDetail(String id) async {
    try {
      return await HttpUtil.get("/admin/job/job/$id");
    } catch (e) {
      print('查看题目详情时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }
  static Future<dynamic> jobDetailByCode(String code) async {
    try {
      // 构建最终参数，并确保 null 值替换为 ''
      final Map<String, String> finalParams = {
        'code': code,
      };

      return await HttpUtil.get("/admin/job/job/list", params: finalParams);
    } catch (e) {
      print('获取题目列表时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 更新题目
  static Future<dynamic> jobUpdate(int id, Map<String, dynamic> params) async {
    try {
      // 必传字段校验
      List<String> requiredFields = [
        'code',
        'name',
        'desc',
        'cate',
        'company_code',
        'company_name',
        'enrollment_num',
        'enrollment_ratio',
      ];
      for (var field in requiredFields) {
        if (!params.containsKey(field) || params[field] == null) {
          throw ArgumentError('缺少必填字段: $field');
        }
      }

      return await HttpUtil.put("/admin/job/job/$id", params: params);
    } catch (e) {
      print('更新题目时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> jobUpdateMajor(List<int> jobIds, int majorId) async {
    try {
      // 必传字段校验
      if (jobIds == null || jobIds.isEmpty) {
        throw ArgumentError('缺少必填字段: job_ids');
      }
      if (majorId == null) {
        throw ArgumentError('缺少必填字段: major_id');
      }

      Map<String, dynamic> params = {
        'job_ids': jobIds,
        'major_id': majorId,
      };

      return await HttpUtil.post("/admin/job/job/update-major", params: params);
    } catch (e) {
      print('更新岗位专业时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 删除题目
  static Future<dynamic> jobDelete(String id) async {
    try {
      return await HttpUtil.delete("/admin/job/job/$id");
    } catch (e) {
      print('删除题目时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 导入题目
  static Future<dynamic> jobBatchImport(File file) async {
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
      return await HttpUtil.uploadFile("/admin/job/job/batch-import", formData, showMsg: false);
    } catch (e) {
      print('调用导入接口时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  // 导出题目为 CSV
  static Future<dynamic> jobExport({
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
      return await HttpUtil.get("/admin/job/job/export", params: params);
    } catch (e) {
      print('导出题目时发生错误: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }

  static Future<dynamic> auditJob(int jobId, int status) async {
    try {
      return await HttpUtil.put('/admin/job/job/$jobId/audit_ret/$status');
    } catch (e) {
      throw Exception('审核请求失败: $e');
    }
  }
}
