import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:student_exam/ex/ex_hint.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import '../../../../component/lottery.dart';
import '../../../../theme/theme_util.dart';
import '../../head/logic.dart';
import '../../sidebar/logic.dart';
import 'countdown_logic.dart';
import 'exam_logic.dart';
import 'ws_logic.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();

  static SidebarTree newThis() {
    return SidebarTree(
      name: "面试模拟",
      icon: Icons.person_outline,
      page: ExamPage(),
    );
  }
}

class _ExamPageState extends State<ExamPage> {
  final List<bool> _isHovering =
      List.generate(4, (_) => false); // Initialize hover state
  late Countdown countdownLogic;
  final headerLogic = Get.put(HeadLogic());
  final wsLogic = Get.put(WSLogic());
  final examLogic = Get.put(ExamLogic());
  bool _isLoading = false;

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
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Container(
          child: _buildPanel(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: AppBar(
        title: const Text(''),
        centerTitle: true,
        elevation: 0,
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
    );
  }

  Widget _buildPanel() {
    return Column(
      children: [
        Obx(() => Container(
              decoration: BoxDecoration(
                color: Colors.white70,
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
            )),
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
    if (wsLogic.unitsList.value.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 135.22),
        child: Center(
          child: SimpleRoulette(
            options: wsLogic.unitsList.value.map((unit) {
              return {'id': unit['id'], 'name': unit['name']};
            }).toList(),
            onSpinCompleted: (dynamic id) {
              var selectedOption = wsLogic.unitsList.value.firstWhere(
                (option) => option['id'] == id,
                orElse: () => {'id': 'unknown', 'name': 'unknown'},
              );
              "选中试题名称为：${selectedOption['name']}，id：${selectedOption['id']}"
                  .toHint();
              wsLogic.sendStudentSelect(id);
              wsLogic.unitsList.value = [];
            },
            countdown: countdownLogic,
          ),
        ),
      );
    } else if (examLogic.questions.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ConstrainedBox(
          // 确保SuperListView有一个明确的最大高度
          constraints: BoxConstraints(maxHeight: 480), // 根据您的设计调整这个值
          child: SuperListView.builder(
            listController: examLogic.listController,
            controller: examLogic.scrollController,
            itemCount: examLogic.questions.length,
            itemBuilder: (context, index) {
              final question = examLogic.questions[index];
              return _buildQuestion(index: index, question: question);
            },
          ),
        ),
      );
    } else {
      return Column(
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
      );
    }
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
            _buildLoginInfo(),
            SizedBox(height: 10),
            ThemeUtil.lineH(height: 2),
            SizedBox(height: 10),
            _buildConnectionStatus(),
            SizedBox(height: 10),
            ThemeUtil.lineH(height: 2),
            SizedBox(height: 30),
            _buildTimerPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginInfo() {
    return _buildTextWithInput(
        '登录码:', '请输入登录码', Color(0xFFFFFBC7), Color(0xFFFF0004));
  }

  Widget _buildTextWithInput(
      String label, String placeholder, Color labelColor, Color textColor) {
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
            keyboardType: TextInputType.number,
            // 设置输入类型为数字
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
              LengthLimitingTextInputFormatter(6), // 限制输入最大长度为6位
            ],
            onChanged: (value) {
              wsLogic.examCode.value = value;
            },
            decoration: InputDecoration(
              filled: true,
              // 启用填充
              fillColor: Colors.white,
              // 设置背景色
              hintText: placeholder,
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: 'PingFang SC',
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              // 设置提示文字颜色
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              // 内边距
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
        if (wsLogic.connStatusName.value == "未连接" ||
            wsLogic.connStatusName.value == "连接失败" ||
            wsLogic.connStatusName.value == "连接断开" ||
            wsLogic.connStatusName.value == "正在连接...")
          _buildConnectButton(context)
        else
          _buildDisconnectButton(context),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('连接状态：',
            style: TextStyle(
                color: Color(0xFFFFFBC7),
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        Text(
          wsLogic.connStatusName.value,
          style: const TextStyle(
            fontSize: 14.0,
            fontFamily: 'PingFang SC',
            color: Colors.white, // 连接状态颜色
          ),
        ),
      ],
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    return TextButton(
      onPressed: wsLogic.isConnecting
          ? null
          : () {
              wsLogic.connectStudent(wsLogic.examCode.value);
            },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero, // 去掉默认的内边距，方便自定义样式
      ),
      child: Container(
        width: 70,
        height: 35,
        decoration: BoxDecoration(
          gradient: wsLogic.isConnecting
              ? LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.grey, Colors.white], // 加载时的颜色
                )
              : LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFFFFD566), Colors.white], // 默认渐变色
                ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '连接',
            style: TextStyle(
                color:
                    wsLogic.isConnecting ? Colors.white54 : Color(0xFFFF4F1A),
                fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        wsLogic.disconnect();
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero, // 去掉默认的内边距，方便自定义样式
      ),
      child: Container(
        width: 70,
        height: 35,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(
                  colors: [Colors.grey, Colors.grey.shade400], // 加载时的颜色
                )
              : LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFFFFD566), Colors.white], // 默认渐变色
                ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '断开',
            style: TextStyle(color: Colors.blueGrey, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion({required int index, required Question question}) {
    bool isHighlighted = examLogic.highlightedItems.contains(index);
    Color? backgroundColor = isHighlighted ? Color(0xFFEAF7FE) : Colors.white;

    // Scroll to the item after building, but only if it's highlighted and the frame has been laid out
    if (isHighlighted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        examLogic.listController.animateToItem(
          index: index,
          scrollController: examLogic.scrollController,
          alignment: 0.5,
          duration: (estimatedDistance) => Duration(milliseconds: 500),
          curve: (estimatedDistance) => Curves.easeInOut,
        );
      });
    }

    return InkWell(
      onTap: () {
        setState(() {
          examLogic.currentQuestionIndex.value = index;
          examLogic.animateToItem(index);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/question_icon.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.title,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerPanel() {
    return Container(
      width: 320,
      height: 406,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
            2), // Match with parent container
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            SizedBox(height: 16),
            Center(
              child: Text(
                '答题时间',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 30,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // All other elements wrapped in a new container
            Container(
              width: double.infinity,
              height: 339, // Adjusted height for better layout
              decoration: BoxDecoration(
                color: Color(0xFFFFF1E8), // Background color
                borderRadius: BorderRadius.circular(2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontFamily: 'Anton-Regular',
                          ),
                          children: [
                            TextSpan(
                                text: (countdownLogic.currentSeconds ~/ 60)
                                    .toString()
                                    .padLeft(2, '0')[0]),
                            TextSpan(
                              text: ' ',
                              // Increase space between digits of minutes
                              style: TextStyle(
                                  color: Colors.transparent, fontSize: 54),
                            ),
                            TextSpan(
                                text: (countdownLogic.currentSeconds ~/ 60)
                                    .toString()
                                    .padLeft(2, '0')[1]),
                            TextSpan(text: ' : '),
                            // Increase space around colon
                            TextSpan(
                                text: (countdownLogic.currentSeconds % 60)
                                    .toString()
                                    .padLeft(2, '0')[0]),
                            TextSpan(
                              text: ' ',
                              // Increase space between digits of seconds
                              style: TextStyle(
                                  color: Colors.transparent, fontSize: 54),
                            ),
                            TextSpan(
                                text: (countdownLogic.currentSeconds % 60)
                                    .toString()
                                    .padLeft(2, '0')[1]),
                          ],
                        ),
                      ),
                    ),
                    if (countdownLogic.showElapsedTime)
                      Center(
                        child: Text(
                          '本次共用时${(countdownLogic.totalDuration - countdownLogic.currentSeconds) ~/ 60}分${(countdownLogic.totalDuration - countdownLogic.currentSeconds) % 60}秒',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.orange,
                            fontFamily: 'PingFang SC',
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Space between time and button
                    // Custom button directly below the time display
                    Expanded(
                      child: StreamBuilder<List<String>>(
                        stream: countdownLogic.segmentsStream,
                        initialData: [],
                        builder: (context, snapshot) {
                          final segments = snapshot.data ?? [];
                          return ListView.builder(
                            itemCount: segments.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: Text(
                                  '第${index + 1}段用时：',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'PingFang SC',
                                  ),
                                ),
                                title: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    segments[index],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.redAccent,
                                      fontFamily: 'OPPOSans',
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        child:
            Text(placeholder, style: TextStyle(color: textColor, fontSize: 16)),
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
