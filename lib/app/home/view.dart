import 'package:student_exam/app/home/sidebar/view.dart';
import 'package:student_exam/app/home/tab_bar/view.dart';
import 'package:student_exam/component/watermark.dart';
import 'package:student_exam/ex/ex_anim.dart';
import 'package:student_exam/state.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import 'logic.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final logic = Get.put(HomeLogic());

  static Widget sidebarPage = SidebarPage();
  static const double SIDEBAR_WIDTH = 149;     // 侧边栏宽度
  static const double TOGGLE_BUTTON_WIDTH = 10; // 收缩按钮宽度
  static const double MAIN_WIDTH = 1440;       // 主内容区域宽度 (1600 - 149 - 10 -1)

  void _toggleSidebar() async {
    sidebarExpanded.value = !sidebarExpanded.value;
    sidebarShow.value = false;
    // 根据侧边栏状态调整窗口大小
    final newWidth = sidebarExpanded.value ? 
      1600.0 :  // 展开状态总宽度
      (MAIN_WIDTH + TOGGLE_BUTTON_WIDTH + 5).toDouble();  // 收起状态总宽度 (1441 + 10)
    await windowManager.setSize(Size(newWidth, 810.0));
  }

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
                  child: const WatermarkWidget(),
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _toggleSidebar,
                child: Container(
                  height: 100,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Obx(() => Icon(
                    sidebarExpanded.value
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: 10,
                    color: Theme.of(context).iconTheme.color,
                  )),
                ),
              ),
            ),
          ),
          ThemeUtil.lineV(),
          Container(
            width: MAIN_WIDTH,
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