import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../api/subject_api.dart';
import '../../../../../common/encr_util.dart';
import '../../../../../ex/ex_hint.dart';

/// 专业题库Logic
class SelfResearchLogic extends GetxController with GetSingleTickerProviderStateMixin {
  // TabController
  TabController? tabController;

  // Category列表
  final RxList<int> categories = <int>[].obs;

  // 当前选中的category索引
  final RxInt currentCategoryIndex = 0.obs;

  // 每个category的题目列表 (key: category, value: subjects)
  final RxMap<int, List<SubjectModel>> categorySubjects = <int, List<SubjectModel>>{}.obs;

  // 每个category的总数 (key: category, value: total)
  final RxMap<int, int> categoryTotals = <int, int>{}.obs;

  // 每个category的当前页码 (key: category, value: page)
  final RxMap<int, int> categoryPages = <int, int>{}.obs;

  // 每页数量
  final int pageSize = 20;

  // 加载状态
  final RxBool isLoading = false.obs;
  final RxBool isCategoriesLoading = true.obs;

  // 错误信息
  final RxString errorMessage = ''.obs;

  // 展开的题目答案（记录题目ID）
  final RxSet<int> expandedAnswers = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  /// 加载Categories
  Future<void> loadCategories() async {
    try {
      isCategoriesLoading.value = true;
      final data = await SubjectApi.getSubjectCategories();

      if (data != null && data is List && data.isNotEmpty) {
        categories.value = data.cast<int>();

        // 初始化TabController
        tabController?.dispose();
        tabController = TabController(
          length: categories.length,
          vsync: this,
        );

        // 监听tab切换
        tabController?.addListener(() {
          if (!tabController!.indexIsChanging) {
            currentCategoryIndex.value = tabController!.index;
            final category = categories[currentCategoryIndex.value];
            if (!categorySubjects.containsKey(category)) {
              loadSubjects(category);
            }
          }
        });

        // 加载第一个category的题目
        if (categories.isNotEmpty) {
          loadSubjects(categories[0]);
        }
      } else {
        errorMessage.value = '未找到题库分类';
      }
    } catch (e) {
      debugPrint('加载题库分类失败: $e');
      errorMessage.value = '加载题库分类失败';
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  /// 加载指定category的题目
  Future<void> loadSubjects(int category, {int? page}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final currentPage = page ?? categoryPages[category] ?? 1;

      final data = await SubjectApi.getSubjectList(
        subjectCategory: category,
        page: currentPage,
        pageSize: pageSize,
      );

      if (data != null) {
        categoryTotals[category] = data['total'] ?? 0;
        categoryPages[category] = currentPage;

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

          categorySubjects[category] = decryptedSubjects;
        } else {
          categorySubjects[category] = [];
        }

        // 清空展开状态
        expandedAnswers.clear();
      }
    } catch (e) {
      debugPrint('加载题目失败: $e');
      errorMessage.value = '加载题目失败';
      categorySubjects[category] = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// 获取当前category的题目列表
  List<SubjectModel> get currentSubjects {
    if (categories.isEmpty) return [];
    final category = categories[currentCategoryIndex.value];
    return categorySubjects[category] ?? [];
  }

  /// 获取当前category的总数
  int get currentTotal {
    if (categories.isEmpty) return 0;
    final category = categories[currentCategoryIndex.value];
    return categoryTotals[category] ?? 0;
  }

  /// 获取当前category的页码
  int get currentPage {
    if (categories.isEmpty) return 1;
    final category = categories[currentCategoryIndex.value];
    return categoryPages[category] ?? 1;
  }

  /// 获取总页数
  int get totalPages {
    if (currentTotal == 0) return 0;
    return (currentTotal / pageSize).ceil();
  }

  /// 切换答案展开状态
  void toggleAnswer(int id) {
    if (expandedAnswers.contains(id)) {
      expandedAnswers.remove(id);
    } else {
      expandedAnswers.add(id);
    }
  }

  /// 上一页
  void previousPage() {
    if (currentPage > 1) {
      final category = categories[currentCategoryIndex.value];
      loadSubjects(category, page: currentPage - 1);
    }
  }

  /// 下一页
  void nextPage() {
    if (currentPage < totalPages) {
      final category = categories[currentCategoryIndex.value];
      loadSubjects(category, page: currentPage + 1);
    }
  }

  /// 跳转到指定页
  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      final category = categories[currentCategoryIndex.value];
      loadSubjects(category, page: page);
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
      
      // 重新加载当前category的题目以获取最新的平均评分
      final category = categories[currentCategoryIndex.value];
      loadSubjects(category, page: currentPage);
    } catch (e) {
      debugPrint('评分失败: $e');
      '评分失败'.toHint();
    }
  }

  /// 刷新当前category的题目
  @override
  void refresh() {
    if (categories.isNotEmpty) {
      final category = categories[currentCategoryIndex.value];
      loadSubjects(category, page: currentPage);
    }
  }

  @override
  void onClose() {
    tabController?.dispose();
    super.onClose();
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
