import 'package:admin_flutter/ex/ex_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin_flutter/api/major_api.dart';
import 'package:admin_flutter/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../api/job_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import 'j_logic.dart';

class MLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;
  final jLogic = Get.put(JLogic());

  final GlobalKey<CascadingDropdownFieldState> majorDropdownKey =
  GlobalKey<CascadingDropdownFieldState>();
  final GlobalKey<DropdownFieldState> cateDropdownKey =
  GlobalKey<DropdownFieldState>();
  final GlobalKey<DropdownFieldState> levelDropdownKey =
  GlobalKey<DropdownFieldState>();
  final GlobalKey<DropdownFieldState> statusDropdownKey =
  GlobalKey<DropdownFieldState>();

  // 当前编辑的题目数据
  var currentEditMajor = RxMap<String, dynamic>({}).obs;
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

  final firstLevelCategory = ''.obs;
  final secondLevelCategory = ''.obs;
  final majorName = ''.obs;
  final year = ''.obs;
  final createTime = ''.obs;
  final updateTime = ''.obs;

  final uFirstLevelCategory = ''.obs;
  final uSecondLevelCategory = ''.obs;
  final uMajorName = ''.obs;
  final uYear = ''.obs;
  final uCreateTime = ''.obs;
  final uUpdateTime = ''.obs;


  // Maps for reverse lookup
  Map<String, String> level3IdToLevel2Id = {};
  Map<String, String> level2IdToLevel1Id = {};

  Future<void> fetchMajors() async {
    try {
      var response =
      await MajorApi.majorList(params: {'pageSize': 3000, 'page': 1});
      if (response != null && response["total"] > 0) {
        var dataList = response["list"] as List<dynamic>;

        // Clear existing data to avoid duplicates
        majorList.clear();
        majorList.add({'id': '0', 'name': '全部专业'});
        subMajorMap.clear();
        subSubMajorMap.clear();
        level1Items.clear();
        level2Items.clear();
        level3Items.clear();

        // Track the generated IDs for first and second levels
        Map<String, String> firstLevelIdMap = {};
        Map<String, String> secondLevelIdMap = {};

        for (var item in dataList) {
          String firstLevelName = item["first_level_category"];
          String secondLevelName = item["second_level_category"];
          String thirdLevelId = item["id"].toString();
          String thirdLevelName = item["major_name"];

          // Generate unique IDs based on name for first-level and second-level categories
          String firstLevelId = firstLevelIdMap.putIfAbsent(
              firstLevelName, () => firstLevelIdMap.length.toString());
          String secondLevelId = secondLevelIdMap.putIfAbsent(
              secondLevelName, () => secondLevelIdMap.length.toString());

          // Add first-level category if it doesn't exist
          if (!majorList.any((m) => m['name'] == firstLevelName)) {
            majorList.add({'id': firstLevelId, 'name': firstLevelName});
            level1Items.add({'id': firstLevelId, 'name': firstLevelName});
            subMajorMap[firstLevelId] = [];
            level2Items[firstLevelId] = [];
          }

          // Add second-level category if it doesn't exist under this first-level category
          if (subMajorMap[firstLevelId]
              ?.any((m) => m['name'] == secondLevelName) !=
              true) {
            subMajorMap[firstLevelId]!
                .add({'id': secondLevelId, 'name': secondLevelName});
            level2Items[firstLevelId]
                ?.add({'id': secondLevelId, 'name': secondLevelName});
            subSubMajorMap[secondLevelId] = [];
            level3Items[secondLevelId] = [];
            level2IdToLevel1Id[secondLevelId] =
                firstLevelId; // Populate reverse lookup map
          }

          // Add third-level major if it doesn't exist under this second-level category
          if (subSubMajorMap[secondLevelId]
              ?.any((m) => m['name'] == thirdLevelName) !=
              true) {
            subSubMajorMap[secondLevelId]!
                .add({'id': thirdLevelId, 'name': thirdLevelName});
            level3Items[secondLevelId]
                ?.add({'id': thirdLevelId, 'name': thirdLevelName});
            level3IdToLevel2Id[thirdLevelId] =
                secondLevelId; // Populate reverse lookup map
          }
        }

        // Debug output
        print('majorList: $majorList');
        print('subMajorMap: $subMajorMap');
        print('subSubMajorMap: $subSubMajorMap');
        print('level1Items: $level1Items');
        print('level2Items: $level2Items');
        print('level3Items: $level3Items');
        print('level3IdToLevel2Id: $level3IdToLevel2Id');
        print('level2IdToLevel1Id: $level2IdToLevel1Id');
      } else {
        "2.获取专业列表失败".toHint();
      }
    } catch (e) {
      "2.获取专业列表失败: $e".toHint();
    }
  }

  String getLevel2IdFromLevel3Id(String thirdLevelId) {
    return level3IdToLevel2Id[thirdLevelId] ?? '';
  }

  String getLevel1IdFromLevel2Id(String secondLevelId) {
    return level2IdToLevel1Id[secondLevelId] ?? '';
  }

  void find(int newSize, int newPage) {
    size.value = newSize;
    page.value = newPage;
    list.clear();
    selectedRows.clear();
    loading.value = true;
    jLogic.selectedMajorId.value = "0";
    jLogic.findForMajor(newSize, newPage);
    jLogic.enableRowSelection();
    // 打印调用堆栈
    try {
      MajorApi.majorList(params: {
        "pageSize": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "major_id": (selectedMajorId.value.toString() ?? ""),
      }).then((value) async {
        if (value != null && value["list"] != null) {
          total.value = value["total"] ?? 0;
          list.assignAll((value["list"] as List<dynamic>).toListMap());
          await Future.delayed(const Duration(milliseconds: 300));
          loading.value = false;
        } else {
          loading.value = false;
          "未获取到岗位数据".toHint();
        }
      }).catchError((error) {
        loading.value = false;
        print("获取岗位列表失败: $error");
        "获取岗位列表失败: $error".toHint();
      });
    } catch (e) {
      loading.value = false;
      print("获取岗位列表失败: $e");
      "获取岗位列表失败: $e".toHint();
    }
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    super.onInit();
    find(size.value, page.value);// Fetch and populate major data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 80),
      ColumnData(title: "一级类别", key: "first_level_category", width: 120),
      ColumnData(title: "二级类别", key: "second_level_category", width: 120),
      ColumnData(title: "专业名称", key: "major_name", width: 120),
      ColumnData(title: "年份", key: "year", width: 0),
      ColumnData(title: "创建时间", key: "create_time", width: 0),
      ColumnData(title: "更新时间", key: "update_time", width: 0),
    ];
  }

  Future<bool> saveMajor() async {
    final firstLevelCategorySubmit = firstLevelCategory.value;
    final secondLevelCategorySubmit = secondLevelCategory.value;
    final majorNameSubmit = majorName.value;

    bool isValid = true;
    String errorMessage = "";

    if (majorNameSubmit.isEmpty) {
      isValid = false;
      errorMessage += "专业名称不能为空\n";
    }
    if (firstLevelCategorySubmit.isEmpty) {
      isValid = false;
      errorMessage += "请选择一级类别\n";
    }
    if (secondLevelCategorySubmit.isEmpty) {
      isValid = false;
      errorMessage += "请选择二级类别\n";
    }

    if (isValid) {
      try {
        Map<String, dynamic> params = {
          "first_level_category": firstLevelCategorySubmit,
          "second_level_category": secondLevelCategorySubmit,
          "major_name": majorNameSubmit,
        };

        dynamic result = await MajorApi.majorCreate(params);
        if (result['id'] > 0) {
          "创建专业成功".toHint();
          return true;
        } else {
          "创建专业失败".toHint();
          return false;
        }
      } catch (e) {
        print('Error: $e');
        "创建专业时发生错误：$e".toHint();
        return false;
      }
    } else {
      // 显示错误提示
      errorMessage.toHint();
      return false;
    }
  }


  Future<bool> updateMajor(int majorId) async {
    // 生成题本的逻辑
    final uFirstLevelCategorySubmit = uFirstLevelCategory.value;
    final uSecondLevelCategorySubmit = uSecondLevelCategory.value;
    final uMajorNameSubmit = uMajorName.value;

    bool isValid = true;
    String errorMessage = "";

    if (uMajorNameSubmit.isEmpty) {
      isValid = false;
      errorMessage += "专业名称不能为空\n";
    }
    if (uFirstLevelCategorySubmit.isEmpty) {
      isValid = false;
      errorMessage += "请选择一级类别\n";
    }
    if (uSecondLevelCategorySubmit.isEmpty) {
      isValid = false;
      errorMessage += "请选择二级类别\n";
    }

    if (isValid) {
      try {
        Map<String, dynamic> params = {
          "first_level_category": uFirstLevelCategorySubmit,
          "second_level_category": uSecondLevelCategorySubmit,
          "major_name": uMajorNameSubmit,
        };

        dynamic result = await MajorApi.majorUpdate(majorId, params);
        "更新专业成功".toHint();
        return true;
      } catch (e) {
        print('Error: $e');
        "更新专业时发生错误：$e".toHint();
        return false;
      }
    } else {
      // 显示错误提示
      errorMessage.toHint();
      return false;
    }
  }

  void delete(Map<String, dynamic> d, int index) {
    try {
      MajorApi.majorDelete(d["id"].toString()).then((value) {
        list.removeAt(index);
      }).catchError((error) {
        "删除失败: $error".toHint();
      });
    } catch (e) {
      "删除失败: $e".toHint();
    }
  }

  Future<void> audit(int majorId, int status) async {
    try {
      await MajorApi.auditMajor(majorId, status);
      "审核完成".toHint();
      find(size.value, page.value);
    } catch (e) {
      "审核失败: $e".toHint();
    }
  }

  @override
  void refresh() {
    find(size.value, page.value);
  }

  void batchDelete(List<int> ids) {
    try {
      List<String> idsStr = ids.map((id) => id.toString()).toList();
      if (idsStr.isEmpty) {
        "请先选择要删除的专业".toHint();
        return;
      }
      MajorApi.majorDelete(idsStr.join(",")).then((value) {
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
      selectedRows.clear();
  }

  Future<void> toggleSelect(int id) async {
    if (selectedRows.contains(id)) {
      // 当前行已被选中，取消选中
      selectedRows.remove(id);
      selectedRows.clear();
      jLogic.selectedRows.clear();
      jLogic.selectedMajorId.value = "0";
      jLogic.enableRowSelection();
    } else {
      // 当前行未被选中，选中
      selectedRows.clear();
      selectedRows.add(id);
      jLogic.selectedMajorId.value = id.toString();
      await jLogic.findForMajor(jLogic.size.value, jLogic.page.value);
      jLogic.disableRowSelection();
    }
  }

  void reset() {
    majorDropdownKey.currentState?.reset();
    cateDropdownKey.currentState?.reset();
    levelDropdownKey.currentState?.reset();
    statusDropdownKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    find(size.value, page.value);
  }

  final Map<int, ValueNotifier<bool>> blueButtonStates = {};
  final Map<int, ValueNotifier<bool>> grayButtonStates = {};
  final Map<int, ValueNotifier<bool>> redButtonStates = {};

  void blueButtonAction(int id) {
    if (!blueButtonStates[id]!.value) {
        return;
    }
    print("蓝色按钮点击");
    if (selectedRows.contains(id)) {
      blueButtonStates[id]!.value = false;
      jLogic.enableRowSelection();
      grayButtonStates[id]!.value = true;
      redButtonStates[id]!.value = true;
    } else {
      "请先选择要操作的专业".toHint();
    }
  }

  void grayButtonAction(int majorId) {
    if (!grayButtonStates[majorId]!.value) {
      return;
    }
    print("灰色按钮点击");
    jLogic.findForMajor(jLogic.size.value, jLogic.page.value);
    jLogic.disableRowSelection();
    blueButtonStates[majorId]!.value = true;
    grayButtonStates[majorId]!.value = false;
    redButtonStates[majorId]!.value = false;
  }

  Future<void> redButtonAction(int majorId) async {
    if (!grayButtonStates[majorId]!.value) {
      return;
    }
    print("红色按钮点击");
    List<String> hasMajorJobs = [];
    for (var id in jLogic.selectedRows) {
      // 找到与 id 匹配的岗位数据
      var job = jLogic.list.firstWhere((job) => job['id'] == id, orElse: () => {});
      if (job.isNotEmpty && job['major_id'] > 0 && job['major_id'] != majorId) {
        hasMajorJobs.add("岗位编码：${job['code']}，岗位名称：${job['name']}"); // 记录major_id > 0的数据
      }
    }

    if (hasMajorJobs.isNotEmpty) {
      // 生成确认弹窗
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            width: 800, // 设置你想要的宽度
            padding: EdgeInsets.all(16.0),
            child: AlertDialog(
              title: Text("确认"),
              content: Text("${hasMajorJobs.join("，")}，已经绑定在其它专业上，是否继续执行？"),
              actions: <Widget>[
                TextButton(
                  child: Text("取消"),
                  onPressed: () {
                    Get.back(); // 关闭对话框
                  },
                ),
                TextButton(
                  child: Text("确认"),
                  onPressed: () async {
                    // 用户确认后执行的操作
                    try {
                      await JobApi.jobUpdateMajor(jLogic.selectedRows, majorId);
                      "绑定成功".toHint();
                      jLogic.disableRowSelection();
                      blueButtonStates[majorId]!.value = true;
                      grayButtonStates[majorId]!.value = false;
                      redButtonStates[majorId]!.value = false;
                      jLogic.findForMajor(jLogic.size.value, jLogic.page.value);
                    } catch (e) {
                      print('Error: $e');
                      "绑定时发生错误：$e".toHint();
                    } finally {
                      Get.back(); // 确保对话框关闭
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // 如果没有符合条件的数据，则直接执行后续操作
      try {
        await JobApi.jobUpdateMajor(jLogic.selectedRows, majorId);
        "绑定成功".toHint();
        jLogic.disableRowSelection();
        blueButtonStates[majorId]!.value = true;
        grayButtonStates[majorId]!.value = false;
        redButtonStates[majorId]!.value = false;
        jLogic.findForMajor(jLogic.size.value, jLogic.page.value);
      } catch (e) {
        print('Error: $e');
        "绑定时发生错误：$e".toHint();
      }
      jLogic.disableRowSelection();
    }
  }

}
