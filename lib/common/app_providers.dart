import 'package:flutter/material.dart';
import 'screen_adapter.dart';

/// 全局提供者类，用于管理应用全局实例
/// 符合依赖注入和单一职责原则，避免从 main.dart 直接导入
class AppProviders {
  // 私有构造函数，确保单例
  AppProviders._();
  
  // 全局实例
  static final AppProviders instance = AppProviders._();
  
  // 屏幕适配器
  late final ScreenAdapter screenAdapter = ScreenAdapter();
  
  // 初始化方法，可以在应用启动时调用
  static Future<void> initialize({Size? screenSize}) async {
    if (screenSize != null) {
      final suitableSize = instance.screenAdapter.getSuitableSize(screenSize);
      instance.screenAdapter.currentSize.value = suitableSize;

      debugPrint("AppProviders - 屏幕适配初始化: 实际屏幕尺寸 ${screenSize.width}x${screenSize.height}");
      debugPrint("AppProviders - 选择的适配尺寸: ${suitableSize.width}x${suitableSize.height} (${suitableSize.name})");
    }
  }
} 