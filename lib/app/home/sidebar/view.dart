import 'package:student_exam/app/home/tab_bar/logic.dart';
import 'package:student_exam/ex/ex_anim.dart';
import 'package:student_exam/ex/ex_list.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:student_exam/theme/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../state.dart';
import 'logic.dart';

class SidebarPage extends StatelessWidget {
  SidebarPage({Key? key}) : super(key: key);

  final logic = Get.put(SidebarLogic());

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 50,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 50, maxWidth: 50),
            child: _default(),
          ),
        ),
        Positioned(
          top: 8,
          right: -24,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                sidebarExpanded.value = !sidebarExpanded.value;
                sidebarShow.value = false;
              },
              child: Container(
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
                  size: 20,
                  color: Theme.of(context).iconTheme.color,
                )),
              ),
            ),
          ),
        ),
      ],
    );
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

  static const double leftSpace = 12;

  Widget _text(SidebarTree item, {double left = leftSpace}) {
    return MouseRegion(
      onEnter: (event) => logic.animName.value = item.name,
      onExit: (event) => logic.animName.value = "",
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
            final bool expanded = sidebarExpanded.value;
            final bool selected = SidebarLogic.selectName.value == item.name;
            return Container(
              width: double.infinity,
              height: 50,
              decoration: ThemeUtil.boxDecoration(
                color: selected ? UiTheme.primary() : null,
                radius: 12,
              ),
              child: expanded
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: left),
                        Icon(
                          item.icon,
                          color: selected
                              ? UiTheme.getOnPrimary(selected)
                              : item.color,
                        ).toJump(logic.animName.value == item.name),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: UiTheme.getOnPrimary(selected),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.children.isNotEmpty) ...[
                          Icon(
                            Icons.arrow_drop_up,
                            color: UiTheme.getTextColor(selected),
                            size: 28,
                          ).toRotate(item.isExpanded.value),
                          const SizedBox(width: 8),
                        ],
                      ],
                    )
                  : Center(
                      child: Icon(
                        item.icon,
                        color: selected
                            ? UiTheme.getOnPrimary(selected)
                            : item.color,
                      ).toJump(logic.animName.value == item.name),
                    ),
            );
          }),
        ),
      ),
    );
  }

  Widget _tree(SidebarTree item, {double left = leftSpace}) {
    return Column(
      children: [
        _text(item, left: left),
        Obx(() {
          return Visibility(
              visible: item.isExpanded.value,
              child: Column(
                children: item.children.toWidgets((e) {
                  if (e.children.isNotEmpty) {
                    return _tree(e, left: left + leftSpace);
                  }
                  return _text(e, left: left + leftSpace);
                }),
              ));
        })
      ],
    );
  }
}
