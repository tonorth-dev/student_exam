import 'package:student_exam/app/home/sidebar/view.dart';
import 'package:student_exam/app/home/tab_bar/view.dart';
import 'package:student_exam/component/watermark.dart';
import 'package:student_exam/ex/ex_anim.dart';
import 'package:student_exam/state.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import '../../common/app_providers.dart';
import 'logic.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final logic = Get.put(HomeLogic());
  // 使用 AppProviders 获取 screenAdapter
  final screenAdapter = AppProviders.instance.screenAdapter;

  static Widget sidebarPage = SidebarPage();
  // 定义基础尺寸常量
  static const double SIDEBAR_WIDTH = 149;     // 侧边栏宽度
  static const double TOGGLE_BUTTON_WIDTH = 10; // 收缩按钮宽度
  static const double MAIN_WIDTH = 1440;       // 主内容区域宽度 (1600 - 149 - 10 -1)

  void _toggleSidebar() async {
    sidebarExpanded.value = !sidebarExpanded.value;
    sidebarShow.value = false;
    // 根据侧边栏状态调整窗口大小
    final adaptedSidebarWidth = screenAdapter.getAdaptiveWidth(SIDEBAR_WIDTH);
    final adaptedToggleWidth = screenAdapter.getAdaptiveWidth(TOGGLE_BUTTON_WIDTH);
    final adaptedMainWidth = screenAdapter.getAdaptiveWidth(MAIN_WIDTH);
    
    final newWidth = sidebarExpanded.value ? 
      screenAdapter.getAdaptiveWidth(1600.0) :  // 展开状态总宽度
      (adaptedMainWidth + adaptedToggleWidth + screenAdapter.getAdaptiveWidth(5.0));  // 收起状态总宽度
    
    final newHeight = screenAdapter.getAdaptiveHeight(810.0);
    await windowManager.setSize(Size(newWidth, newHeight));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (appReload.value) {
        return Scaffold(
          body: Center(
            child: SizedBox(
              width: screenAdapter.getAdaptiveWidth(24),
              height: screenAdapter.getAdaptiveHeight(24),
              child: CircularProgressIndicator(
                strokeWidth: screenAdapter.getAdaptiveWidth(2.0),
              ),
            ),
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
              width: screenAdapter.getAdaptiveWidth(144),
              sidebarExpanded.value,
              onEnd: () {
                sidebarShow.value = true;
              },
            );
          }),
          Container(
            margin: EdgeInsets.symmetric(
              vertical: screenAdapter.getAdaptivePadding(8),
            ),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  screenAdapter.getAdaptiveWidth(12),
                ),
                onTap: _toggleSidebar,
                child: Container(
                  height: screenAdapter.getAdaptiveHeight(100),
                  padding: EdgeInsets.all(
                    screenAdapter.getAdaptivePadding(2),
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      screenAdapter.getAdaptiveWidth(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: screenAdapter.getAdaptiveWidth(4),
                        offset: Offset(
                          0, 
                          screenAdapter.getAdaptiveHeight(2)
                        ),
                      ),
                    ],
                  ),
                  child: Obx(() => Icon(
                    sidebarExpanded.value
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: screenAdapter.getAdaptiveIconSize(10),
                    color: Theme.of(context).iconTheme.color,
                  )),
                ),
              ),
            ),
          ),
          ThemeUtil.lineV(
            width: screenAdapter.getAdaptiveWidth(1),
          ),
          Container(
            width: screenAdapter.getAdaptiveWidth(MAIN_WIDTH),
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