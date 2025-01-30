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
}

class _PsychologyPageState extends State<PsychologyPage> {
  final logic = Get.put(PsychologyLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ThemeUtil.height(),
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

      return Column(
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
          SizedBox(height: 40),
          // 答案按钮
          _buildAnswerButton('A', logic.currentQuestion.value!['answer_a'] ?? ""),
          SizedBox(height: 20),
          _buildAnswerButton('B', logic.currentQuestion.value!['answer_b'] ?? ""),
          SizedBox(height: 20),
          _buildAnswerButton('C', logic.currentQuestion.value!['answer_c'] ?? ""),
        ],
      );
    });
  }

  Widget _buildAnswerButton(String option, String answer) {
    return ElevatedButton(
      onPressed: () => logic.submitAnswer(option),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        "$option. $answer",
        style: TextStyle(fontSize: 16),
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
        ],
      ),
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "心理测试",
      icon: Icons.psychology_outlined,
      page: PsychologyPage(),
    );
  }
}