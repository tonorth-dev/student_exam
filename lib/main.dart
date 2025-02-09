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

import 'common/config_util.dart';
import 'theme/light_theme.dart';

// 定义全局变量 theme 以便在 main 函数外也可以访问
late ThemeData theme;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var appData = await LoginData.read();
  var findTheme =
  themeList.firstWhereOrNull((e) => e.name() == appData.themeName);
  theme = findTheme?.theme() ?? Light().theme();

  await message.init();

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const initialHeight = 810.0;

  WindowOptions windowOptions = WindowOptions(
    size: const Size(1600, initialHeight),  // 初始包含侧边栏
    skipTaskbar: false,
    minimumSize: const Size(1451, 810),     // 收起状态宽度 (1441 + 10)
    maximumSize: const Size(1600, 810),     // 展开状态宽度 (149 + 10 + 1441)
    windowButtonVisibility: false,           // 隐藏窗口调整按钮
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
