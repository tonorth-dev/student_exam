import 'package:admin_flutter/app/home/pages/book/book.dart';
import 'package:admin_flutter/ex/ex_list.dart';
import 'package:admin_flutter/ex/ex_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin_flutter/api/job_api.dart';
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
import '../../../../api/major_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';

class JLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;

  final GlobalKey<CascadingDropdownFieldState> majorDropdownKey =
      GlobalKey<CascadingDropdownFieldState>();
  final GlobalKey<DropdownFieldState> cateDropdownKey =
      GlobalKey<DropdownFieldState>();
  final GlobalKey<DropdownFieldState> levelDropdownKey =
      GlobalKey<DropdownFieldState>();
  final GlobalKey<DropdownFieldState> statusDropdownKey =
      GlobalKey<DropdownFieldState>();

  // 当前编辑的题目数据
  var currentEditJob = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  final ValueNotifier<dynamic> selectedLevel1 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel2 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel3 = ValueNotifier(null);

  // 专业列表数据
  List<Map<String, dynamic>> majorList = [];
  Map<String, List<Map<String, dynamic>>> subMajorMap = {};
  Map<String, List<Map<String, dynamic>>> subSubMajorMap = {};
  List<Map<String, dynamic>> level1Items = [];
  Map<String, List<Map<String, dynamic>>> level2Items = {};
  Map<String, List<Map<String, dynamic>>> level3Items = {};
  Rx<String> selectedMajorId = "0".obs;
  var all = "0";

  final jobCode = ''.obs;
  final jobName = ''.obs;
  final jobCate = ''.obs;
  final jobDesc = ''.obs;
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
  final jobCity = "".obs;
  final jobPhone = "".obs;

  final uJobCode = ''.obs;
  final uJobName = ''.obs;
  final uJobCate = ''.obs;
  final uJobDesc = ''.obs;
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
  final uJobCity = "".obs;
  final uJobPhone = "".obs;

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
      var response = await JobApi.jobList({
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "major_id": (selectedMajorId.value.toString() ?? ""),
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

  Future<void> findForMajor(int newSize, int newPage) async {
    all = selectedMajorId.value.toInt() > 0 ? "1" : "0";
    List<Map<String, dynamic>> items = await find(newSize, newPage);
    for (var item in items) {
      if (item['major_sorted'] == 1) {
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
      ColumnData(title: "ID", key: "id", width: 0),
      ColumnData(title: "岗位编码", key: "code", width: 100),
      ColumnData(title: "岗位名称", key: "name", width: 200),
      ColumnData(title: "岗位类别", key: "cate", width: 120),
      ColumnData(title: "从事工作", key: "desc", width: 0),
      ColumnData(title: "单位编码", key: "company_code", width: 100),
      ColumnData(title: "单位名称", key: "company_name", width: 120),
      ColumnData(title: "录取人数", key: "enrollment_num", width: 0),
      ColumnData(title: "录取比例", key: "enrollment_ratio", width: 0),
      ColumnData(title: "报考条件原文", key: "condition"),
      ColumnData(title: "报考条件", key: "condition_name"),
      ColumnData(title: "城市", key: "city"),
      ColumnData(title: "专业ID", key: "major_id", width: 0),
      ColumnData(title: "专业名称", key: "major_name", width: 100),
      ColumnData(title: "状态", key: "status"),
      ColumnData(title: "创建时间", key: "create_time"),
      ColumnData(title: "更新时间", key: "update_time"),
    ];

    // 初始化数据
    // find(size.value, page.value);
  }

  @override
  void refresh() {
    findForMajor(size.value, page.value);
  }

  void delete(Map<String, dynamic> d, int index) {
    try {
      JobApi.jobDelete(d["id"].toString()).then((value) {
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
      JobApi.jobDelete(idsStr.join(",")).then((value) {
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
    majorDropdownKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    findForMajor(size.value, page.value);
  }

  var isRowsSelectable = false.obs; // 控制行是否可被选中

  void enableRowSelection() {
    isRowsSelectable.value = true;
  }

  void disableRowSelection() {
    isRowsSelectable.value = false;
  }
}
