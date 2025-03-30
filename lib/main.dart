import 'package:flutter_material_pickers/main.dart';
import 'package:student_exam/app/launch/view.dart';
import 'package:student_exam/common/app_data.dart';
import 'package:student_exam/state.dart';
import 'package:student_exam/theme/my_theme.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io' show Platform;
import 'common/screen_adapter.dart';

import 'common/config_util.dart';
import 'theme/light_theme.dart';

// 定义全局变量 theme 以便在 main 函数外也可以访问
late ThemeData theme;
// 定义全局的屏幕适配器实例
final screenAdapter = ScreenAdapter();

// 平台通道，用于获取屏幕尺寸
const MethodChannel _channel = MethodChannel('com.example.student_exam/screen_info');

// 获取屏幕尺寸的方法
Future<Size> getScreenSize() async {
  try {
    final Map<String, dynamic> result = await _channel.invokeMapMethod('getScreenSize') ?? {};
    final double width = result['width'] ?? 1920.0; // 默认值，避免空值
    final double height = result['height'] ?? 1080.0;
    print("通过平台通道获取的屏幕尺寸: ${width}x${height}");
    return Size(width, height);
  } catch (e) {
    print("获取屏幕尺寸出错，使用默认值: $e");
    // 使用硬编码的默认尺寸作为备选方案
    return const Size(1920.0, 1080.0);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var appData = await LoginData.read();
  var findTheme =
  themeList.firstWhereOrNull((e) => e.name() == appData.themeName);
  theme = findTheme?.theme() ?? Light().theme();

  await message.init();

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 初始化屏幕适配器 - 先获取屏幕尺寸
  Size screenSize;
  
  try {
    screenSize = await getScreenSize();
  } catch (e) {
    print("使用默认屏幕尺寸: $e");
    // 使用硬编码的默认尺寸
    screenSize = const Size(1920, 1080);
    print("使用默认屏幕尺寸: ${screenSize.width}x${screenSize.height}");
  }
  
  final suitableSize = screenAdapter.getSuitableSize(screenSize);
  screenAdapter.currentSize.value = suitableSize;
  
  print("应用初始化 - 实际屏幕尺寸: ${screenSize.width}x${screenSize.height}, 选择的尺寸: ${suitableSize.width}x${suitableSize.height} (${suitableSize.name})");

  // 根据适配的尺寸设置窗口大小
  // 窗口高度和宽度比例保持一致，但留出一定的边距
  // 确保窗口不会占满整个屏幕
  final double windowWidth = suitableSize.width;
  final double windowHeight = suitableSize.height;
  
  // 计算窗口的最大尺寸（屏幕尺寸的90%）
  final double maxWidth = screenSize.width * 0.9;
  final double maxHeight = screenSize.height * 0.9;
  
  // 限制窗口的尺寸不超过屏幕的90%
  final double actualWidth = windowWidth > maxWidth ? maxWidth : windowWidth;
  final double actualHeight = windowHeight > maxHeight ? maxHeight : windowHeight;
  
  // 侧边栏宽度约149，我们需要确保有足够的空间容纳内容区域
  const double sidebarWidth = 149.0;
  const double minContentWidth = 1441.0; // 内容区域最小宽度
  
  // 如果窗口宽度不足以容纳侧边栏加最小内容区域，则增加窗口宽度
  final double finalWidth = (actualWidth < (sidebarWidth + minContentWidth)) 
      ? (sidebarWidth + minContentWidth) 
      : actualWidth;
  
  print("设置窗口尺寸: ${finalWidth}x${actualHeight} (考虑侧边栏宽度: $sidebarWidth)");

  WindowOptions windowOptions = WindowOptions(
    size: Size(finalWidth, actualHeight),
    skipTaskbar: false,
    // 允许窗口大小最小为适配尺寸的一半，最大为屏幕尺寸
    minimumSize: Size(sidebarWidth + minContentWidth, actualHeight * 0.5),
    maximumSize: Size(screenSize.width, screenSize.height),
    windowButtonVisibility: true, // 显示窗口调整按钮，允许用户调整大小
    center: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  ConfigUtil.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      translations: message,
      defaultTransition: Transition.noTransition,
      builder: BotToastInit(),
      navigatorObservers: [BotToastNavigatorObserver()],
      title: 'Flutter Admin',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('zh'), // Chinese
      ],
      locale: const Locale('zh'),
      home: LaunchPage(),
    );
  }
}
