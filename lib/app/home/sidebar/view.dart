import 'package:student_exam/app/home/tab_bar/logic.dart';
import 'package:student_exam/ex/ex_anim.dart';
import 'package:student_exam/ex/ex_list.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:student_exam/theme/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_exam/common/app_providers.dart';

import 'logic.dart';

class SidebarPage extends StatelessWidget {
  SidebarPage({Key? key}) : super(key: key);

  final logic = Get.put(SidebarLogic());

  @override
  Widget build(BuildContext context) {
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    return SizedBox(
        width: screenAdapter.getAdaptiveWidth(50),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: screenAdapter.getAdaptiveWidth(50), 
            maxWidth: screenAdapter.getAdaptiveWidth(50)
          ),
          child: _default(),
        ));
  }

  Widget _default() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        var item = SidebarLogic.treeList[index];
        return item.children.isNotEmpty ? _tree(item) : _text(item);
      },
      itemCount: SidebarLogic.treeList.length,
    );
  }

  // 左侧间距转为动态值
  static double getLeftSpace() {
    final screenAdapter = AppProviders.instance.screenAdapter;
    return screenAdapter.getAdaptivePadding(12);
  }

  Widget _text(SidebarTree item, {double? left}) {
    final screenAdapter = AppProviders.instance.screenAdapter;
    final leftPadding = left ?? getLeftSpace();
    
    return MouseRegion(
      // 鼠标悬停
      onEnter: (event) {
        logic.animName.value = item.name;
      },
      onExit: (event) {
        logic.animName.value = "";
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenAdapter.getAdaptivePadding(8), 
          vertical: screenAdapter.getAdaptivePadding(4)
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(12)),
          onTap: () {
            if (item.children.isNotEmpty) {
              item.isExpanded.value = !item.isExpanded.value;
              SidebarLogic.selSidebarTree(item);
              return;
            }
            SidebarLogic.selectName.value = item.name;
            SidebarLogic.selSidebarTree(item);
            TabBarLogic.addPage(item);
          },
          child: Obx(() {
            var selected = SidebarLogic.selectName.value == item.name;
            return Container(
                width: double.infinity,
                decoration: ThemeUtil.boxDecoration(
                    color: selected ? UiTheme.primary() : null, radius: 12),
                height: screenAdapter.getAdaptiveHeight(50),
                child: Row(
                  children: [
                    SizedBox(width: leftPadding),
                    Icon(
                      item.icon,
                      size: screenAdapter.getAdaptiveIconSize(24),
                      color: selected
                          ? UiTheme.getOnPrimary(selected)
                          : item.color,
                    ).toJump(logic.animName.value == item.name),
                    ThemeUtil.width(),
                    Text(
                      item.name,
                      style: TextStyle(
                        color: UiTheme.getOnPrimary(selected),
                        fontSize: screenAdapter.getAdaptiveFontSize(14),
                        fontWeight: FontWeight.w600
                      ),
                    ),
                    const Spacer(),
                    // 下拉箭头
                    Visibility(
                      visible: item.children.isNotEmpty,
                      child: Icon(
                        Icons.arrow_drop_up,
                        color: UiTheme.getTextColor(selected),
                        size: screenAdapter.getAdaptiveIconSize(28),
                      ).toRotate(item.isExpanded.value),
                    ),
                    ThemeUtil.width(),
                  ],
                ));
          }),
        ),
      ),
    );
  }

  Widget _tree(SidebarTree item, {double? left}) {
    final leftPadding = left ?? getLeftSpace();
    
    return Column(
      children: [
        _text(item, left: leftPadding),
        Obx(() {
          return Visibility(
              visible: item.isExpanded.value,
              child: Column(
                children: item.children.toWidgets((e) {
                  if (e.children.isNotEmpty) {
                    return _tree(e, left: leftPadding + getLeftSpace());
                  }
                  return _text(e, left: leftPadding + getLeftSpace());
                }),
              ));
        })
      ],
    );
  }
}
