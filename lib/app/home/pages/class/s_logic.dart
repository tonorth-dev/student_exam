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
import '../../../../api/institution_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';

class SLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;

  final GlobalKey<SuggestionTextFieldState> institutionTextFieldKey = GlobalKey<SuggestionTextFieldState>();
  Rx<String> selectedInstitutionId = "0".obs;

  // 当前编辑的题目数据
  var currentEditStudent = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  final ValueNotifier<dynamic> selectedLevel1 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel2 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel3 = ValueNotifier(null);

  // 专业列表数据
  List<Map<String, dynamic>> classesList = [];
  Map<String, List<Map<String, dynamic>>> subClassesMap = {};
  Map<String, List<Map<String, dynamic>>> subSubClassesMap = {};
  List<Map<String, dynamic>> level1Items = [];
  Map<String, List<Map<String, dynamic>>> level2Items = {};
  Map<String, List<Map<String, dynamic>>> level3Items = {};
  Rx<String> selectedClassesId = "0".obs;
  var all = "0";

  // Maps for reverse lookup
  Map<String, String> level3IdToLevel2Id = {};
  Map<String, String> level2IdToLevel1Id = {};

  String getLevel2IdFromLevel3Id(String thirdLevelId) {
    return level3IdToLevel2Id[thirdLevelId] ?? '';
  }

  String getLevel1IdFromLevel2Id(String secondLevelId) {
    return level2IdToLevel1Id[secondLevelId] ?? '';
  }

  Future<List<Map<String, dynamic>>> find(int newSize, int newPage) async {
    size.value = newSize;
    page.value = newPage;
    list.clear();
    selectedRows.clear();
    loading.value = true;
    // 打印调用堆栈
    try {
      var response = await StudentApi.studentList(params: {
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "class_id": (selectedClassesId.value.toString() ?? ""),
        "institution_id": (selectedInstitutionId.value.toString() ?? ""),
        "all": all ?? "0",
      });

      if (response != null && response["list"] != null) {
        total.value = response["total"] ?? 0;
        list.assignAll((response["list"] as List<dynamic>).toListMap());

        await Future.delayed(const Duration(milliseconds: 300));
        loading.value = false;
        return list;
      } else {
        loading.value = false;
        "未获取到岗位数据".toHint();
        return [];
      }
    } catch (e) {
      loading.value = false;
      print("获取岗位列表失败: $e");
      "获取岗位列表失败: $e".toHint();
      return [];
    }
  }

  Future<void> findForClasses(int newSize, int newPage) async {
    all = selectedClassesId.value.toInt() > 0 ? "1" : "0";
    List<Map<String, dynamic>> items = await find(newSize, newPage);
    for (var item in items) {
      if (item['class_sorted'] == 1) {
        toggleSelect(item['id'], isForce: true);
      }
    }
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    super.onInit(); // Fetch and populate classes data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 50),
      ColumnData(title: "姓名", key: "name", width: 80),
      ColumnData(title: "电话", key: "phone", width: 120),
      ColumnData(title: "密码", key: "password", width: 150),
      ColumnData(title: "机构名称", key: "institution_name", width: 120),
      ColumnData(title: "班级名称", key: "class_name", width: 120),
      ColumnData(title: "岗位编码", key: "job_code", width: 120),
      ColumnData(title: "职位名称", key: "job_name", width: 150),
      ColumnData(title: "到期时间", key: "expire_time", width: 0),
    ];

    // 初始化数据
    // find(size.value, page.value);
  }

  Future<List<Map<String, dynamic>>> fetchInstructions(String query) async {
    print("query:$query");
    try {
      final response = await InstitutionApi.institutionList(params: {
        "pageSize": 10,
        "page": 1,
        "keyword": query ?? "",
      });
      var data = response['list'];
      print("response: $data");
      // 检查数据是否为 List
      if (data is List) {
        final List<Map<String, dynamic>> suggestions = data.map((item) {
          // 检查每个 item 是否包含 'name' 和 'id' 字段
          if (item is Map && item.containsKey('name') && item.containsKey('id')) {
            return {
              'name': item['name'],
              'id': item['id'].toString(),
            };
          } else {
            throw FormatException('Invalid item format: $item');
          }
        }).toList();
        print("suggestions： $suggestions");
        return suggestions;
      } else {
        // Handle the case where data is not a List
        return [];
      }
    } catch (e) {
      // Handle any exceptions that are thrown
      print('Error fetching instructions: $e');
      return [];
    }
  }

  @override
  void refresh() {
    findForClasses(size.value, page.value);
  }

  void delete(Map<String, dynamic> d, int index) {
    try {
      StudentApi.studentDelete(d["id"].toString()).then((value) {
        list.removeAt(index);
      }).catchError((error) {
        "删除失败: $error".toHint();
      });
    } catch (e) {
      "删除失败: $e".toHint();
    }
  }

  void batchDelete(List<int> ids) {
    try {
      List<String> idsStr = ids.map((id) => id.toString()).toList();
      if (idsStr.isEmpty) {
        "请先选择要删除的试题".toHint();
        return;
      }
      StudentApi.studentDelete(idsStr.join(",")).then((value) {
        "批量删除成功!".toHint();
        selectedRows.clear();
        refresh();
      }).catchError((error) {
        "批量删除失败: $error".toHint();
      });
    } catch (e) {
      "批量删除失败: $e".toHint();
    }
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

  void reset() {
    institutionTextFieldKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    findForClasses(size.value, page.value);
  }

  var isRowsSelectable = false.obs; // 控制行是否可被选中

  void enableRowSelection() {
    isRowsSelectable.value = true;
  }

  void disableRowSelection() {
    isRowsSelectable.value = false;
  }
}
