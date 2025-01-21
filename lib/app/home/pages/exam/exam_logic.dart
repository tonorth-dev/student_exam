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
