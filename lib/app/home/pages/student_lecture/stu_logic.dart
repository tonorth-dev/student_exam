import 'package:hongshi_admin/ex/ex_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hongshi_admin/api/student_api.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../api/job_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import 'lec_logic.dart';

class StudLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;
  final lLogic = Get.put(LLogic());

  final GlobalKey<CascadingDropdownFieldState> studentDropdownKey =
  GlobalKey<CascadingDropdownFieldState>();
  final GlobalKey<DropdownFieldState> cateDropdownKey =
  GlobalKey<DropdownFieldState>();
  final GlobalKey<DropdownFieldState> levelDropdownKey =
  GlobalKey<DropdownFieldState>();
  final GlobalKey<DropdownFieldState> statusDropdownKey =
  GlobalKey<DropdownFieldState>();

  // 当前编辑的题目数据
  var currentEditStudent = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  final ValueNotifier<dynamic> selectedLevel1 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel2 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel3 = ValueNotifier(null);

  // 专业列表数据
  List<Map<String, dynamic>> studentList = [];
  Map<String, List<Map<String, dynamic>>> subStudentMap = {};
  Map<String, List<Map<String, dynamic>>> subSubStudentMap = {};
  List<Map<String, dynamic>> level1Items = [];
  Map<String, List<Map<String, dynamic>>> level2Items = {};
  Map<String, List<Map<String, dynamic>>> level3Items = {};
  Rx<String> selectedStudentId = "0".obs;

  final firstLevelCategory = ''.obs;
  final secondLevelCategory = ''.obs;
  final studentName = ''.obs;
  final year = ''.obs;
  final createTime = ''.obs;
  final updateTime = ''.obs;

  final uFirstLevelCategory = ''.obs;
  final uSecondLevelCategory = ''.obs;
  final uStudentName = ''.obs;
  final uYear = ''.obs;
  final uCreateTime = ''.obs;
  final uUpdateTime = ''.obs;


  // Maps for reverse lookup
  Map<String, String> level3IdToLevel2Id = {};
  Map<String, String> level2IdToLevel1Id = {};

  Future<void> fetchStudents() async {
    try {
      var response =
      await StudentApi.studentList(params: {'pageSize': 3000, 'page': 1});
      if (response != null && response["total"] > 0) {
        var dataList = response["list"] as List<dynamic>;

        // Clear existing data to avoid duplicates
        studentList.clear();
        studentList.add({'id': '0', 'name': '全部专业'});
        subStudentMap.clear();
        subSubStudentMap.clear();
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
          String thirdLevelName = item["student_name"];

          // Generate unique IDs based on name for first-level and second-level categories
          String firstLevelId = firstLevelIdMap.putIfAbsent(
              firstLevelName, () => firstLevelIdMap.length.toString());
          String secondLevelId = secondLevelIdMap.putIfAbsent(
              secondLevelName, () => secondLevelIdMap.length.toString());

          // Add first-level category if it doesn't exist
          if (!studentList.any((m) => m['name'] == firstLevelName)) {
            studentList.add({'id': firstLevelId, 'name': firstLevelName});
            level1Items.add({'id': firstLevelId, 'name': firstLevelName});
            subStudentMap[firstLevelId] = [];
            level2Items[firstLevelId] = [];
          }

          // Add second-level category if it doesn't exist under this first-level category
          if (subStudentMap[firstLevelId]
              ?.any((m) => m['name'] == secondLevelName) !=
              true) {
            subStudentMap[firstLevelId]!
                .add({'id': secondLevelId, 'name': secondLevelName});
            level2Items[firstLevelId]
                ?.add({'id': secondLevelId, 'name': secondLevelName});
            subSubStudentMap[secondLevelId] = [];
            level3Items[secondLevelId] = [];
            level2IdToLevel1Id[secondLevelId] =
                firstLevelId; // Populate reverse lookup map
          }

          // Add third-level student if it doesn't exist under this second-level category
          if (subSubStudentMap[secondLevelId]
              ?.any((m) => m['name'] == thirdLevelName) !=
              true) {
            subSubStudentMap[secondLevelId]!
                .add({'id': thirdLevelId, 'name': thirdLevelName});
            level3Items[secondLevelId]
                ?.add({'id': thirdLevelId, 'name': thirdLevelName});
            level3IdToLevel2Id[thirdLevelId] =
                secondLevelId; // Populate reverse lookup map
          }
        }

        // Debug output
        print('studentList: $studentList');
        print('subStudentMap: $subStudentMap');
        print('subSubStudentMap: $subSubStudentMap');
        print('level1Items: $level1Items');
        print('level2Items: $level2Items');
        print('level3Items: $level3Items');
        print('level3IdToLevel2Id: $level3IdToLevel2Id');
        print('level2IdToLevel1Id: $level2IdToLevel1Id');
      } else {
        "获取学生列表失败".toHint();
      }
    } catch (e) {
      "获取学生列表失败: $e".toHint();
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
    lLogic.selectedStudentId.value = "0";
    lLogic.findForStudent(newSize, newPage);
    lLogic.enableRowSelection();
    // 打印调用堆栈
    try {
      StudentApi.studentList(params: {
        "pageSize": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "student_id": (selectedStudentId.value.toString() ?? ""),
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
    find(size.value, page.value);// Fetch and populate student data on initialization

    columns = [
    ColumnData(title: "ID", key: "id", width: 50),
    ColumnData(title: "姓名", key: "name", width: 80),
    ColumnData(title: "电话", key: "phone", width: 0),
    ColumnData(title: "密码", key: "password", width: 0),
    ColumnData(title: "机构名称", key: "institution_name", width: 100),
    ColumnData(title: "班级名称", key: "class_name", width: 100),
    ColumnData(title: "考生编码", key: "question_code", width: 0),
    ColumnData(title: "岗位代码", key: "job_code", width: 0),
    ColumnData(title: "岗位名称", key: "job_name", width: 150),
    ColumnData(title: "到期时间", key: "expire_time", width: 0),
    ];
  }

  Future<bool> saveStudent() async {
    final firstLevelCategorySubmit = firstLevelCategory.value;
    final secondLevelCategorySubmit = secondLevelCategory.value;
    final studentNameSubmit = studentName.value;

    bool isValid = true;
    String errorMessage = "";

    if (studentNameSubmit.isEmpty) {
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
          "student_name": studentNameSubmit,
        };

        dynamic result = await StudentApi.studentCreate(params);
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


  Future<bool> updateStudent(int studentId) async {
    // 生成题本的逻辑
    final uFirstLevelCategorySubmit = uFirstLevelCategory.value;
    final uSecondLevelCategorySubmit = uSecondLevelCategory.value;
    final uStudentNameSubmit = uStudentName.value;

    bool isValid = true;
    String errorMessage = "";

    if (uStudentNameSubmit.isEmpty) {
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
          "student_name": uStudentNameSubmit,
        };

        dynamic result = await StudentApi.studentUpdate(studentId, params);
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
      StudentApi.studentDelete(d["id"].toString()).then((value) {
        list.removeAt(index);
      }).catchError((error) {
        "删除失败: $error".toHint();
      });
    } catch (e) {
      "删除失败: $e".toHint();
    }
  }

  Future<void> audit(int studentId, int status) async {
    try {
      await StudentApi.auditStudent(studentId, status);
      "审核完成".toHint();
      find(size.value, page.value);
    } catch (e) {
      "审核失败: $e".toHint();
    }
  }

  void generateAndOpenLink(
      BuildContext context, Map<String, dynamic> item) async {
    final url =
    Uri.parse('http://localhost:8888/static/h5/?studentId=${item['id']}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('无法打开链接')));
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
      selectedRows.clear();
  }

  Future<void> toggleSelect(int id) async {
    if (selectedRows.contains(id)) {
      // 当前行已被选中，取消选中
      selectedRows.remove(id);
      selectedRows.clear();
      lLogic.selectedRows.clear();
      lLogic.selectedStudentId.value = "0";
      lLogic.enableRowSelection();
    } else {
      // 当前行未被选中，选中
      selectedRows.clear();
      selectedRows.add(id);
      lLogic.selectedStudentId.value = id.toString();
      await lLogic.findForStudent(lLogic.size.value, lLogic.page.value);
      lLogic.disableRowSelection();
    }
  }

  void reset() {
    studentDropdownKey.currentState?.reset();
    cateDropdownKey.currentState?.reset();
    levelDropdownKey.currentState?.reset();
    statusDropdownKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    fetchStudents();
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
      lLogic.enableRowSelection();
      grayButtonStates[id]!.value = true;
      redButtonStates[id]!.value = true;
    } else {
      "请先选择要操作的专业".toHint();
    }
  }

  void grayButtonAction(int studentId) {
    if (!grayButtonStates[studentId]!.value) {
      return;
    }
    print("灰色按钮点击");
    lLogic.findForStudent(lLogic.size.value, lLogic.page.value);
    lLogic.disableRowSelection();
    blueButtonStates[studentId]!.value = true;
    grayButtonStates[studentId]!.value = false;
    redButtonStates[studentId]!.value = false;
  }

  Future<void> redButtonAction(int studentId) async {
    if (!grayButtonStates[studentId]!.value) {
      return;
    }
    print("红色按钮点击");
    List<String> hasStudentJobs = [];
    for (var id in lLogic.selectedRows) {
      // 找到与 id 匹配的岗位数据
      var job = lLogic.list.firstWhere((job) => job['id'] == id, orElse: () => {});
      if (job.isNotEmpty && job['student_id'] > 0 && job['student_id'] != studentId) {
        hasStudentJobs.add("岗位编码：${job['code']}，岗位名称：${job['name']}"); // 记录student_id > 0的数据
      }
    }

    if (hasStudentJobs.isNotEmpty) {
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
              content: Text("${hasStudentJobs.join("，")}，已经绑定在其它专业上，是否继续执行？"),
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
                      // await JobApi.jobUpdateStudent(lLogic.selectedRows, studentId);
                      // "绑定成功".toHint();
                      // lLogic.disableRowSelection();
                      // blueButtonStates[studentId]!.value = true;
                      // grayButtonStates[studentId]!.value = false;
                      // redButtonStates[studentId]!.value = false;
                      // lLogic.findForStudent(lLogic.size.value, lLogic.page.value);
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
        // await JobApi.jobUpdateStudent(lLogic.selectedRows, studentId);
        // "绑定成功".toHint();
        // lLogic.disableRowSelection();
        // blueButtonStates[studentId]!.value = true;
        // grayButtonStates[studentId]!.value = false;
        // redButtonStates[studentId]!.value = false;
        // lLogic.findForStudent(lLogic.size.value, lLogic.page.value);
      } catch (e) {
        print('Error: $e');
        "绑定时发生错误：$e".toHint();
      }
      lLogic.disableRowSelection();
    }
  }

}
