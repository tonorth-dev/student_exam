import 'package:flutter/material.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

// Main application entry point
class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: const MainPage(),
    );
  }
}

// Main page scaffold
class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: const [
          MainContent(),
        ],
      ),
    );
  }
}

// Main content widget
class MainContent extends StatelessWidget {
  const MainContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 1440,
        height: 810,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 70,
              top: 130,
              child: Container(
                width: 1300,
                height: 650,
                child: Column(
                  children: [
                    _questionContainer(
                      "一、你觉得适应岗位应该具有什么能力(素质)?(做好文职工作需要什么能力或素质?)",
                      const Color(0xFFFAECEB),
                    ),
                    const SizedBox(height: 25),
                    _questionContainer(
                      "二、什么是军队数字营区?",
                      const Color(0xFFF7F7F7),
                    ),
                    const SizedBox(height: 25),
                    _questionContainer(
                      "三、如何加强基建营房档案信息网络管理?",
                      const Color(0xFFF7F7F7),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 417,
              top: 26,
              child: _headerRow(),
            ),
            Positioned(
              left: 246,
              top: 20,
              child: _titleText(),
            ),
          ],
        ),
      ),
    );
  }

  // Question container widget
  Widget _questionContainer(String text, Color backgroundColor) {
    return Container(
      width: double.infinity,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 19),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 30,
          fontFamily: 'PingFang SC',
          fontWeight: FontWeight.w400,
          height: 1.40,
        ),
      ),
    );
  }

  // Header row widget
  Widget _headerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _headerItem("001", Colors.white),
        _headerItem("00:00", const Color(0xFFFFEB3B)),
      ],
    );
  }

  // Header item widget
  Widget _headerItem(String text, Color color) {
    return Container(
      width: 160,
      height: 65,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 50,
          fontFamily: 'Alibaba PuHuiTi',
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  // Title text widget
  Widget _titleText() {
    return SizedBox(
      width: 720,
      child: Text(
        '红师文职人员招聘面试系统',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFAEEBE),
          fontSize: 60,
          fontFamily: 'Alimama ShuHeiTi',
          fontWeight: FontWeight.w700,
          height: 1.20,
        ),
      ),
    );
  }
}
