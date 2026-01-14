import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../api/config_api.dart';

/// 用户手册Logic
class UserGuideLogic extends GetxController {
  // 加载状态
  final RxBool isLoading = true.obs;

  // 错误信息
  final RxString errorMessage = ''.obs;

  // 用户手册URL
  final RxString guideUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserGuide();
  }

  /// 加载用户手册配置
  Future<void> loadUserGuide() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final data = await ConfigApi.configUserGuide();

      if (data != null && data['user_guide'] != null) {
        guideUrl.value = data['user_guide'];
      } else {
        errorMessage.value = '未获取到用户手册链接';
      }
    } catch (e) {
      debugPrint('加载用户手册配置失败: $e');
      errorMessage.value = '加载用户手册配置失败';
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新
  @override
  void refresh() {
    loadUserGuide();
  }
}
