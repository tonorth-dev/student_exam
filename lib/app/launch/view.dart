import 'package:student_exam/ex/ex_hint.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/version_service.dart';
import '../../component/dialogs/update_dialog.dart';
import '../../models/version_info.dart';
import '../home/view.dart';  // 假设主页面在这个路径
import '../login/view.dart';
import '../../api/user_api.dart';
import 'package:bot_toast/bot_toast.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({Key? key}) : super(key: key);

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 先检查版本更新
    await _checkForUpdates();
    // 版本检查完成后，再进行 token 验证
    if (mounted) {
      await _validateToken();
    }
  }

  Future<void> _validateToken() async {
    try {
      // 调用远程验证接口
      await UserApi.userInfo();
      // 如果成功，进入主页
      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      "登录已过期，请重新登录".toHint();
      // 如果失败，进入登录页
      if (mounted) {
        Get.off(() => const LoginPage());
      }
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final versionService = VersionService();
      final VersionInfo? updateInfo = await versionService.checkForUpdates();
      if (updateInfo != null && mounted) {
        await _showUpdateDialog(updateInfo);
      }
    } catch (e) {
      debugPrint('版本检查失败: $e');
      // 版本检查失败时，显示错误提示
      if (mounted) {
        BotToast.showText(text: '版本检查失败，请稍后重试');
      }
    }
  }

  Future<void> _showUpdateDialog(VersionInfo updateInfo) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(versionInfo: updateInfo),
    );
  }

  void _navigateToHome() {
    if (!mounted) return;
    Get.off(() => HomePage());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            SizedBox(height: 24),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在启动...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
