import 'package:admin_flutter/theme/ui_theme.dart';
import 'package:flutter/material.dart';

import '../component/table/table_data.dart';

class ThemeUtil {
  /// 圆角
  static BoxDecoration boxDecoration(
      {Color? color, double radius = 6, Color? border}) {
    // 圆角
    return BoxDecoration(
      color: color,
      // 边框颜色
      border: border != null ? Border.all(color: border) : null,
      borderRadius: BorderRadius.all(Radius.circular(radius)),
    );
  }

  /// 行高
  static SizedBox height({double? height = 12}) {
    return SizedBox(
      height: height,
    );
  }

  /// 行宽
  static SizedBox width({double? width = 12}) {
    return SizedBox(
      width: width,
    );
  }

  /// 水平线
  static Widget lineH({double height = 1}) {
    return Divider(
      height: height,
      color: UiTheme.border(),
    );
  }

  /// 垂直线
  static Widget lineV({double width = 1}) {
    return VerticalDivider(
      width: width,
      color: UiTheme.border(),
    );
  }

  static TableTheme getDefaultTheme() {
    return TableTheme(
      border: Border.all(color: UiTheme.primary(), width: 1),
      headerColor: UiTheme.primary().withOpacity(0.8), // 添加 headerColor
      headerTextColor: Colors.white, // 添加 headerTextColor
      rowColor: UiTheme.primary().withOpacity(0.2), // 添加 rowColor
      textColor: UiTheme.primary(), // 添加 textColor
      alternateRowColor: UiTheme.primary().withOpacity(0.1), // 添加 alternateRowColor
    );
  }

  static TableTheme getDarkTheme() {
    return TableTheme(
      border: Border.all(color: Colors.grey.shade300, width: 1), // 边框颜色为浅灰色
      headerColor: Colors.blue.shade700, // 表头背景色为深蓝色
      headerTextColor: Colors.white, // 表头文字颜色为白色
      rowColor: Colors.white, // 偶数行背景色为白色
      textColor: Colors.black, // 表格文字颜色为黑色
      alternateRowColor: Colors.grey.shade100, // 奇数行背景色为非常浅的灰色
    );
  }
}
