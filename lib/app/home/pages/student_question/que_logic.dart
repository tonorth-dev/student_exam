import 'package:admin_flutter/app/home/pages/book/book.dart';
import 'package:admin_flutter/ex/ex_list.dart';
import 'package:admin_flutter/ex/ex_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin_flutter/api/student_api.dart';
import 'package:admin_flutter/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:admin_flutter/component/form/enum.dart';
import 'package:admin_flutter/component/form/form_data.dart';
import 'package:admin_flutter/component/dialog.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../api/classes_api.dart';
import '../../../../api/config_api.dart';
import '../../../../api/institution_api.dart';
import '../../../../api/major_api.dart';
import '../../../../api/question_api.dart';
import '../../../../api/topic_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';

class QueLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;

  // 当前编辑的题目数据
  var currentEditTopic = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  ValueNotifier<String?> selectedQuestionCate = ValueNotifier<String?>(null);
  ValueNotifier<String?> selectedQuestionLevel = ValueNotifier<String?>(null);
  ValueNotifier<String?> selectedQuestionStatus = ValueNotifier<String?>(null);
  RxList<Map<String, dynamic>> questionCate = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> questionLevel = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> questionStatus = <Map<String, dynamic>>[
    {'id': '0', 'name': '全部'},
    {'id': '1', 'name': '草稿'},
    {'id': '2', 'name': '生效中'},
    {'id': '4', 'name': '审核中'},
  ].obs;

  // 专业列表数据
  Rx<String> selectedStudentId = "0".obs;
  var all = "0";

  final topicTitle = ''.obs;
  ValueNotifier<String?> topicSelectedQuestionCate = ValueNotifier<String?>(null);
  ValueNotifier<String?> topicSelectedQuestionLevel = ValueNotifier<String?>(null);
  final topicSelectedMajorId = "".obs;
  final topicAnswer = "".obs;
  final topicAuthor = "".obs;
  final topicTag = "".obs;
  final topicStatus = 0.obs;

  final uTopicTitle = ''.obs;
  final uTopicSelectedQuestionCate = "".obs;
  final uTopicSelectedQuestionLevel = "".obs;
  final uTopicSelectedMajorId = "".obs;
  final uTopicAnswer = "".obs;
  final uTopicAuthor = "".obs;
  final uTopicTag = "".obs;
  final uTopicStatus = 0.obs;

  Future<void> fetchConfigs() async {
    try {
      var configData = await ConfigApi.configList();
      if (configData != null && configData.containsKey("list")) {
        final list = configData["list"] as List<dynamic>;
        final questionCateItem = list.firstWhere(
              (item) => item["name"] == "question_cate",
          orElse: () => null,
        );

        if (questionCateItem != null &&
            questionCateItem.containsKey("attr") &&
            questionCateItem["attr"].containsKey("cates")) {
          questionCate = RxList.from(questionCateItem["attr"]["cates"]);
        } else {
          print("配置数据中未找到 'question_cate' 或其 'cates' 属性");
          questionCate = RxList<Map<String, dynamic>>(); // 作为默认值，防止未初始化
        }

        final questionLevelItem = list.firstWhere(
              (item) => item["name"] == "question_level",
          orElse: () => null,
        );

        if (questionLevelItem != null &&
            questionLevelItem.containsKey("attr") &&
            questionLevelItem["attr"].containsKey("levels")) {
          questionLevel = RxList.from(questionLevelItem["attr"]["levels"]);
        } else {
          print("配置数据中未找到 'question_cate' 或其 'cates' 属性");
          questionLevel = RxList<Map<String, dynamic>>(); // 作为默认值，防止未初始化
        }
      } else {
        print("配置数据中未找到 'config' 或其 'list' 属性");
        questionCate = RxList<Map<String, dynamic>>();
      }
    } catch (e) {
      print('初始化 config 失败: $e');
      questionCate = RxList<Map<String, dynamic>>();
    }
  }

  Future<List<Map<String, dynamic>>> find(int newSize, int newPage) async {
    size.value = newSize;
    page.value = newPage;
    list.clear();
    loading.value = true;
    try {
      var response = await TopicApi.topicList({
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "cate": getSelectedCateId() ?? "",
        "level": getSelectedLevelId() ?? "",
        "status": selectedQuestionStatus.value.toString(),
        "student_id": (selectedStudentId.value.toString() ?? ""),
        "all": all ?? "0",
      });

      if (response != null && response["list"] != null) {
        total.value = response["total"] ?? 0;
        list.assignAll((response["list"] as List<dynamic>).toListMap());
        await Future.delayed(const Duration(milliseconds: 300));
        loading.value = false;
        return (response["list"] as List<dynamic>).cast<Map<String, dynamic>>();
      } else {
        loading.value = false;
        "未获取到题库数据".toHint();
        return [];
      }
    } catch (e) {
      loading.value = false;
      print("获取题库列表失败: $e");
      "获取题库列表失败: $e".toHint();
      return [];
    }
  }

  String? getSelectedCateId() {
    if (selectedQuestionCate.value == '全部题型') {
      return "";
    }
    return selectedQuestionCate.value?.toString() ?? "";
  }

  String? getSelectedLevelId() {
    if (selectedQuestionLevel.value == '全部难度') {
      return "";
    }
    return selectedQuestionLevel.value?.toString() ?? "";
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    fetchConfigs();
    ever(
      questionCate,
          (value) {
        if (questionCate.isNotEmpty) {
          // 当 questionCate 被赋值后再执行表单加载逻辑
          super.onInit();
          find(size.value, page.value);
        }
      },
    );

    columns = [
      ColumnData(title: "ID", key: "id", width: 80),
      ColumnData(title: "题型", key: "cate_name", width: 80),
      ColumnData(title: "难度", key: "level_name", width: 80),
      ColumnData(title: "题干", key: "title", width: 120),
      ColumnData(title: "答案", key: "answer", width: 200),
      ColumnData(title: "专业ID", key: "major_id",width: 80),
      ColumnData(title: "专业名称", key: "major_name",width: 80),
      ColumnData(title: "标签", key: "tag"),
      ColumnData(title: "录入人", key: "author"),
      ColumnData(title: "状态", key: "status_name"),
      ColumnData(title: "创建时间", key: "create_time"),
      ColumnData(title: "更新时间", key: "update_time"),
    ];

    // 初始化数据
    // find(size.value, page.value);
  }

  Future<void> findForStudent(int newSize, int newPage) async {
    all = selectedStudentId.value.toInt() > 0 ? "1" : "0";
    List<Map<String, dynamic>> items = await find(newSize, newPage);
    for (var item in items) {
      if (item['student_sorted'] == 1) {
        print(item['id']);
        toggleSelect(item['id'], isForce: true);
      }
    }
  }

  @override
  void refresh() {
    findForStudent(size.value, page.value);
  }

  void toggleSelect(int id, {bool isForce = false}) {
    if (isForce) {
      // 强制选中
      if (!selectedRows.contains(id)) {
        selectedRows.add(id);
      }
    } else {
      // 正常的选中/取消选中逻辑
      if (selectedRows.contains(id)) {
        // 当前行已被选中，取消选中
        selectedRows.remove(id);
      } else {
        // 当前行未被选中，选中
        selectedRows.add(id);
      }
    }
  }

  void toggleSelectAll() {
    if (selectedRows.length == list.length) {
      selectedRows.clear();
    } else {
      selectedRows.addAll(list.map((item) => item['id']));
    }
  }

  void reset() {
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    findForStudent(size.value, page.value);
  }

  var isRowsSelectable = false.obs; // 控制行是否可被选中

  void enableRowSelection() {
    isRowsSelectable.value = true;
  }

  void disableRowSelection() {
    isRowsSelectable.value = false;
  }
}
