import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import '../../head/logic.dart';
import '../../sidebar/logic.dart';
import 'countdown_logic.dart';
import 'exam_logic.dart';
import 'ws_logic.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final List<bool> _isHovering = List.generate(4, (_) => false); // Initialize hover state
  late Countdown countdownLogic;
  final headerLogic = Get.put(HeadLogic());
  final wsLogic = Get.put(WSLogic());
  final examLogic = Get.put(ExamLogic());

  @override
  void initState() {
    countdownLogic = Countdown(
        totalDuration: 900); // Default total duration in seconds (15 minutes)
    _listenToCountdown();
    super.initState();
  }

  @override
  void dispose() {
    countdownLogic.dispose();
    examLogic.scrollController.dispose();
    examLogic.listController.dispose();
    wsLogic.webSocketService.disconnect();
    wsLogic.webSocketService.dispose();
    headerLogic.dispose();
    wsLogic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          title: const Text(''),
          centerTitle: true,
          elevation: 0, // 设置 elevation 为 0
          flexibleSpace: FlexibleSpaceBar(
            background: Image.asset(
              'assets/images/exam_banner_logo.png',
              fit: BoxFit.fill,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () {
                  headerLogic.clickHeadImage();
                },
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/cat.jpeg",
                    height: 42,
                    width: 42,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          child: _buildPanel(),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.yellow,
            image: DecorationImage(
              image: AssetImage('assets/images/exam_page_bg.png'),
              fit: BoxFit.fill,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(1),
                BlendMode.dstATop,
              ),
            ),
          ),
          width: 1440,
          height: 702,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              _buildMainContent(),
              _buildInfoPanel(),
            ],
          ),
        ),
      ],
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
                image: AssetImage('assets/images/no_questions_bg.jpg'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            '等待教师下发试题',
            style: TextStyle(
              color: Color(0xFF383838),
              fontSize: 18,
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
      child: Container(
        width: 300, // 添加固定宽度
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
      ),
    );
  }

  Widget _buildStudentInfo() {
    return _buildTextWithInput('登录码:', '请输入登录码', Color(0xFFFFFBC7), Color(0xFFFF0004));
  }

  Widget _buildTextWithInput(String label, String placeholder, Color labelColor, Color textColor) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 20),
        Container(
          width: 120, // 设置宽度
          height: 35, // 设置高度
          child: TextField(
            keyboardType: TextInputType.number, // 设置输入类型为数字
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
              LengthLimitingTextInputFormatter(6), // 限制输入最大长度为6位
            ],
            decoration: InputDecoration(
              filled: true, // 启用填充
              fillColor: Colors.white, // 设置背景色
              hintText: placeholder,
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'PingFang SC',
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ), // 设置提示文字颜色
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), // 内边距
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: textColor, width: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: textColor, width: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: TextStyle(color: Colors.orange, fontSize: 16), // 输入文字颜色和样式
          ),
        ),
        SizedBox(width: 20),
        _buildConnectButton(),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('连接状态：', style: TextStyle(color: Color(0xFFFFFBC7), fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildConnectButton() {
    return TextButton(
      onPressed: () {
        print('连接按钮被点击');
        HapticFeedback.lightImpact();
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.black.withOpacity(0.2);
            }
            return Colors.transparent;
          },
        ),
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return Colors.black.withOpacity(0.1);
            }
            return null;
          },
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
      child: Container(
        width: 70,
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFFFD566), Colors.white],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '连接',
            style: TextStyle(color: Color(0xFFFF4F1A), fontSize: 16),
          ),
        ),
      ),
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

  void _listenToCountdown() {
    countdownLogic.tickStream.listen((seconds) {
      setState(() {});
    });

    countdownLogic.isRunningStream.listen((isRunning) {
      setState(() {});
    });

    countdownLogic.segmentsStream.listen((segments) {
      setState(() {});
    });
  }
}
