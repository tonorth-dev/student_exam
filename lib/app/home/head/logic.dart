import 'package:hongshi_admin/app/login/logic.dart';
import 'package:hongshi_admin/app/login/view.dart';
import 'package:hongshi_admin/common/app_data.dart';
import 'package:hongshi_admin/ex/ex_anim.dart';
import 'package:hongshi_admin/ex/ex_btn.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:hongshi_admin/ex/ex_url.dart';
import 'package:hongshi_admin/theme/theme_util.dart';
import 'package:hongshi_admin/theme/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class HeadLogic extends GetxController {
  final loginLogic = Get.put(LoginLogic());

  void logout() {
    loginLogic.logout();
    Get.offAll(() => LoginPage());
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

  Widget head(){
    return Container(
      width: 200,
      decoration: UiTheme.decoration(),
      child: Column(
        children: [
          ThemeUtil.height(),
          "退出登录".toBtn(onTap: (){
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
