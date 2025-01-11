import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LoginData {
  String token = "";
  String themeName = "";
  String role = "";
  String user = "";
  DateTime? expiryDate;

  // toJson
  String toJson() {
    return jsonEncode({
      "token": token,
      "user": user,
      "themeName": themeName,
      "expiryDate": expiryDate != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(expiryDate!) : null,
    });
  }

  // fromJson
  static LoginData fromJson(Map<String, dynamic> map) {
    var data = LoginData();
    data.token = map["token"] ?? "";
    data.themeName = map["themeName"] ?? "";
    data.user = map["user"] ?? "";
    if (map["expiryDate"] != null) {
      data.expiryDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse(map["expiryDate"]);
    }
    return data;
  }

  static String saveKey = "app_data";

  static Future<LoginData> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(saveKey);
    print("Data from SharedPreferences: $data"); // Add this line for debugging
    if (data == null || !await _isDataValid(data)) {
      print("Data is null or invalid"); // Additional debug info
      return LoginData();
    }
    try {
      return LoginData.fromJson(jsonDecode(data));
    } catch (e) {
      print("Error decoding JSON: $e"); // Log any JSON decoding errors
      return LoginData();
    }
  }

  // 检查数据是否有效（未过期）
  static Future<bool> _isDataValid(String jsonData) async {
    Map<String, dynamic> map = jsonDecode(jsonData);
    LoginData loginData = LoginData.fromJson(map);

    if (loginData.expiryDate == null) {
      return false;
    }

    final now = DateTime.now();
    return loginData.expiryDate!.isAfter(now);
  }

  // 设置过期时间为一天后
  void setExpiryToTomorrow() {
    expiryDate = DateTime.now().add(Duration(days: 7));
  }

  // 保存数据
  Future<void> save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(saveKey, toJson());
  }

  /// 更简单的数据保存
  static Future<void> easySave(Function(LoginData) dg) async {
    var data = await read();
    dg(data);
    // 确保每次保存前都设置新的过期时间
    data.setExpiryToTomorrow();
    await data.save();
  }

  // 新增 clear 方法：清除保存的数据
  static Future<void> clear() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(saveKey);  // 删除保存的登录数据
    print("Login data cleared.");
  }
}
