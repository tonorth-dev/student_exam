import 'package:student_exam/app/home/pages/lecture/pdf_pre_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/theme_util.dart';
import '../../sidebar/logic.dart';
import 'logic.dart';
import '../../../../api/student_api.dart';
import 'package:student_exam/common/app_providers.dart';

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
    final screenAdapter = AppProviders.instance.screenAdapter;
    
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
              SizedBox(height: screenAdapter.getAdaptiveHeight(150)),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(24.0)),
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
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    return Obx(() {
      if (logic.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (logic.isCompleted.value) {
        return _buildCompletionScreen();
      }

      if (logic.currentQuestion.value == null) {
        return Center(
          child: Text(
            "加载题目失败，请重试",
            style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(16)),
          ),
        );
      }

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenAdapter.getAdaptiveWidth(1000)),
          child: Container(
            padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 问题展示区域
                Container(
                  padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(20)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: screenAdapter.getAdaptivePadding(1),
                        blurRadius: screenAdapter.getAdaptivePadding(10),
                        offset: Offset(0, screenAdapter.getAdaptiveHeight(3)),
                      ),
                    ],
                  ),
                  child: Text(
                    logic.currentQuestion.value!['question'] ?? "",
                    style: TextStyle(
                      fontSize: screenAdapter.getAdaptiveFontSize(20),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: screenAdapter.getAdaptiveHeight(60)),
                // 答案按钮 - 只在答案不为空时显示
                if (logic.currentQuestion.value!['answer_a']?.isNotEmpty ?? false) ...[
                  _buildAnswerButton('A', logic.currentQuestion.value!['answer_a']!),
                  SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
                ],
                if (logic.currentQuestion.value!['answer_b']?.isNotEmpty ?? false) ...[
                  _buildAnswerButton('B', logic.currentQuestion.value!['answer_b']!),
                  SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
                ],
                if (logic.currentQuestion.value!['answer_c']?.isNotEmpty ?? false)
                  _buildAnswerButton('C', logic.currentQuestion.value!['answer_c']!),
                // 添加提示文字
                SizedBox(height: screenAdapter.getAdaptiveHeight(100)),
                Container(
                  padding: EdgeInsets.only(bottom: screenAdapter.getAdaptivePadding(30)),
                  child: Text(
                    "心理测试过程，最好一次性完成，以方便导师准确判断您的测试情况",
                    style: TextStyle(
                      fontSize: screenAdapter.getAdaptiveFontSize(16),
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
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    return ElevatedButton(
      onPressed: () => logic.submitAnswer(option),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue.shade600,
        padding: EdgeInsets.symmetric(
          vertical: screenAdapter.getAdaptivePadding(20), 
          horizontal: screenAdapter.getAdaptivePadding(30),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(10)),
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
          fontSize: screenAdapter.getAdaptiveFontSize(16),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: screenAdapter.getAdaptiveIconSize(80),
            color: Colors.green,
          ),
          SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
          Text(
            "测试完成！",
            style: TextStyle(
              fontSize: screenAdapter.getAdaptiveFontSize(24),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenAdapter.getAdaptiveHeight(10)),
          Text(
            "感谢您完成本次心理测试",
            style: TextStyle(
              fontSize: screenAdapter.getAdaptiveFontSize(16),
              color: Colors.grey,
            ),
          ),
          SizedBox(height: screenAdapter.getAdaptiveHeight(180)),
          Visibility(
            visible: !logic.isAllCompleted.value,
            child: ElevatedButton(
              onPressed: () => logic.resetTest(),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue.shade600,
                padding: EdgeInsets.symmetric(
                  vertical: screenAdapter.getAdaptivePadding(15), 
                  horizontal: screenAdapter.getAdaptivePadding(40),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(10)),
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
                  fontSize: screenAdapter.getAdaptiveFontSize(16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}