import 'dart:io';

import 'package:student_exam/ex/ex_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_exam/ex/ex_hint.dart';
import 'package:student_exam/component/dialog.dart';
import '../../../../api/book_api.dart';
import '../../../../api/major_api.dart';
import '../../../../common/config_util.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';

class NoteLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;
  final RxString selectedKey = ''.obs; // 初始化为空字符串
  final RxList<String> expandedKeys = <String>[].obs;

  final RxString selectedNoteId = '0'
      .obs; // To track which note's directory we are viewing

  var isLoading = false.obs;


  final GlobalKey<CascadingDropdownFieldState> majorDropdownKey =
  GlobalKey<CascadingDropdownFieldState>();

  // 当前编辑的题目数据
  var currentEditNote = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  final selectedPdfUrl = RxnString("");

  final ValueNotifier<dynamic> selectedLevel1 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel2 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel3 = ValueNotifier(null);

  void find(int newSize, int newPage) {
    size.value = newSize;
    page.value = newPage;
    list.clear();
    selectedRows.clear();
    loading.value = true;
    // 打印调用堆栈
    try {
      BookApi.bookList({
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
      }).then((value) async {
        if (value != null && value["list"] != null) {
          total.value = value["total"] ?? 0;
          list.assignAll((value["list"] as List<dynamic>).toListMap());
          await Future.delayed(const Duration(milliseconds: 300));
          loading.value = false;
        } else {
          loading.value = false;
          "未获取到讲义数据".toHint();
        }
      }).catchError((error) {
        loading.value = false;
        print("获取讲义列表失败: $error");
        "获取讲义列表失败: $error".toHint();
      });
    } catch (e) {
      loading.value = false;
      print("获取讲义列表失败: $e");
      "获取讲义列表失败: $e".toHint();
    }
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    super.onInit(); // Fetch and populate major data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 80),
      ColumnData(title: "题本名称", key: "name", width: 120),
      ColumnData(title: "专业", key: "major_name", width: 150),
      ColumnData(title: "难度", key: "level_name", width: 80),
      ColumnData(title: "试题数量", key: "questions_number", width: 60),
      ColumnData(title: "创建时间", key: "create_time", width: 120),
    ];

    // 初始化数据
    // find(size.value, page.value);
  }

  @override
  void refresh() {
    find(size.value, page.value);
  }

  void toggleSelectAll() {
    if (selectedRows.length == list.length) {
      // 当前所有行都被选中，清空选中状态
      selectedRows.clear();
    } else {
      // 当前不是所有行都被选中，选择所有行
      selectedRows.assignAll(list.map((item) => item['id']));
    }
  }

  void toggleSelect(int id) {
    if (selectedRows.contains(id)) {
      // 当前行已被选中，取消选中
      selectedRows.remove(id);
    } else {
      // 当前行未被选中，选中
      selectedRows.add(id);
    }
  }

  void reset() {
    majorDropdownKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    find(size.value, page.value);
  }

  void updatePdfUrl(String url) {
    if (url.isEmpty) {
      selectedPdfUrl.value = "";
      debugPrint('Selected PDF URL updated: ${selectedPdfUrl.value}');
      return;
    }
    if (selectedPdfUrl.value != "${ConfigUtil.ossUrl}$url") {
      selectedPdfUrl.value = "${ConfigUtil.ossUrl}$url";
      debugPrint('Selected PDF URL updated: ${selectedPdfUrl.value}');
    }
  }

  Future<void> loadAndUpdatePdfUrl(int id) async {
    final response = await BookApi.generateBook(id, isTeacher: true);

    // 检查响应状态码
    if (!response['url'].isEmpty) {
      // 获取 PDF 文件的 URL
      selectedPdfUrl.value = "${ConfigUtil.ossUrl}${response['url']}";
    }
  }
}
