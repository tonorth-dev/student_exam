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

  const initialWidth = 1600.0; // 初始宽度
  const initialHeight = 810.0; // 初始高度

  WindowOptions windowOptions = WindowOptions(
    size: const Size(initialWidth, initialHeight),
    skipTaskbar: false,
    minimumSize: const Size(initialWidth, 810), // 设置最小高度，宽度与初始宽度相同
    maximumSize: const Size(initialWidth, double.infinity), // 设置最大高度，宽度与初始宽度相同
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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
