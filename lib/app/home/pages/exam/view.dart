import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:student_exam/ex/ex_hint.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import '../../../../component/lottery.dart';
import '../../../../theme/theme_util.dart';
import '../../../../common/app_providers.dart';
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

  // 从 AppProviders 获取 screenAdapter
  final screenAdapter = AppProviders.instance.screenAdapter;

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
      preferredSize: Size.fromHeight(screenAdapter.getAdaptiveHeight(80)),
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
            padding:
                EdgeInsets.only(right: screenAdapter.getAdaptivePadding(16.0)),
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(screenAdapter.getAdaptiveWidth(32)),
              onTap: () {
                headerLogic.clickHeadImage();
              },
              child: ClipOval(
                child: Image.asset(
                  "assets/images/cat.jpeg",
                  height: screenAdapter.getAdaptiveHeight(42),
                  width: screenAdapter.getAdaptiveWidth(42),
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
              width: screenAdapter.getAdaptiveWidth(1440),
              height: screenAdapter.getAdaptiveHeight(796),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: EdgeInsets.only(
                    left: screenAdapter.getAdaptivePadding(11.0),
                    top: screenAdapter.getAdaptivePadding(12.0),
                    right: screenAdapter.getAdaptivePadding(16.0),
                    bottom: screenAdapter.getAdaptivePadding(25.0)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 76, // 约76%的空间给主内容区
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: screenAdapter.getAdaptivePadding(100.0),
                          left: screenAdapter.getAdaptivePadding(15.76),
                        ),
                        child: _buildMainContent(),
                      ),
                    ),
                    SizedBox(width: screenAdapter.getAdaptiveWidth(32)),
                    Expanded(
                      flex: 24, // 约24%的空间给信息面板
                      child: Container(
                        padding: EdgeInsets.only(
                          top: screenAdapter.getAdaptivePadding(123.0),
                        ),
                        child: _buildInfoPanel(),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screenAdapter.getAdaptiveWidth(20)),
            bottomLeft: Radius.circular(screenAdapter.getAdaptiveWidth(20)),
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(child: _buildWaitingRoom()),
        ],
      ),
    );
  }

  Widget _buildWaitingRoom() {
    if (wsLogic.unitsList.value.isNotEmpty) {
      return Center(
        child: Padding(
          padding:
              EdgeInsets.only(top: screenAdapter.getAdaptiveHeight(135.22)),
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
        padding: EdgeInsets.symmetric(
            horizontal: screenAdapter.getAdaptivePadding(16.0),
            vertical: screenAdapter.getAdaptivePadding(8.0)),
        child: ConstrainedBox(
          // 确保SuperListView有一个明确的最大高度
          constraints:
              BoxConstraints(maxHeight: screenAdapter.getAdaptiveHeight(480)),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: screenAdapter.getAdaptiveWidth(189.78),
            height: screenAdapter.getAdaptiveHeight(189.78),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/no_questions_bg.jpg'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
          Text(
            '等待教师下发试题',
            style: TextStyle(
              color: Color(0xFF383838),
              fontSize: screenAdapter.getAdaptiveFontSize(18),
              fontFamily: 'PingFang SC',
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
          SizedBox(height: screenAdapter.getAdaptiveHeight(60)),
        ],
      );
    }
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: EdgeInsets.only(right: screenAdapter.getAdaptiveWidth(14)),
      width: screenAdapter.getAdaptiveWidth(300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenAdapter.getAdaptiveHeight(10)),
          _buildLoginInfo(),
          SizedBox(height: screenAdapter.getAdaptiveHeight(10)),
          ThemeUtil.lineH(height: screenAdapter.getAdaptiveHeight(2)),
          SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
          _buildConnectionStatus(),
          SizedBox(height: screenAdapter.getAdaptiveHeight(10)),
          ThemeUtil.lineH(height: screenAdapter.getAdaptiveHeight(2)),
          SizedBox(height: screenAdapter.getAdaptiveHeight(30)),
          _buildTimerPanel(),
        ],
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
            fontSize: screenAdapter.getAdaptiveFontSize(16),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: screenAdapter.getAdaptiveWidth(10)),
        Container(
          width: screenAdapter.getAdaptiveWidth(120),
          height: screenAdapter.getAdaptiveHeight(35),
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
                fontSize: screenAdapter.getAdaptiveFontSize(14),
                fontWeight: FontWeight.w400,
              ),
              // 设置提示文字颜色
              contentPadding: EdgeInsets.symmetric(
                  vertical: screenAdapter.getAdaptivePadding(10),
                  horizontal: screenAdapter.getAdaptivePadding(15)),
              // 内边距
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: textColor, width: 0.2),
                borderRadius:
                    BorderRadius.circular(screenAdapter.getAdaptiveWidth(8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: textColor, width: 0.8),
                borderRadius:
                    BorderRadius.circular(screenAdapter.getAdaptiveWidth(8)),
              ),
            ),
            style: TextStyle(
                color: Colors.orange,
                fontSize: screenAdapter.getAdaptiveFontSize(16)), // 输入文字颜色和样式
          ),
        ),
        SizedBox(width: screenAdapter.getAdaptiveWidth(20)),
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
                fontSize: screenAdapter.getAdaptiveFontSize(16),
                fontWeight: FontWeight.w600)),
        Text(
          wsLogic.connStatusName.value,
          style: TextStyle(
            fontSize: screenAdapter.getAdaptiveFontSize(14.0),
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
        width: screenAdapter.getAdaptiveWidth(70),
        height: screenAdapter.getAdaptiveHeight(35),
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
          borderRadius:
              BorderRadius.circular(screenAdapter.getAdaptiveWidth(10)),
        ),
        child: Center(
          child: Text(
            '连接',
            style: TextStyle(
                color:
                    wsLogic.isConnecting ? Colors.white54 : Color(0xFFFF4F1A),
                fontSize: screenAdapter.getAdaptiveFontSize(16)),
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
        width: screenAdapter.getAdaptiveWidth(70),
        height: screenAdapter.getAdaptiveHeight(35),
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
          borderRadius:
              BorderRadius.circular(screenAdapter.getAdaptiveWidth(10)),
        ),
        child: Center(
          child: Text(
            '断开',
            style: TextStyle(
                color: Colors.blueGrey,
                fontSize: screenAdapter.getAdaptiveFontSize(16)),
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
        margin:
            EdgeInsets.symmetric(vertical: screenAdapter.getAdaptivePadding(8)),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
              BorderRadius.circular(screenAdapter.getAdaptiveWidth(2)),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.grey[50],
                padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(8.0)),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/question_icon.png',
                      width: screenAdapter.getAdaptiveWidth(24),
                      height: screenAdapter.getAdaptiveHeight(24),
                    ),
                    SizedBox(width: screenAdapter.getAdaptiveWidth(10)),
                    Expanded(
                      child: Text(
                        question.title,
                        style: TextStyle(
                            fontSize: screenAdapter.getAdaptiveFontSize(16)),
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
      width: screenAdapter.getAdaptiveWidth(320),
      height: screenAdapter.getAdaptiveHeight(476),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
            screenAdapter.getAdaptiveWidth(2)), // Match with parent container
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            SizedBox(height: screenAdapter.getAdaptiveHeight(16)),
            Center(
              child: Text(
                '答题时间',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: screenAdapter.getAdaptiveFontSize(30),
                ),
              ),
            ),
            SizedBox(height: screenAdapter.getAdaptiveHeight(8)),
            // All other elements wrapped in a new container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFFFFF1E8), // Background color
                  borderRadius:
                      BorderRadius.circular(screenAdapter.getAdaptiveWidth(2)),
                ),
                child: Padding(
                  padding:
                      EdgeInsets.all(screenAdapter.getAdaptivePadding(16.0)),
                  child: Column(
                    children: [
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: screenAdapter.getAdaptiveFontSize(40),
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
                                    color: Colors.transparent,
                                    fontSize:
                                        screenAdapter.getAdaptiveFontSize(54)),
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
                                    color: Colors.transparent,
                                    fontSize:
                                        screenAdapter.getAdaptiveFontSize(54)),
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
                              fontSize: screenAdapter.getAdaptiveFontSize(18),
                              color: Colors.orange,
                              fontFamily: 'PingFang SC',
                            ),
                          ),
                        ),
                      SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
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
                                      fontSize:
                                          screenAdapter.getAdaptiveFontSize(18),
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'PingFang SC',
                                    ),
                                  ),
                                  title: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      segments[index],
                                      style: TextStyle(
                                        fontSize: screenAdapter
                                            .getAdaptiveFontSize(18),
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
            ),
          ],
        ),
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
