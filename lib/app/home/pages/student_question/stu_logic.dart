import 'package:hongshi_admin/ex/ex_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hongshi_admin/api/student_api.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import '../../../../api/institution_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import 'que_logic.dart';

class StuLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;
  final qLogic = Get.put(QueLogic());

  final GlobalKey<SuggestionTextFieldState> institutionTextFieldKey =
      GlobalKey<SuggestionTextFieldState>();

  // 当前编辑的题目数据
  var currentEditStudent = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  Rx<String> selectedInstitutionId = "0".obs;

  final name = ''.obs;
  final institutionId = ''.obs;
  final teacher = ''.obs;
  final createTime = ''.obs;

  final uName = ''.obs;
  final uInstitutionId = ''.obs;
  final uInstitutionName = ''.obs;
  final uTeacher = ''.obs;
  final uCreateTime = ''.obs;

  void find(int newSize, int newPage) {
    size.value = newSize;
    page.value = newPage;
    list.clear();
    selectedRows.clear();
    loading.value = true;
    qLogic.selectedStudentId.value = "0";
    qLogic.findForStudent(newSize, newPage);
    qLogic.enableRowSelection();
    // 打印调用堆栈
    try {
      StudentApi.studentList(params: {
        "pageSize": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "institution_id": (selectedInstitutionId.value.toString() ?? ""),
      }).then((value) async {
        if (value != null && value["list"] != null) {
          total.value = value["total"] ?? 0;
          list.assignAll((value["list"] as List<dynamic>).toListMap());
          await Future.delayed(const Duration(milliseconds: 300));
          loading.value = false;
        } else {
          loading.value = false;
          "未获取到考生数据".toHint();
        }
      }).catchError((error) {
        loading.value = false;
        print("获取考生列表失败: $error");
        "获取考生列表失败: $error".toHint();
      });
    } catch (e) {
      loading.value = false;
      print("获取考生列表失败: $e");
      "获取考生列表失败: $e".toHint();
    }
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    super.onInit();
    find(size.value,
        page.value); // Fetch and populate student data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 50),
      ColumnData(title: "姓名", key: "name", width: 80),
      ColumnData(title: "电话", key: "phone", width: 120),
      ColumnData(title: "密码", key: "password", width: 0),
      ColumnData(title: "机构名称", key: "institution_name", width: 100),
      ColumnData(title: "班级名称", key: "class_name", width: 100),
      ColumnData(title: "考生编码", key: "question_code", width: 0),
      ColumnData(title: "岗位代码", key: "job_code", width: 100),
      ColumnData(title: "岗位名称", key: "job_name", width: 150),
      ColumnData(title: "到期时间", key: "expire_time", width: 0),
    ];
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
    find(size.value, page.value);
  }

  void toggleSelectAll() {
    selectedRows.clear();
  }

  Future<void> toggleSelect(int id) async {
    if (selectedRows.contains(id)) {
      // 当前行已被选中，取消选中
      selectedRows.remove(id);
      selectedRows.clear();
      qLogic.selectedRows.clear();
      qLogic.selectedStudentId.value = "0";
      await qLogic.findForStudent(qLogic.size.value, qLogic.page.value);
      qLogic.enableRowSelection();
    } else {
      // 当前行未被选中，选中
      selectedRows.clear();
      selectedRows.add(id);
      qLogic.selectedStudentId.value = id.toString();
      await qLogic.findForStudent(qLogic.size.value, qLogic.page.value);
      qLogic.disableRowSelection();
    }
  }

  void reset() {
    institutionTextFieldKey.currentState?.reset();
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
      qLogic.enableRowSelection();
      grayButtonStates[id]!.value = true;
      redButtonStates[id]!.value = true;
    } else {
      "请先选择要操作的考生".toHint();
    }
  }

  void grayButtonAction(int studentId) {
    if (!grayButtonStates[studentId]!.value) {
      return;
    }
    print("灰色按钮点击");
    qLogic.findForStudent(qLogic.size.value, qLogic.page.value);
    qLogic.disableRowSelection();
    blueButtonStates[studentId]!.value = true;
    grayButtonStates[studentId]!.value = false;
    redButtonStates[studentId]!.value = false;
  }
}
