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
import 'package:student_exam/app/data/book_model.dart';

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

  final searchController = TextEditingController();
  final bookList = <BookModel>[].obs;
  final expandedRows = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBooks();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    searchText.value = value;
  }

  void onSearch() {
    page.value = 1;
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      final response = await BookApi.bookList({
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value,
      });

      if (response != null && response['list'] != null) {
        final List<dynamic> list = response['list'];
        bookList.value = list.map((item) => BookModel.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error fetching books: $e');
      // 在界面上显示错误信息
      Get.snackbar(
        '错误',
        '获取题本列表失败',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void toggleExpand(int bookId) {
    if (expandedRows.contains(bookId)) {
      expandedRows.remove(bookId);
    } else {
      expandedRows.add(bookId);
    }
  }

  void downloadBook(BookModel book) {
    // TODO: 实现下载功能
    print('Downloading book: ${book.name}');
  }

  void previewBook(BookModel book) {
    // TODO: 实现预览功能
    print('Previewing book: ${book.name}');
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    super.onInit(); // Fetch and populate major data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 80),
      ColumnData(title: "题本名称", key: "name", width: 240),
      ColumnData(title: "专业", key: "major_name", width: 120),
      ColumnData(title: "难度", key: "level_name", width: 100),
      ColumnData(title: "试题数量", key: "questions_number", width: 60),
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
