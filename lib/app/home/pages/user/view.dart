import 'package:hongshi_admin/app/home/sidebar/logic.dart';
import 'package:hongshi_admin/component/pagination/view.dart';
import 'package:hongshi_admin/component/table/ex.dart';
import 'package:hongshi_admin/component/table/table_data.dart';
import 'package:hongshi_admin/component/table/view.dart';
import 'package:hongshi_admin/ex/ex_btn.dart';
import 'package:hongshi_admin/state.dart';
import 'package:hongshi_admin/theme/theme_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../state.dart';
import '../../../../state.dart';
import 'logic.dart';

class UserPage extends StatelessWidget {
  UserPage({Key? key}) : super(key: key);

  final logic = Get.put(UserLogic());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableEx.actions(
          children: [
            SizedBox(
              width: 150,
              child: TableEx.input(tip: "搜索姓名", onChanged: logic.nameChanged),
            ),
            ThemeUtil.width(),
            Obx(() {
              return SegmentedButton(
                selected: logic.sexSel.toSet(),
                emptySelectionAllowed: true,
                segments: const [
                  ButtonSegment(label: Text("男"), value: 1),
                  ButtonSegment(label: Text("女"), value: 0),
                ],
                onSelectionChanged: (e) {
                  logic.sexSel.clear();
                  logic.sexSel.addAll(e);
                  logic.find();
                },
              );
            }),
            ThemeUtil.width(),
            "选择城市".toBtn(onTap: logic.selectCity),
            ThemeUtil.width(),
            "多选删除".toBtn(onTap: logic.deleteSel),
            ThemeUtil.width(),
            "新增".toBtn(onTap: logic.add),
            ThemeUtil.width(),
          ],
        ),
        ThemeUtil.lineH(),
        Expanded(
          child: Obx(() {
            return TablePage(
              tableData: TableData(
                  theme: ThemeUtil.getDefaultTheme(),
                  isIndex: true,
                  columns: logic.columns,
                  rows: logic.list.toList()),
            );
          }),
        ),
        Obx(() {
          return PaginationPage(
            uniqueId: 'user_pagination',
            total: logic.total.value,
            changed: (size, page) {
              logic.size = size;
              logic.page = page;
              logic.find();
            },
          );
        })
      ],
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(name: "用户列表", icon: Icons.person, page: UserPage());
  }
}
