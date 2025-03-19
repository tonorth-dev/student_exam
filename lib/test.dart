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
    Size(819, 414),   // 1024*0.8 ≈ 819, 518*0.8 ≈ 414
    Size(1280, 648),  // 1600*0.8 = 1280, 810*0.8 = 648
    Size(1536, 778)   // 1920*0.8 = 1536, 972*0.8 ≈ 778
  ];

  // 获取显示器信息
  final primaryDisplay = await screenRetriever.getPrimaryDisplay();
  final scaleFactor = primaryDisplay.scaleFactor ?? 1.0;
  final logicalSize = Size(
    primaryDisplay.size.width / scaleFactor,
    primaryDisplay.size.height / scaleFactor,
  );

  print('显示器物理尺寸：${primaryDisplay.size.width}*${primaryDisplay.size.height}');
  print('显示器缩放因子：$scaleFactor');
  print('显示器逻辑尺寸：${logicalSize.width}*${logicalSize.height}');
  
  // 选择宽度小于当前屏幕尺寸且最接近的预设尺寸
  Size? closestSize;
  double minDifference = double.infinity;
  
  // 按宽度从大到小排序预设尺寸
  final sortedSizes = List<Size>.from(presetSizes)
    ..sort((a, b) => b.width.compareTo(a.width));
  
  // 找出宽度严格小于屏幕且差距最小的尺寸
  for (var size in sortedSizes) {
    if (size.width < logicalSize.width) {  // 使用严格小于，而不是小于等于
      double difference = logicalSize.width - size.width;
      if (difference < minDifference) {
        minDifference = difference;
        closestSize = size;
      }
    }
  }
  
  // 如果没有找到合适的尺寸（所有预设尺寸都大于等于屏幕尺寸），则使用最小的预设尺寸
  closestSize ??= sortedSizes.last;
  
  // 打印选择过程的详细信息
  print('预设尺寸列表: ${sortedSizes.map((s) => '${s.width}×${s.height}').join(', ')}');
  print('选择的尺寸: ${closestSize.width}×${closestSize.height} (差距: ${logicalSize.width - closestSize.width})');

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
          home: const ResponsiveDemo(),
        );
      },
    );
  }
}

class ResponsiveDemo extends StatelessWidget {
  const ResponsiveDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 获取当前设计尺寸
    final designWidth = 1.sw / (1.sw / 100) * 100;
    final designHeight = 1.sh / (1.sh / 100) * 100;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('ScreenUtil 响应式布局示例', style: TextStyle(fontSize: 18.sp)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: Text(
                '当前设计尺寸: ${designWidth.toInt()}×${designHeight.toInt()}',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                '文本大小适配 (.sp)',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('小号文本 - 12.sp', style: TextStyle(fontSize: 12.sp)),
                    Text('正常文本 - 14.sp', style: TextStyle(fontSize: 14.sp)),
                    Text('中等文本 - 16.sp', style: TextStyle(fontSize: 16.sp)),
                    Text('大号文本 - 18.sp', style: TextStyle(fontSize: 18.sp)),
                    Text('标题文本 - 24.sp', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              
              _buildSection(
                '宽度适配 (.w)',
                Column(
                  children: [
                    _buildWidthBox(100.w, '100.w'),
                    SizedBox(height: 8.h),
                    _buildWidthBox(200.w, '200.w'),
                    SizedBox(height: 8.h),
                    _buildWidthBox(300.w, '300.w'),
                  ],
                ),
              ),
              
              _buildSection(
                '高度适配 (.h)',
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildHeightBox(50.h, '50.h'),
                    _buildHeightBox(80.h, '80.h'),
                    _buildHeightBox(120.h, '120.h'),
                  ],
                ),
              ),
              
              _buildSection(
                '半径适配 (.r)',
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRadiusBox(10.r, '10.r'),
                    _buildRadiusBox(20.r, '20.r'),
                    _buildRadiusBox(40.r, '40.r'),
                  ],
                ),
              ),
              
              _buildSection(
                '内边距适配 (EdgeInsets.all(x.r))',
                Container(
                  color: Colors.blue.shade50,
                  width: double.infinity,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        color: Colors.blue.shade100,
                        child: Text('内边距 8.r', style: TextStyle(fontSize: 14.sp)),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(16.r),
                        color: Colors.blue.shade200,
                        child: Text('内边距 16.r', style: TextStyle(fontSize: 14.sp)),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(24.r),
                        color: Colors.blue.shade300,
                        child: Text('内边距 24.r', style: TextStyle(fontSize: 14.sp)),
                      ),
                    ],
                  ),
                ),
              ),
              
              _buildSection(
                '响应式布局示例',
                _buildResponsiveLayout(),
              ),
              
              _buildSection(
                '设备信息',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('设计尺寸: ${designWidth.toInt()}×${designHeight.toInt()}', 
                        style: TextStyle(fontSize: 14.sp)),
                    Text('屏幕宽度: ${1.sw.toStringAsFixed(2)}px', 
                        style: TextStyle(fontSize: 14.sp)),
                    Text('屏幕高度: ${1.sh.toStringAsFixed(2)}px', 
                        style: TextStyle(fontSize: 14.sp)),
                    Text('状态栏高度: ${MediaQuery.of(context).padding.top.toStringAsFixed(2)}px', 
                        style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, Widget content) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.r)),
            ),
            child: Text(
              title,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16.h),
          content,
        ],
      ),
    );
  }
  
  Widget _buildWidthBox(double width, String label) {
    return Container(
      width: width,
      height: 40.h,
      color: Colors.blue.shade300,
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
    );
  }
  
  Widget _buildHeightBox(double height, String label) {
    return Container(
      width: 80.w,
      height: height,
      color: Colors.green.shade300,
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
    );
  }
  
  Widget _buildRadiusBox(double radius, String label) {
    return Container(
      width: 80.w,
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.orange.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
    );
  }
  
  Widget _buildResponsiveLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据宽度决定布局方式
        if (constraints.maxWidth >= 600.w) {
          // 宽屏布局 - 水平排列
          return Row(
            children: [
              Expanded(child: _buildCard('卡片 1', Colors.red.shade100)),
              SizedBox(width: 16.w),
              Expanded(child: _buildCard('卡片 2', Colors.green.shade100)),
              SizedBox(width: 16.w),
              Expanded(child: _buildCard('卡片 3', Colors.blue.shade100)),
            ],
          );
        } else {
          // 窄屏布局 - 垂直排列
          return Column(
            children: [
              _buildCard('卡片 1', Colors.red.shade100),
              SizedBox(height: 16.h),
              _buildCard('卡片 2', Colors.green.shade100),
              SizedBox(height: 16.h),
              _buildCard('卡片 3', Colors.blue.shade100),
            ],
          );
        }
      },
    );
  }
  
  Widget _buildCard(String title, Color color) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            '这是一个响应式卡片，会根据屏幕宽度自动调整布局。在不同尺寸的显示器上，元素大小会保持一致的比例。',
            style: TextStyle(fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              '按钮示例',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}
