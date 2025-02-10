import 'package:student_exam/app/login/logic.dart';
import 'package:student_exam/app/login/view.dart';
import 'package:student_exam/common/app_data.dart';
import 'package:student_exam/ex/ex_anim.dart';
import 'package:student_exam/ex/ex_btn.dart';
import 'package:student_exam/ex/ex_hint.dart';
import 'package:student_exam/ex/ex_url.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:student_exam/theme/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HeadLogic extends GetxController {
  final loginLogic = Get.put(LoginLogic());

  // 修改这里：声明一个私有变量来存储用户数据
  LoginData? _loginData;

  // 使用 onInit 方法在控制器初始化时加载数据
  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    // 添加监听器来监听登录状态变化
    ever(loginLogic.isLoggedIn, (_) => refreshUserData());
  }

  // 异步加载用户数据的方法
  Future<void> _loadUserData() async {
    try {
      _loginData = await LoginData.read();
    } catch (e) {
      debugPrint('Failed to load user data: $e');
      _loginData = null;
    }
  }

  // 修改刷新方法以确保立即更新
  void refreshUserData() async {
    await _loadUserData();
    update(); // 确保视图更新
  }

  void logout() {
    loginLogic.logout();
    Get.off(() => LoginPage());
  }

  void clickHeadImage() {
    showDialog(
        context: Get.context!,
        barrierColor: Colors.transparent,
        builder: (context) {
          return Stack(
            children: [
              Positioned(
                right: 10,
                top: 55,
                child: head(),
              ),
            ],
          );
        });
  }

  Widget head() {
    if (_loginData == null) {
      return CircularProgressIndicator(); // 加载中或无数据时显示进度条
    }

    final userName = _loginData!.user;
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white, // 设置背景色为白色
        // borderRadius:  BorderRadius.all(Radius.circular(2)),
      ),
      child: Column(
        children: [
          // 这里显示用户名
          ThemeUtil.height(),
          Text(
            "你好，$userName",
            style: TextStyle(
              color: Colors.black, // 设置字体颜色为黑色
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          ThemeUtil.height(),
          "退出登录".toBtn(onTap: () {
            logout();
          }),
          ThemeUtil.height(),
        ],
      ),
    ).toFadeInWithMoveX(true);
  }

  Widget itemBtn(Icon icon, String text, Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          icon,
        ],
      ),
    );
  }
}
