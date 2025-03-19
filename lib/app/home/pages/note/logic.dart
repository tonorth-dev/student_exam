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
  final loading = false.obs;
  final total = 0.obs;
  final page = 1.obs;
  final size = 15.obs;
  final searchText = ''.obs;
  final RxList<Map<String, dynamic>> list = <Map<String, dynamic>>[].obs;
  final RxSet<String> expandedBookIds = <String>{}.obs;
  final RxSet<String> selectedBookIds = <String>{}.obs;
  final searchController = TextEditingController();

  final ValueNotifier<dynamic> selectedLevel1 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel2 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel3 = ValueNotifier(null);

  final RxString selectedKey = ''.obs;
  final RxList<String> expandedKeys = <String>[].obs;
  final selectedPdfUrl = RxnString("");
  final currentEditNote = RxMap<String, dynamic>({}).obs;

  final RxString selectedNoteId =
      '0'.obs; // To track which note's directory we are viewing

  var isLoading = false.obs;

  final GlobalKey<CascadingDropdownFieldState> majorDropdownKey =
      GlobalKey<CascadingDropdownFieldState>();

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void fetchData() async {
    try {
      BookApi.bookList({
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
      }).then((value) async {
        if (value != null && value["list"] != null) {
          list.value = (value["list"] as List).map((item) => 
            Map<String, dynamic>.from(item as Map)).toList();
        }
      });
    } catch (e) {
      print('获取题本错误: $e');
    }
  }

  void onSearchChanged(String value) {
    searchText.value = value;
  }

  void onSearch() {
    final searchTerm = searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      fetchData();
      return;
    }

    final filteredList = list.where((book) {
      return book['name'].toLowerCase().contains(searchTerm) ||
          book['major_name'].toLowerCase().contains(searchTerm);
    }).toList();

    list.value = filteredList;
  }

  void toggleExpand(dynamic bookId) {
    final id = bookId.toString();
    if (expandedBookIds.contains(id)) {
      expandedBookIds.remove(id);
    } else {
      expandedBookIds.add(id);
    }
  }

  void toggleSelect(String bookId) {
    if (selectedBookIds.contains(bookId)) {
      selectedBookIds.remove(bookId);
    } else {
      selectedBookIds.add(bookId);
    }
  }

  void downloadBook(Map<String, dynamic> book) {
    print('Downloading book: ${book['name']}');
  }

  void previewBook(Map<String, dynamic> book) {
    print('Previewing book: ${book['name']}');
  }

  var columns = <ColumnData>[];

  @override
  void refresh() {
    fetchData();
  }

  void reset() {
    majorDropdownKey.currentState?.reset();
    searchText.value = '';
    selectedBookIds.clear();

    fetchData();
  }

  void updatePdfUrl(String url) {
    if (url.isEmpty) {
      selectedPdfUrl.value = "";
      return;
    }
    selectedPdfUrl.value = "${ConfigUtil.ossUrl}$url";
  }

  Future<void> loadAndUpdatePdfUrl(int id) async {
    final response = await BookApi.generateBook(id, isTeacher: true);

    if (!response['url'].isEmpty) {
      selectedPdfUrl.value = "${ConfigUtil.ossUrl}${response['url']}";
    }
  }

  void selectBook(Map<String, dynamic> book) {
    final id = book['id'].toString();
    selectedBookIds.clear();
    selectedBookIds.add(id);
  }

  bool isBookSelected(Map<String, dynamic> book) {
    return selectedBookIds.contains(book['id']);
  }
}
