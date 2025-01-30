import 'package:get/get.dart';
import '../../../../api/student_api.dart';

class PsychologyLogic extends GetxController {
  // 状态变量
  final RxBool isLoading = false.obs;
  final RxBool isCompleted = false.obs;
  final Rx<Map<String, dynamic>?> currentQuestion = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    loadNextQuestion();
  }

  // 加载下一个问题
  Future<void> loadNextQuestion() async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      final response = await StudentApi.questionPull(params: {
        "current_id": currentQuestion.value?['id']?.toString() ?? "",
      });

      isLoading.value = false;
      if (response != null && response.isNotEmpty) {
        currentQuestion.value = response;
      } else {
        isCompleted.value = true;
      }
    } catch (e) {
      isLoading.value = false;
      print("Error loading question: $e");
    }
  }

  // 提交答案
  Future<void> submitAnswer(String answer) async {
    if (isLoading.value || currentQuestion.value == null) return;

    isLoading.value = true;

    try {
      await StudentApi.submit({
        "question_id": currentQuestion.value!['id'].toString(),
        "answer": answer,
      });

      // 加载下一题
      loadNextQuestion();
    } catch (e) {
      isLoading.value = false;
      print("Error submitting answer: $e");
    }
  }
}