import 'package:flutter/material.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: Scaffold(
        body: const MainContent(),
      ),
    );
  }
}

class MainContent extends StatelessWidget {
  const MainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          width: 1440,
          height: 900,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white),
          child: Stack(
            children: [
              _buildSidePanel(),
              _buildTitle(),
              _buildMainContent(),
              _buildInfoPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidePanel() {
    return Positioned(
      left: 1081.76,
      top: 116,
      child: Container(
        width: 338.14,
        height: 590,
        decoration: ShapeDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.02, -1.00),
            end: Alignment(-0.02, 1),
            colors: [Color(0x7FFFF7DE), Color(0x4CFAE296), Color(0x19FFD565)],
          ),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Colors.white),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Positioned(
      left: 251,
      top: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 13),
          Text(
            '红师文职人员招聘面试系统',
            style: TextStyle(
              color: Color(0xFFFAEEBE),
              fontSize: 60,
              fontFamily: 'Alimama ShuHeiTi',
              fontWeight: FontWeight.w700,
              height: 1.20,
            ),
          ),
          SizedBox(width: 13),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Positioned(
      left: 31.76,
      top: 116,
      child: Container(
        width: 1050,
        height: 590,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildWaitingRoom(),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingRoom() {
    return Padding(
      padding: EdgeInsets.only(top: 135.22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 189.78,
            height: 189.78,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://via.placeholder.com/190x190"),
                fit: BoxFit.fill,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            '等待教室下发试题',
            style: TextStyle(
              color: Color(0xFF383838),
              fontSize: 30,
              fontFamily: 'PingFang SC',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Positioned(
      left: 1113.33,
      top: 139,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStudentInfo(),
          SizedBox(height: 40),
          _buildConnectionStatus(),
          SizedBox(height: 40),
          _buildTimerPanel(),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return _buildTextWithInput('学生端号码:', '请输入学生号码', Color(0xFFFFFBC7), Color(0xFFFF0004));
  }

  Widget _buildConnectionStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('连接状态：', style: TextStyle(color: Color(0xFFFFFBC7), fontSize: 18, fontWeight: FontWeight.w600)),
        _buildConnectButton(),
      ],
    );
  }

  Widget _buildConnectButton() {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFFFFD566), Colors.white],
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: Color(0xFFF92D37)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text('立即连接', style: TextStyle(color: Color(0xFFFF4F1A), fontSize: 16)),
    );
  }

  Widget _buildTimerPanel() {
    return Container(
      width: 275,
      height: 466,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 275,
              height: 375,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            left: 22.44,
            top: 92,
            child: _buildTimerDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDetails() {
    return Column(
      children: [
        _buildTimerDisplay(),
        SizedBox(height: 20),
        Text('分段计时', style: TextStyle(color: Colors.white, fontSize: 20)),
        SizedBox(height: 20),
        _buildTimeSegments(),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return Stack(
      children: [
        // You would need to implement the actual timer display here
      ],
    );
  }

  Widget _buildTimeSegments() {
    return Stack(
      children: [
        // Implement time segment display here
      ],
    );
  }

  Widget _buildTextWithInput(String label, String placeholder, Color labelColor, Color textColor) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 18, fontWeight: FontWeight.w600)),
        SizedBox(width: 20),
        _buildInputField(placeholder, textColor),
      ],
    );
  }

  Widget _buildInputField(String placeholder, Color textColor) {
    return Container(
      width: 160,
      height: 40,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: Color(0xFFF92D37)),
          borderRadius: BorderRadius.circular(10),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x19871B03),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Center(
        child: Text(placeholder, style: TextStyle(color: textColor, fontSize: 16)),
      ),
    );
  }
}