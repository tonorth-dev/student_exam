import 'package:flutter_material_pickers/main.dart';
import 'package:student_exam/app/launch/view.dart';
import 'package:student_exam/common/app_data.dart';
import 'package:student_exam/common/app_providers.dart';
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
// 全局的屏幕适配器实例现在从 AppProviders 获取
// final screenAdapter = ScreenAdapter();

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
    screenSize = const Size(1600, 900);
    print("使用默认屏幕尺寸: ${screenSize.width}x${screenSize.height}");
  }
  
  // 使用 AppProviders 初始化屏幕适配器
  await AppProviders.initialize(screenSize: screenSize);
  final screenAdapter = AppProviders.instance.screenAdapter;
  final suitableSize = screenAdapter.currentSize.value;
  
  print("应用初始化 - 实际屏幕尺寸: ${screenSize.width}x${screenSize.height}, 选择的尺寸: ${suitableSize.width}x${suitableSize.height} (${suitableSize.name})");
  
  // 设置窗口选项
  WindowOptions windowOptions = WindowOptions(
    size: Size(suitableSize.width, suitableSize.height),
    skipTaskbar: false,
    windowButtonVisibility: false, // 显示窗口调整按钮，允许用户调整大小
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
