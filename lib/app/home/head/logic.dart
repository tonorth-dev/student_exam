import 'package:student_exam/app/login/logic.dart';
import 'package:student_exam/app/login/view.dart';
import 'package:student_exam/common/app_data.dart';
import 'package:student_exam/common/biz_type.dart';
import 'package:student_exam/theme/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HeadLogic extends GetxController {
  final loginLogic = Get.put(LoginLogic(), permanent: true);

  // 修改这里：声明一个私有变量来存储用户数据
  LoginData? _loginData;

  // 使用 onInit 方法在控制器初始化时加载数据
  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    // 添加监听器来监听登录状态变化
    ever(loginLogic.isLoggedIn, (_) => refreshUserData());
  }

  // 异步加载用户数据的方法
  Future<void> _loadUserData() async {
    try {
      _loginData = await LoginData.read();
    } catch (e) {
      debugPrint('Failed to load user data: $e');
      _loginData = null;
    }
  }

  // 修改刷新方法以确保立即更新
  void refreshUserData() async {
    await _loadUserData();
    update(); // 确保视图更新
  }

  void logout() {
    loginLogic.logout();
    Get.offAll(() => LoginPage());
  }

  void clickHeadImage(BuildContext anchor) async {
    final box = anchor.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero);
    final anchorSize = box.size;
    await _loadUserData();
    if (!anchor.mounted) {
      return;
    }
    const menuWidth = 228.0;
    final screen = MediaQuery.sizeOf(anchor);
    var left = origin.dx + anchorSize.width - menuWidth;
    if (left < 8) {
      left = 8;
    }
    if (left + menuWidth > screen.width - 8) {
      left = screen.width - 8 - menuWidth;
    }
    final top = origin.dy + anchorSize.height + 6;
    showDialog(
      context: anchor,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: head(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget head() {
    final data = _loginData;
    if (data == null) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return _accountCard(
      name: data.user.isEmpty ? "学生" : data.user,
      role: "学生",
      bizType: data.bizType,
    );
  }

  Widget _accountCard({
    required String name,
    required String role,
    required int bizType,
  }) {
    final primary = UiTheme.primary();
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x330F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE6E8EE)),
      ),
      child: SizedBox(
        width: 228,
        child: DefaultTextStyle(
          style: const TextStyle(
            decoration: TextDecoration.none,
            color: Color(0xFF1F2430),
            height: 1.2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _nameRow(name, role, primary),
              _bizRow(bizType, primary),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEF0F5)),
              _logoutRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nameRow(String name, String role, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 11,
                color: primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bizRow(int bizType, Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          const Text(
            "所属业务系统",
            style: TextStyle(fontSize: 12, color: Color(0xFF8B90A0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              BizType.label(bizType),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoutRow() {
    return InkWell(
      onTap: logout,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          "退出登录",
          style: TextStyle(fontSize: 13, color: Color(0xFF3A4150)),
        ),
      ),
    );
  }

  Widget itemBtn(Icon icon, String text, Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          icon,
        ],
      ),
    );
  }
}
