import 'dart:typed_data';

import 'package:student_exam/ex/ex_hint.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/user_api.dart';
import '../../common/app_data.dart';
import '../home/view.dart';

class LoginLogic extends GetxController {
  var accountText = TextEditingController();
  var passwordText = TextEditingController();
  var captchaText = TextEditingController();
  var captchaImageUrl = ''.obs;
  var captchaId = ''.obs;
  final isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAccountInfo();
    fetchCaptcha();
  }

  Future<void> loadAccountInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedAccount = prefs.getString('account');
    if (savedAccount != null) {
      accountText.text = savedAccount;
    }
  }

  void saveAccountInfo(String account) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('account', account);
  }

  void fetchCaptcha() async {
    try {
      var data = await UserApi.captcha();
      if (data['captchaId'].isNotEmpty) {
        captchaId.value = data['captchaId'];
        captchaImageUrl.value = data['picPath'];
      } else {
        '获取验证码失败'.toHint();
      }
    } catch (e) {
      '网络异常，请重试'.toHint();
    }
  }

  void login() async {
    if (passwordText.text.isEmpty) {
      '密码不能为空'.toHint();
      return;
    }
    if (captchaText.text.isEmpty) {
      '验证码不能为空'.toHint();
      return;
    }

    try {
      var data = await UserApi.login({
        'password': passwordText.text,
        'captcha': captchaText.text,
        'captchaId': captchaId.value
      });

      if (data['token'].isNotEmpty) {
        await LoginData.easySave((dg) {
          dg.token = data['token'];
          dg.user = data['user']['userName'];
          dg.code = data['user']['phone'];
          dg.id = int.parse(data['user']['email']);
        });
        // 登录成功后保存账号信息
        saveAccountInfo(accountText.text);
        isLoggedIn.value = true;
        Get.off(() => HomePage());
      } else {
        captchaText.clear();
        fetchCaptcha();
        "登录失败".toHint();
      }
    } catch (e) {
      captchaText.clear();
      fetchCaptcha();
      "登录失败：${e.toString()}".toHint();
    }
  }

  void logout() {
    LoginData.easySave((p0) => {p0.token = "", p0.role = "", p0.user = ""});
    isLoggedIn.value = false;
  }

  Uint8List base64ToImage(String base64String) {
    return base64.decode(base64String.split(',').last);
  }
}
