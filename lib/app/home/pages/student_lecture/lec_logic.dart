import 'package:hongshi_admin/ex/ex_list.dart';
import 'package:hongshi_admin/ex/ex_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hongshi_admin/api/lecture_api.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';

class LLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;

  // 当前编辑的题目数据
  var currentEditLecture = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  final ValueNotifier<dynamic> selectedLevel1 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel2 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel3 = ValueNotifier(null);

  // 专业列表数据
  Rx<String> selectedStudentId = "0".obs;
  var all = "0";

  final lectureCode = ''.obs;
  final lectureName = ''.obs;
  final lectureCate = ''.obs;
  final lectureDesc = ''.obs;
  final companyCode = ''.obs;
  final companyName = ''.obs;
  final enrollmentNum = 0.obs;
  final enrollmentRatio = ''.obs;
  final conditionSource = ''.obs;
  final conditionQualification = "".obs;
  final conditionDegree = "".obs;
  final conditionMajor = "".obs;
  final conditionExam = "".obs;
  final conditionOther = "".obs;
  final lectureCity = "".obs;
  final lecturePhone = "".obs;

  final uLectureCode = ''.obs;
  final uLectureName = ''.obs;
  final uLectureCate = ''.obs;
  final uLectureDesc = ''.obs;
  final uCompanyCode = ''.obs;
  final uCompanyName = ''.obs;
  final uEnrollmentNum = 0.obs;
  final uEnrollmentRatio = ''.obs;
  final uConditionSource = ''.obs;
  final uConditionQualification = "".obs;
  final uConditionDegree = "".obs;
  final uConditionMajor = "".obs;
  final uConditionExam = "".obs;
  final uConditionOther = "".obs;
  final uLectureCity = "".obs;
  final uLecturePhone = "".obs;

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
      var response = await LectureApi.lectureList({
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "student_id": (selectedStudentId.value.toString() ?? ""),
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

  var columns = <ColumnData>[];

  @override
  void onInit() {
    super.onInit(); // Fetch and populate major data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 40),
      ColumnData(title: "讲义名称", key: "name", width:200),
      ColumnData(title: "专业", key: "major_name", width:150),
      ColumnData(title: "岗位代码", key: "job_code", width:100),
      ColumnData(title: "岗位名称", key: "job_name", width:150),
      ColumnData(title: "排序", key: "sort", width:50),
      ColumnData(title: "创建者", key: "creator"),
      ColumnData(title: "讲义类别", key: "category"),
      ColumnData(title: "大小", key: "size"),
      ColumnData(title: "页数", key: "pagecount"),
      ColumnData(title: "状态", key: "status"),
      ColumnData(title: "创建时间", key: "created_time"),
    ];

    // 初始化数据
    // find(size.value, page.value);
  }

  @override
  void refresh() {
    findForStudent(size.value, page.value);
  }

  void delete(Map<String, dynamic> d, int index) {
    try {
      LectureApi.lectureDelete(d["id"].toString()).then((value) {
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
      LectureApi.lectureDelete(idsStr.join(",")).then((value) {
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
