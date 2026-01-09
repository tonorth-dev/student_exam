import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../api/subject_api.dart';
import '../../../../../common/encr_util.dart';
import '../../../../../ex/ex_hint.dart';

/// 红师AI题库Logic
class AISubjectLogic extends GetxController {
  // 题目列表
  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;

  // 缓存两种类型的题目数据
  final Map<int, List<SubjectModel>> _cachedSubjects = {};
  final Map<int, int> _cachedTotals = {};

  // 每页数量（固定5题）
  final int pageSize = 5;

  // 总数
  final RxInt total = 0.obs;

  // 加载状态
  final RxBool isLoading = false.obs;

  // 错误信息
  final RxString errorMessage = ''.obs;

  // 展开的题目答案（记录题目ID）
  final RxSet<int> expandedAnswers = <int>{}.obs;

  // 当前选中的类型：1-岗位题目, 2-专业题目
  final RxInt currentType = 1.obs;

  @override
  void onInit() {
    super.onInit();
    loadSubjects();
  }

  /// 切换题目类型
  void switchType(int type) {
    if (currentType.value != type) {
      currentType.value = type;
      
      // 如果已经缓存了该类型的数据，直接使用缓存
      if (_cachedSubjects.containsKey(type) && _cachedSubjects[type]!.isNotEmpty) {
        subjects.value = _cachedSubjects[type]!;
        total.value = _cachedTotals[type] ?? 0;
      } else {
        // 否则重新加载
        loadSubjects();
      }
    }
  }

  /// 加载题目列表
  Future<void> loadSubjects({int retryCount = 0}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final data = await SubjectApi.getAISubjectList(params: {
        'page': 1,  // 服务端随机给题，页码固定为1
        'pageSize': pageSize,
        'type': currentType.value,  // 1-岗位题目, 2-专业题目
      });

      if (data != null) {
        total.value = data['total'] ?? 0;

        if (data['list'] != null) {
          final rawSubjects = (data['list'] as List)
              .map((item) => SubjectModel.fromJson(item))
              .toList();

          // 解密所有题目
          final decryptedSubjects = <SubjectModel>[];
          for (var subject in rawSubjects) {
            final decrypted = await subject.decrypt();
            decryptedSubjects.add(decrypted);
          }

          subjects.value = decryptedSubjects;
          
          // 缓存当前类型的数据
          _cachedSubjects[currentType.value] = decryptedSubjects;
          _cachedTotals[currentType.value] = total.value;
        } else {
          subjects.value = [];
        }

        // 清空展开状态
        expandedAnswers.clear();
      }
    } catch (e) {
      debugPrint('加载题目失败 (尝试 ${retryCount + 1}/2): $e');

      // 如果是第一次失败，自动重试一次
      if (retryCount == 0) {
        debugPrint('正在重试...');
        await Future.delayed(const Duration(milliseconds: 500));
        return loadSubjects(retryCount: 1);
      }

      // 第二次也失败了，显示错误信息
      errorMessage.value = '加载题目失败';
      subjects.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// 切换答案展开状态
  void toggleAnswer(int id) {
    if (expandedAnswers.contains(id)) {
      expandedAnswers.remove(id);
    } else {
      expandedAnswers.add(id);
    }
  }

  /// 对题目进行评分
  Future<void> rateSubject(int subjectId, int rating) async {
    try {
      await SubjectApi.rateSubject(
        subjectId: subjectId,
        rating: rating,
      );

      '评分成功'.toHint();
      
      // 重新加载题目以获取最新的平均评分
      loadSubjects();
    } catch (e) {
      debugPrint('评分失败: $e');
      '评分失败'.toHint();
    }
  }

  /// 刷新题目（换一换）
  @override
  void refresh() {
    loadSubjects();
  }
}

/// 题目数据模型
class SubjectModel {
  final int id;
  final String title;        // 题目内容（明文）
  final String titleEncr;    // 题目内容（加密）
  final String answer;       // 答案内容（明文）
  final String answerEncr;   // 答案内容（加密）
  final String cate;         // 题型类别
  final String level;        // 难度等级
  final String majorCode;    // 专业代码
  final int subjectCategory; // 学科类别
  final String tag;          // 标签
  final String author;       // 作者
  final String belongYear;   // 所属年份
  final double avgRating;    // 平均评分 (0.0-5.0)
  final int ratingCount;     // 评分人数

  SubjectModel({
    required this.id,
    required this.title,
    required this.titleEncr,
    required this.answer,
    required this.answerEncr,
    required this.cate,
    required this.level,
    required this.majorCode,
    required this.subjectCategory,
    required this.tag,
    required this.author,
    required this.belongYear,
    this.avgRating = 0.0,
    this.ratingCount = 0,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      titleEncr: json['title_encr'] ?? '',
      answer: json['answer'] ?? '',
      answerEncr: json['answer_encr'] ?? '',
      cate: json['cate'] ?? '',
      level: json['level'] ?? '',
      majorCode: json['major_code'] ?? '',
      subjectCategory: json['subject_category'] ?? 0,
      tag: json['tag'] ?? '',
      author: json['author'] ?? '',
      belongYear: json['belong_year'] ?? '',
      avgRating: (json['avg_rating'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
    );
  }

  /// 复制并修改部分字段
  SubjectModel copyWith({
    int? id,
    String? title,
    String? titleEncr,
    String? answer,
    String? answerEncr,
    String? cate,
    String? level,
    String? majorCode,
    int? subjectCategory,
    String? tag,
    String? author,
    String? belongYear,
    double? avgRating,
    int? ratingCount,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEncr: titleEncr ?? this.titleEncr,
      answer: answer ?? this.answer,
      answerEncr: answerEncr ?? this.answerEncr,
      cate: cate ?? this.cate,
      level: level ?? this.level,
      majorCode: majorCode ?? this.majorCode,
      subjectCategory: subjectCategory ?? this.subjectCategory,
      tag: tag ?? this.tag,
      author: author ?? this.author,
      belongYear: belongYear ?? this.belongYear,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  /// 解密题目和答案
  Future<SubjectModel> decrypt() async {
    String decryptedTitle = title;
    String decryptedAnswer = answer;

    // 如果明文为空，尝试解密
    if (decryptedTitle.isEmpty && titleEncr.isNotEmpty) {
      try {
        decryptedTitle = await EncryptionUtil.decryptAES256(titleEncr);
      } catch (e) {
        debugPrint('解密题目失败: $e');
        decryptedTitle = '【题目解密失败】';
      }
    }

    if (decryptedAnswer.isEmpty && answerEncr.isNotEmpty) {
      try {
        decryptedAnswer = await EncryptionUtil.decryptAES256(answerEncr);
      } catch (e) {
        debugPrint('解密答案失败: $e');
        decryptedAnswer = '【答案解密失败】';
      }
    }

    // 返回新的实例，包含解密后的内容
    return SubjectModel(
      id: id,
      title: decryptedTitle,
      titleEncr: titleEncr,
      answer: decryptedAnswer,
      answerEncr: answerEncr,
      cate: cate,
      level: level,
      majorCode: majorCode,
      subjectCategory: subjectCategory,
      tag: tag,
      author: author,
      belongYear: belongYear,
      avgRating: avgRating,
      ratingCount: ratingCount,
    );
  }
}
