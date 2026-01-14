import 'package:student_exam/app/home/pages/empty/view.dart';
import 'package:student_exam/app/home/pages/note/view.dart';
import 'package:student_exam/ex/ex_int.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/psyc/view.dart';
import '../pages/lecture/view.dart';
import '../pages/subject_bank/self_research/view.dart';
import '../pages/subject_bank/ai_subject/view.dart';
import '../pages/settings/view.dart';
import '../pages/exam/view.dart';
import '../pages/user_guide/view.dart';

class SidebarLogic extends GetxController {
  static var selectName = "".obs;
  var animName = "".obs;
  var expansionTile = <String>[].obs;

  /// 面包屑列表
  static var breadcrumbList = <SidebarTree>[].obs;

  static List<SidebarTree> treeList = [
    SidebarTree(
      name: "面试模拟",
      icon: Icons.person_outline, // Apply color here
      color: Colors.orange[300], // Set desired color
      page: ExamPage(),
    ),
    SidebarTree(
      name: "讲义学习",
      icon: Icons.menu_book_outlined, // Apply color here
      color: Colors.green[400], // Set desired color
      page: LecturePage(),
    ),
    SidebarTree(
      name: "题本学习",
      icon: Icons.app_registration_outlined, // Apply color here
      color: Colors.blue[400], // Set desired color
      page: NotePage(),
    ),
    SidebarTree(
      name: "专业题库",
      icon: Icons.library_books,
      color: Colors.blue[700],
      page: SelfResearchPage(),
    ),
    SidebarTree(
      name: "红师AI题库",
      icon: Icons.smart_toy,
      color: Colors.purple[400],
      page: AISubjectPage(),
    ),
    SidebarTree(
      name: "心理测试",
      icon: Icons.psychology_outlined,
      color: Colors.purple[400],
      page: PsychologyPage(),
    ),
    SidebarTree(
      name: "设置",
      icon: Icons.settings_outlined,
      color: Colors.grey[600],
      page: SettingsPage(),
    ),
    SidebarTree(
      name: "用户手册",
      icon: Icons.menu_book,
      color: Colors.blue[600],
      page: UserGuidePage(),
    )
  ];

  /// 面包屑和侧边栏联动
  static void selSidebarTree(SidebarTree sel) {
    if (breadcrumbList.isNotEmpty && breadcrumbList.last.name == sel.name) {
      return;
    }
    breadcrumbList.clear();
    32.toDelay(() {
      findSidebarTree(sel, treeList);
    });
  }

  /// 递归查找面包屑
  static bool findSidebarTree(SidebarTree sel, List<SidebarTree> list) {
    for (var item in list) {
      if (item.name == sel.name) {
        breadcrumbList.add(item);
        return true;
      }
      if (item.children.isNotEmpty) {
        /// 递归查找，当找到时，将当前节点插入到面包屑列表中，并返回true
        if (findSidebarTree(sel, item.children)) {
          breadcrumbList.insert(0, item);
          return true;
        }
      }
    }
    return false;
  }
}

class SidebarTree {
  final String name;
  final IconData icon;
  final List<SidebarTree> children;
  var isExpanded = false.obs;
  final Widget page;
  final Color color; // 正确添加 color 属性

  SidebarTree({
    required this.name,
    this.icon = Icons.ac_unit,
    this.children = const [],
    this.page = const EmptyPage(),
    Color? color, // 修改为可选参数
  }) : color = color ?? Colors.black; // 使用 ?? 运算符提供默认颜色
}

SidebarTree newThis(String name) {
  return SidebarTree(
    name: name,
    icon: Icons.supervised_user_circle,
    color: Colors.grey[600], // Set default color (optional)
  );
}
