import 'package:student_exam/app/home/head/logic.dart';
import 'package:student_exam/app/home/head/view.dart';
import 'package:student_exam/app/home/sidebar/logic.dart';
import 'package:student_exam/app/home/sidebar/view.dart';
import 'package:student_exam/app/home/tab_bar/view.dart';
import 'package:student_exam/component/watermark.dart';
import 'package:student_exam/ex/ex_anim.dart';
import 'package:student_exam/main.dart';
import 'package:student_exam/state.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final logic = Get.put(HomeLogic());

  static Widget sidebarPage = SidebarPage();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (appReload.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      return Stack(
        children: [
          body(),
          Positioned.fill(
            child: IgnorePointer(
              child: Obx(() {
                return Visibility(
                  visible: waterMark.value,
                  child: CustomPaint(
                    painter: WatermarkPainter(),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    });
  }

  Widget body() {
    return Scaffold(
      body: Row(
        children: [
          // 宽度扩大动画
          Obx(() {
            var show = sidebarShow.value;
            return Visibility(
              visible: show,
              child: sidebarPage,
            ).toAccordionX(
              sidebarExpanded.value,
              onEnd: () {
                sidebarShow.value = true;
              },
            );
          }),
          ThemeUtil.lineV(),
          Expanded(
            child: Column(
              children: [
                // HeadPage(),
                Expanded(child: TabBarPage()),
              ],
            ),
          )
        ],
      ),
    );
  }
}
