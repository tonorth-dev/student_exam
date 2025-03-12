import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:screen_retriever/screen_retriever.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 预设窗口尺寸
  const presetSizes = [
    Size(1024, 518),
    Size(1600, 810),
    Size(1920, 972),
  ];

  // 获取显示器信息
  final primaryDisplay = await screenRetriever.getPrimaryDisplay();
  final screenSize = Size(
    primaryDisplay.size.width,
    primaryDisplay.size.height,
  );
  
  print('显示器尺寸：${screenSize.width}*${screenSize.height}');
  
  // 选择最接近的预设尺寸
  Size closestSize = presetSizes.first;
  for (var size in presetSizes) {
    if ((size.width - screenSize.width).abs() <
        (closestSize.width - screenSize.width).abs()) {
      closestSize = size;
    }
  }

  // 设置窗口尺寸并居中
  await windowManager.setSize(closestSize);
  await windowManager.center();
  
  // 设置窗口标题和其他属性
  await windowManager.setTitle('学生考试系统');
  await windowManager.setMinimumSize(const Size(800, 600));
  
  print('使用窗口尺寸：${closestSize.width}*${closestSize.height}');

  // 运行应用
  runApp(MyApp(designSize: closestSize));
}

class MyApp extends StatelessWidget {
  final Size designSize;
  
  const MyApp({Key? key, required this.designSize}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // 使用ScreenUtilInit初始化，以便根据设计尺寸适配UI元素
    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '学生考试系统',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: Typography.englishLike2018.apply(fontSizeFactor: 1.sp),
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('自适应窗口示例', style: TextStyle(fontSize: 18.sp))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '窗口尺寸已根据屏幕分辨率适配',
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 20.h),
            Container(
              width: 200.w,
              height: 50.h,
              color: Colors.blue.shade100,
              alignment: Alignment.center,
              child: Text(
                '这是一个使用ScreenUtil适配的容器',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
