import 'package:student_exam/ex/ex_btn.dart';
import 'package:student_exam/ex/ex_int.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:student_exam/theme/ui_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    var style = const TextStyle(fontSize: 14, color: Colors.black87);
    final logic = Get.find<PaginationLogic>(tag: uniqueId);

    return Obx(() {
      if (logic.totalPage.value <= 1) {
        return SizedBox.shrink();
      }

      return SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: alignment,
          children: [
            ThemeUtil.width(),
            Container(
              width: 80,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.white70),
                borderRadius: BorderRadius.circular(5),
              ),
              child: TextButton(
                onPressed: logic.current.value > 1 ? logic.prev : null,
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled) ? Color(0xFFD43030) : Colors.white;
                    },
                  ),
                ),
                child: Text(
                  "上一页",
                  style: TextStyle(
                    color: logic.current.value > 1 ? Colors.white: Color(0xFFD43030),
                  ),
                ),
              ),
            ),
            ThemeUtil.width(),
            Container(
              width: 80,
              margin: EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: Colors.white70),
                borderRadius: BorderRadius.circular(5),
              ),
              child: TextButton(
                onPressed: logic.current.value < logic.totalPage.value ? logic.next : null,
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      return states.contains(MaterialState.disabled) ? Color(0xFFD43030) : Colors.white;
                    },
                  ),
                ),
                child: Text(
                  "下一页",
                  style: TextStyle(
                    color: logic.current.value < logic.totalPage.value ? Colors.white: Color(0xFFD43030),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
