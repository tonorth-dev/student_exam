import 'package:hongshi_admin/ex/ex_btn.dart';
import 'package:hongshi_admin/ex/ex_int.dart';
import 'package:hongshi_admin/theme/theme_util.dart';
import 'package:hongshi_admin/theme/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';

class PaginationPage extends StatelessWidget {
  final MainAxisAlignment alignment;
  final String uniqueId;

  PaginationPage({
    super.key,
    this.alignment = MainAxisAlignment.end,
    required this.uniqueId,
    int total = 0,
    required Function(int size, int page) changed,
  }) {
    final logic = Get.put(PaginationLogic(), tag: uniqueId);
    logic.total = total;
    logic.changed = changed;
    // 初次延迟加载
    128.toDelay(() {
      logic.reload();
    });
  }

  final sizeList = [15, 20, 50, 100, 500];

  List<int?> _generatePageNumbers(int currentPage, int totalPage) {
    if (totalPage <= 6) {
      return List<int?>.generate(totalPage, (index) => index + 1);
    }

    List<int?> pages = [1];
    if (currentPage > 4) pages.add(null);

    int start = currentPage > 4 ? currentPage - 1 : 2;
    int end = currentPage < totalPage - 3 ? currentPage + 1 : totalPage - 1;

    for (int i = start; i <= end; i++) {
      pages.add(i);
    }

    if (currentPage < totalPage - 3) pages.add(null);
    pages.add(totalPage);

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    var style = const TextStyle(fontSize: 14, color: Colors.black87);
    final logic = Get.find<PaginationLogic>(tag: uniqueId);

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          ThemeUtil.width(),
          Text("共 ", style: style),
          Text("${logic.total}", style: TextStyle(
              color: Color(0xFFD43030),
              fontSize: 15
          )),
          Text(" 条记录", style: style),
          ThemeUtil.width(),
          Text("每页显示:", style: style),
          Obx(() {
            return Container(
              height: 34,
              decoration: BoxDecoration(
                color: Colors.grey[100], // 设置下拉框背景颜色
                borderRadius: BorderRadius.circular(5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: DropdownButton<int>(
                itemHeight: 48,
                items: sizeList.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text("$size"),
                  );
                }).toList(),
                onChanged: (value) {
                  logic.size.value = value!;
                  logic.current.value = 1;
                  logic.reload();
                },
                value: logic.size.value,
                style: style.copyWith(color: UiTheme.onBackground()),
                underline: Container(),
              ),
            );
          }),
          ThemeUtil.width(),
          Obx(() {
            return Container(
              width: 50,
              margin: EdgeInsets.symmetric(horizontal: 5), // 调整间距
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: TextButton(
                onPressed: logic.current.value > 1 ? logic.prev : null, // 禁用条件：第一页
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled) ? Colors.grey : Color(0xFFD43030);
                    },
                  ),
                ),
                child: Icon(Icons.arrow_left, color: logic.current.value > 1 ? Color(0xFFD43030) : Colors.grey),
              ),
            );
          }),
          ThemeUtil.width(),
          Obx(() {
            return Row(
              children: _generatePageNumbers(logic.current.value, logic.totalPage.value)
                  .map((page) {
                return page == null
                    ? Text("...", style: style)
                    : Container(
                  margin: EdgeInsets.symmetric(horizontal: 2), // 调整间距
                  width: 50,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                    color: page == logic.current.value ? Color(0xFFD43030) : Colors.white, // 动态设置背景颜色
                  ),
                  child: TextButton(
                    onPressed: () {
                      if (page != logic.current.value) {
                        logic.current.value = page;
                        logic.reload();
                      }
                    },
                    child: Text(
                      "$page",
                      style: TextStyle(
                        color: page == logic.current.value ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          ThemeUtil.width(),
          Obx(() {
            return Container(
              width: 50,
              margin: EdgeInsets.symmetric(horizontal: 5), // 调整间距
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: TextButton(
                onPressed: logic.current.value < logic.totalPage.value ? logic.next : null, // 禁用条件：最后一页
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled) ? Colors.grey : Color(0xFFD43030);
                    },
                  ),
                ),
                child: Icon(Icons.arrow_right, color: logic.current.value < logic.totalPage.value ? Color(0xFFD43030) : Colors.grey),
              ),
            );
          }),
        ],
      ),
    );
  }
}