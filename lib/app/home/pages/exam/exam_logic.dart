import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:student_exam/api/exam_api.dart';
import 'package:student_exam/ex/ex_hint.dart';

class ExamLogic extends GetxController {
  var studentName = '-'.obs;
  var jobCode = '-'.obs;
  var jobName = '-'.obs;
  var majorNames = '-'.obs;
  var jobDescription = '-'.obs;
  var notPracticedCount = 0.obs;

  late ListController listController;
  late ScrollController scrollController;
  List<int> highlightedItems = []; // Example: Highlight the third item
  RxInt currentQuestionIndex = 0.obs;

  // RxList 用于存储题目和答案数据
  var questions = <Question>[].obs;

  @override
  void onInit() {
    listController = ListController();
    scrollController = ScrollController();
    super.onInit();
  }

  // 更新问题列表的方法
  void updateQuestions(List<Question> newQuestions) {
    questions.value = newQuestions;
  }

  // 新增属性：用于控制等待状态
  var isLoading = false.obs;
  var waitingText = ''.obs;

  Future<void> startPractice(int studentId, int examId) async {
    try {
      // 获取单元数据（假设这是你想要从 API 获取的原始数据）
      var unitsData = await ExamApi.examUnits({
        "student_id": studentId,
        "exam_id": examId,
      });

      // 模拟选题逻辑并更新UI状态
      await _simulateQuestionSelection(unitsData, examId);

      // 获取试题数据
      var quesData = await ExamApi.examQuestions({
        "student_id": studentId,
        "exam_id": examId,
        "unit_id": examId,
      });

      // 检查返回的数据是否符合预期
      if (quesData != null && quesData.containsKey("student") && quesData.containsKey("questions") && quesData["student"] != null && quesData["questions"] != null) {
        // 填充学生信息
        studentName.value = quesData["student"]["name"] ?? '-';
        jobCode.value = quesData["student"]["job_code"] ?? '-';
        jobName.value = quesData["student"]["job_name"] ?? '-';
        majorNames.value = quesData["student"]?["major_names"] != null
            ? quesData["student"]["major_names"].join(', ')
            : '-';
        jobDescription.value = quesData["student"]["job_desc"] ?? '-';
      } else {
        '考生试题为空'.toHint();
      }

      // 填充试题列表
      if (quesData.containsKey("questions") && quesData["questions"] != null) {
        print(quesData["questions"]);
        var questions = quesData["questions"] as List;
        updateQuestions(questions.map((q) {
          return Question(
            title: q["topic_title"] ?? '未知标题',
            answer: q["topic_answer"] ?? '暂无答案',
          );
        }).toList());
      }
    } catch (e) {
      // 错误处理
      print("Error in pullExam: $e");
      if (!e.toString().contains('登录已失效')) {
        '系统发生错误，没有抽取到试题'.toHint();
      }
    } finally {
      isLoading.value = false; // 确保无论成功或失败都关闭加载状态
    }
  }

  Future<Map<String, dynamic>?> _simulateQuestionSelection(var unitsData, int examId) async {
    isLoading.value = true;
    waitingText.value = '考生正在选取题目...';

    // 显示加载框
    Get.dialog(
      Obx(() => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(), // 加载动画
            SizedBox(height: 10),
            Text(
              waitingText.value, // 动态提示文案
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )),
      barrierDismissible: false, // 禁止点击空白处关闭
    );

    try {
      // 模拟耗时5秒
      await Future.delayed(Duration(seconds: 5));

      // 假设我们总是选择第一个单元的第一道题目作为示例
      final selectedUnit = unitsData['lists'].firstWhere(
            (unit) => unit['exam_id'] == examId,
        orElse: () => {'id': -1, 'name': 'No Matching Unit Found'},
      );

      if (selectedUnit['id'] != -1) {
        return selectedUnit;
      } else {
        return null;
      }
    } finally {
      // 确保关闭加载框
      Get.back(); // 关闭浮层
      isLoading.value = false;
      waitingText.value = ''; // 清除提示文案
    }
  }

  void animateToItem(int index) {
    highlightedItems = [index];
    if (index < questions.length) {
      // Ensure index is within bounds
      listController.animateToItem(
        index: index,
        scrollController: scrollController,
        alignment: 0.5,
        duration: (estimatedDistance) =>
            Duration(milliseconds: 300),
        curve: (estimatedDistance) => Curves.easeInOut,
      );
    }
  }
}

class Question {
  final String title;
  final String answer;

  Question({required this.title, required this.answer});
}
