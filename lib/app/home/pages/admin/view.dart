import 'package:hongshi_admin/app/home/sidebar/logic.dart';
import 'package:hongshi_admin/component/pagination/view.dart';
import 'package:hongshi_admin/component/table/ex.dart';
import 'package:hongshi_admin/component/table/table_data.dart';
import 'package:hongshi_admin/component/table/view.dart';
import 'package:hongshi_admin/theme/theme_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';

class AdminPage extends StatelessWidget {
  AdminPage({Key? key}) : super(key: key);

  final logic = Get.put(AdminLogic());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableEx.actions(
          children: [
            ThemeUtil.width(),
            const Text(
              "运行mock目录下的服务器体验",
              style: TextStyle(fontSize: 18),
            ),
            const Spacer(),
            FilledButton(
                onPressed: () {
                  logic.add();
                },
                child: const Text("新增")),
            ThemeUtil.width(),
          ],
        ),
        ThemeUtil.lineH(),
        Expanded(
          child: Obx(() {
            return TablePage(
              loading: logic.loading.value,
              tableData: TableData(
                  isIndex: true,
                  columns: logic.columns,
                  rows: logic.list.toList(),
                  theme: ThemeUtil.getDefaultTheme()),
            );
          }),
        ),
        Obx(() {
          return PaginationPage(
            uniqueId: 'admin_pagination',
            total: logic.total.value,
            changed: (size, page) {
              logic.find(size, page);
            },
          );
        })
      ],
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "管理列表",
      icon: Icons.app_registration_outlined,
      page: AdminPage(),
    );
  }
}
