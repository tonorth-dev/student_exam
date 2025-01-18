import 'package:flutter/material.dart';
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
        preferredSize: const Size.fromHeight(95),
        child: AppBar(
          title: const Text(''),
          centerTitle: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Image.asset(
              'assets/images/exam_banner_logo.png',
              fit: BoxFit.cover,
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
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/exam_page_bg.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 0),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPanel(),
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

  Widget _buildConnect() {
    return Obx(() => Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      width: 314,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black87, // 设置背景颜色为深色
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center( // 使用 Center 小部件使内容垂直居中
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 第一行：学生端登录码和实际登录码
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 将元素左右对齐
              children: [
                const Text(
                  "登录码：",
                  style: TextStyle(fontSize: 14.0, color: Colors.white),
                ),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(),
                    onChanged: (value) {
                      wsLogic.examCode.value = value;
                    },
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontFamily: 'PingFang SC',
                      color: Colors.orangeAccent, // 登录码颜色为绿色
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none, // 去掉边框
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 将元素左右对齐
              children: [
                const Text(
                  "连接状态：",
                  style: TextStyle(fontSize: 14.0, color: Colors.white),
                ),
                Row(
                  children: [
                    // 连接状态文本
                    Text(
                      wsLogic.connStatusName.value,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontFamily: 'PingFang SC',
                        color: Colors.greenAccent, // 连接状态颜色
                      ),
                    ),
                    const SizedBox(width: 25),
                    // 根据连接状态决定按钮是否可用
                    if (wsLogic.connStatusName.value == "未连接" || wsLogic.connStatusName.value == "连接失败")
                      Container(
                        width: 60,
                        height: 25,
                        child: TextButton(
                          onPressed: () {
                            // 点击按钮后调用wsLogic中的连接方法
                            wsLogic.connectStudent(wsLogic.examCode.value);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue, // 按钮文字颜色
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6), // 设置较小的圆角半径
                            ),
                          ),
                          child: const Text("连接"),
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 25,
                        child: TextButton(
                          onPressed: null,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6), // 设置较小的圆角半径
                            ),
                          ),
                          child: const Text("连接"),
                        ),
                      )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildQuestionContent(),
          ),
          const SizedBox(width: 38),
          Column(
            children: [
              _buildConnect(),
              const SizedBox(height: 10),
              _buildTimer(),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x70FFDBDB),
        borderRadius: BorderRadius.circular(2),
        image: DecorationImage(
          image: AssetImage('assets/images/exam_questions_bg.jpg'), // 替换为你的背景图片路径
          fit: BoxFit.fill, // 根据需要调整图片的填充方式
        ),
      ),
      child: Column(
        children: [
          // 始终显示顶部图片
          const SizedBox(height: 15),
          Expanded(
            child: Stack(
              children: [
                // 背景图片（当题目列表为空时显示）
                Obx(
                      () => examLogic.questions.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/no_questions_bg.jpg',
                          width: 200,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '等待教师下发试题',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(), // 当有数据时不显示背景图片
                ),
                // 题目列表内容
                Obx(
                      () => examLogic.questions.isEmpty
                      ? const SizedBox.shrink() // 列表为空时不显示内容
                      : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: SuperListView.builder(
                      listController: examLogic.listController,
                      controller: examLogic.scrollController,
                      itemCount: examLogic.questions.length,
                      itemBuilder: (context, index) {
                        final question = examLogic.questions[index];
                        return _buildQuestion(
                            index: index, question: question);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              const SizedBox(height: 10),
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/answer_icon.png',
                      width: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.answer,
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 14,
                        ),
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

  Widget _buildTimer() {
    return Container(
      width: 340,
      height: 800, // Adjusted height for better layout
      decoration: BoxDecoration(
        color: Colors.red[400],
        borderRadius:
        BorderRadius.circular(2), // Increased border radius for aesthetics
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Timer header image
            Container(
              width: double.infinity, // Make it stretch horizontally
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Image.asset(
                'assets/images/timer_header.png',
                height: 46,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  // White container with time display and button inside
                  Container(
                    width: double.infinity,
                    height: 550, // Adjusted height for better layout
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          2), // Match with parent container
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Time display at the top of the white container
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 54,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontFamily: 'Anton-Regular',
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                      (countdownLogic.currentSeconds ~/ 60)
                                          .toString()
                                          .padLeft(2, '0')[0]),
                                  TextSpan(
                                    text: ' ',
                                    // Increase space between digits of minutes
                                    style: TextStyle(
                                        color: Colors.transparent,
                                        fontSize: 54),
                                  ),
                                  TextSpan(
                                      text:
                                      (countdownLogic.currentSeconds ~/ 60)
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
                                        fontSize: 54),
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
                          _buildCustomButton(),
                          const SizedBox(height: 20),
                          // Display segments using ListView
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
          ],
        ),
      ),
    );
  }

// The custom button widget remains unchanged
  Widget _buildCustomButton() {
    return Container(
      width: double.infinity, // Make the button stretch horizontally
      height: 50, // Adjust based on design needs
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/timer_seg.png'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(2), // Match with parent container
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            countdownLogic.markSegment();
          },
          onHover: (isHovering) {
            // Optional: Change state or appearance when hovered
          },
          child: Center(
            child: Text(
              '分段计时', // Button label
              style: TextStyle(
                color: Colors.white, // Label color
                fontSize: 20, // Label size
                fontWeight: FontWeight.bold, // Label weight
              ),
            ),
          ),
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

  static SidebarTree newThis() {
    return SidebarTree(
      name: "机构管理",
      icon: Icons.app_registration_outlined,
      page: ExamPage(),
    );
  }
}
