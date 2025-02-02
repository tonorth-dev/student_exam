import 'package:student_exam/app/home/pages/lecture/pdf_pre_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/theme_util.dart';
import '../../sidebar/logic.dart';
import 'logic.dart';
import '../../../../api/student_api.dart';

class PsychologyPage extends StatefulWidget {
  @override
  _PsychologyPageState createState() => _PsychologyPageState();

  static SidebarTree newThis() {
    return SidebarTree(
      name: "心理测试",
      icon: Icons.psychology_outlined,
      page: PsychologyPage(),
    );
  }
}

class _PsychologyPageState extends State<PsychologyPage> {
  final logic = Get.put(PsychologyLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图
          Positioned.fill(
            child: Image.asset(
              'assets/images/psy_page_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // 内容层
          Column(
            children: [
              ThemeUtil.height(),
              SizedBox(height:150),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() {
      if (logic.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (logic.isCompleted.value) {
        return _buildCompletionScreen();
      }

      if (logic.currentQuestion.value == null) {
        return Center(child: Text("加载题目失败，请重试"));
      }

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1000),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 问题展示区域
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    logic.currentQuestion.value!['question'] ?? "",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 60),
                // 答案按钮 - 只在答案不为空时显示
                if (logic.currentQuestion.value!['answer_a']?.isNotEmpty ?? false) ...[
                  _buildAnswerButton('A', logic.currentQuestion.value!['answer_a']!),
                  SizedBox(height: 20),
                ],
                if (logic.currentQuestion.value!['answer_b']?.isNotEmpty ?? false) ...[
                  _buildAnswerButton('B', logic.currentQuestion.value!['answer_b']!),
                  SizedBox(height: 20),
                ],
                if (logic.currentQuestion.value!['answer_c']?.isNotEmpty ?? false)
                  _buildAnswerButton('C', logic.currentQuestion.value!['answer_c']!),
                // 添加提示文字
                SizedBox(height: 100),
                Container(
                  padding: EdgeInsets.only(bottom: 30),
                  child: Text(
                    "心理测试过程，最好一次性完成，以方便导师准确判断您的测试情况",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAnswerButton(String option, String answer) {
    return ElevatedButton(
      onPressed: () => logic.submitAnswer(option),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue.shade600,
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Colors.blue.shade400,
            width: 1,
          ),
        ),
        elevation: 2,
        shadowColor: Colors.blue.withOpacity(0.3),
      ),
      child: Text(
        "$option. $answer",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green,
          ),
          SizedBox(height: 20),
          Text(
            "测试完成！",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "感谢您完成本次心理测试",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => logic.resetTest(),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue.shade600,
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: Colors.blue.shade400,
                  width: 1,
                ),
              ),
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.3),
            ),
            child: Text(
              "再测一次",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}