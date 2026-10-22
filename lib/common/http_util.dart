import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:student_exam/common/app_data.dart';
import 'package:student_exam/ex/ex_hint.dart';

import '../app/login/view.dart';
import 'biz_path.dart';
import 'config_util.dart';

class HttpUtil {
  static const authorization = "X-Token";
  static const appVersion = "X-App-Version";
  static const String _logTag = '[HttpUtil]';

  static final dio = Dio(BaseOptions(
    baseUrl: ConfigUtil.fullUrl,
    connectTimeout: const Duration(seconds: 40),
    receiveTimeout: const Duration(seconds: 40),
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        _logRequest(options);
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response);
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _logError(e);
        return handler.next(e);
      },
    ));

  static Future<dynamic> get(String url,
      {Map<String, dynamic>? params,
      bool showMsg = true,
      Duration? timeout}) async {
    url = await BizPath.apply(url);
    debugPrint('$_logTag 🔵 GET Request Starting');
    debugPrint('$_logTag 📍 URL: $url');
    debugPrint('$_logTag 📊 Params: ${params ?? "None"}');
    var map = await header();
    Response response = await dio.get(url,
        queryParameters: params,
        options: Options(
          headers: map,
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ));
    return await verify(response.data, showMsg);
  }

  static Future<dynamic> post(String url,
      {Map<String, dynamic>? params, bool showMsg = true}) async {
    url = await BizPath.apply(url);
    debugPrint('$_logTag 🟢 POST Request Starting');
    debugPrint('$_logTag 📍 URL: $url');
    debugPrint('$_logTag 📊 Body: ${params ?? "None"}');
    var map = await header();
    Response response = await dio.post(url,
        data: params,
        options: Options(contentType: Headers.jsonContentType, headers: map));
    return await verify(response.data, showMsg);
  }

  static Future<dynamic> put(String url,
      {Map<String, dynamic>? params, bool showMsg = true}) async {
    url = await BizPath.apply(url);
    debugPrint('$_logTag 🟡 PUT Request Starting');
    debugPrint('$_logTag 📍 URL: $url');
    var map = await header();
    Response response = await dio.put(url,
        data: params,
        options: Options(contentType: Headers.jsonContentType, headers: map));
    return await verify(response.data, showMsg);
  }

  static Future<dynamic> delete(String url,
      {Map<String, dynamic>? params, bool showMsg = true}) async {
    url = await BizPath.apply(url);
    debugPrint('$_logTag 🔴 DELETE Request Starting');
    debugPrint('$_logTag 📍 URL: $url');
    var map = await header();
    Response response = await dio.delete(url,
        queryParameters: params, options: Options(headers: map));
    return await verify(response.data, showMsg);
  }

  static Future<Map<String, dynamic>> header() async {
    var data = await LoginData.read();
    final token = data.token;
    final tokenPreview = token.isEmpty
        ? '(empty)'
        : (token.length <= 10 ? token : '${token.substring(0, 10)}...');
    debugPrint('$_logTag 🔐 Auth token: $tokenPreview');
    return {
      authorization: token,
      appVersion: ConfigUtil.appVersion,
    };
  }

  static Future<dynamic> uploadByte(String url, Uint8List file, String name,
      {bool showMsg = true,
      Function(int count, int total)? onSendProgress}) async {
    url = await BizPath.apply(url);
    debugPrint('$_logTag 📤 UploadByte Starting: $name');
    var map = await header();
    var formData = FormData.fromMap({
      "file": MultipartFile.fromBytes(file, filename: name),
    });
    Response response = await dio.post(url,
        data: formData,
        options: Options(headers: map),
        onSendProgress: onSendProgress);
    return await verify(response.data, showMsg);
  }

  static Future<dynamic> uploadFile(String url, FormData formData,
      {bool showMsg = true,
      Function(int count, int total)? onSendProgress}) async {
    url = await BizPath.apply(url);
    debugPrint('$_logTag 📤 UploadFile Starting');
    var map = await header();
    Response response = await dio.post(
      url,
      data: formData,
      options: Options(headers: map),
      onSendProgress: onSendProgress,
    );
    return await verify(response.data, showMsg);
  }

  static dynamic verify(dynamic data, bool showMsg) async {
    debugPrint('$_logTag 🔍 Verifying response data...');
    debugPrint('$_logTag 📈 Response Code: ${data["code"]}');
    debugPrint('$_logTag 💬 Response Message: ${data["msg"] ?? "No message"}');

    if (data["code"] == 10) {
      debugPrint('$_logTag 🚫 Token expired, code: ${data["code"]}');
      "登录已失效，需重新登录".toHint();
      LoginData.clear();
      await Future.delayed(Duration(milliseconds: 1000));
      Get.to(() => LoginPage());
      return Future.error("登录已失效，需重新登录");
    }
    if (data["code"] == 0) {
      debugPrint('$_logTag ✅ Request successful');
      return data["data"];
    } else {
      debugPrint('$_logTag ⚠️ API Error: ${data["msg"] ?? "Unknown error"}');
      if (showMsg) {
        data["msg"].toString().toHint();
      }
      return Future.error(data["msg"]);
    }
  }

  static void _logRequest(RequestOptions options) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('\n🔵 $_logTag HTTP Request [$timestamp]');
    debugPrint('├─ Method: ${options.method}');
    debugPrint('├─ URL: ${options.baseUrl}${options.path}');
    debugPrint('├─ Headers: ${options.headers}');
    debugPrint('├─ Query Parameters: ${options.queryParameters}');
    if (options.data != null) {
      if (options.data is FormData) {
        final formData = options.data as FormData;
        debugPrint(
            '├─ FormData Fields: ${formData.fields.map((e) => '${e.key}=${e.value}').join(', ')}');
      } else {
        final dataStr = options.data.toString();
        final truncatedData =
            dataStr.length > 1000 ? '${dataStr.substring(0, 1000)}...' : dataStr;
        debugPrint('├─ Request Data: $truncatedData');
      }
    }
    debugPrint('└─ End Request\n');
  }

  static void _logResponse(Response response) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('\n✅ $_logTag HTTP Response [$timestamp]');
    debugPrint('├─ Status Code: ${response.statusCode}');
    debugPrint(
        '├─ URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
    debugPrint('├─ Method: ${response.requestOptions.method}');
    if (response.data != null) {
      final dataStr = response.data.toString();
      final truncatedData =
          dataStr.length > 2000 ? '${dataStr.substring(0, 2000)}...' : dataStr;
      debugPrint('├─ Response Data: $truncatedData');
    }
    debugPrint('└─ End Response\n');
  }

  static void _logError(DioException e) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('\n❌ $_logTag HTTP Error [$timestamp]');
    debugPrint('├─ Error Type: ${e.type}');
    debugPrint('├─ Error Message: ${e.message}');
    debugPrint('├─ Status Code: ${e.response?.statusCode}');
    debugPrint(
        '├─ URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
    if (e.response?.data != null) {
      final dataStr = e.response!.data.toString();
      final truncatedData =
          dataStr.length > 1000 ? '${dataStr.substring(0, 1000)}...' : dataStr;
      debugPrint('├─ Error Response Data: $truncatedData');
    }
    debugPrint('└─ End Error\n');
  }
}
