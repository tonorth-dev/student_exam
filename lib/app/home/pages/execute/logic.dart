import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:hongshi_admin/ex/ex_list.dart';
import 'package:get/get.dart';
import 'package:hongshi_admin/component/table/table_data.dart';
import 'package:hongshi_admin/api/execute_api.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:hongshi_admin/component/form/enum.dart';
import 'package:hongshi_admin/component/form/form_data.dart';

class ExecuteLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 0;
  var page = 0;
  var loading = false.obs;
  RxList<int> selectedRows = <int>[].obs;
  RxInt selectedRowIndex = RxInt(-1);
  Rx<String?> selectedMajor = '全部专业'.obs;
  Rx<String?> selectedQuestionType = '全部题型'.obs;
  List<String> majorList = ['全部专业', '计算机科学与技术', '国际关系', '教育学'];  // 根据实际情况填充
  List<String> questionTypeList = ['全部题型', '综合', '专业方向', '基础方向'];  // 根据实际情况填充
  void applyFilters() { /* 实现筛选逻辑 */ }

  void find(int size, int page) {
    this.size = size;
    this.page = page;
    list.clear();
    loading.value = true;
    ExecuteApi.executeList(params: {
      "size": size,
      "page": page,
    }).then((value) async {
      total.value = value["total"];
      list.addAll((value["list"] as List<dynamic>).toListMap());
      list.refresh();
      print('execute Data loaded: ${list}');
      await Future.delayed(const Duration(milliseconds: 300));
      loading.value = false;
    });
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    super.onInit();
    columns = [
      ColumnData(title: "ID", key: "id", width: 80),
      ColumnData(title: "名称", key: "name"),
      ColumnData(title: "开始时间", key: "start_time"),
      ColumnData(title: "结束时间", key: "end_time"),
      ColumnData(title: "题目类型", key: "question_type"),
      ColumnData(title: "答题时间(分钟)", key: "answer_time"),
      ColumnData(title: "题目难度", key: "question_level"),
      ColumnData(title: "班级ID", key: "class_id"),
      ColumnData(title: "班级名称", key: "class_name"),
      ColumnData(title: "执行状态", key: "status_name"),
      ColumnData(title: "创建时间", key: "created_time"),
      ColumnData(title: "执行明细", key: "ext_questions_json"),  // 添加额外题目字段
    ];
  }

  var form = FormDto(labelWidth: 100, columns: [
    FormColumnDto(
      label: "名称",
      key: "name",
      placeholder: "请输入计划名称",
    ),
    FormColumnDto(
      label: "开始时间",
      key: "start_time",
      placeholder: "请选择开始时间",
      type: FormColumnEnum.datetime,
    ),
    FormColumnDto(
      label: "结束时间",
      key: "end_time",
      placeholder: "请选择结束时间",
      type: FormColumnEnum.datetime,
    ),
    FormColumnDto(
      label: "题目类型",
      key: "question_type",
      placeholder: "请选择题目类型",
      type: FormColumnEnum.select,
      options: [
        {"value": "综合", "label": "综合"},
        {"value": "专业基础", "label": "专业基础"},
        {"value": "专业通识", "label": "专业通识"},
        {"value": "求职动机", "label": "求职动机"},
      ],
    ),
    FormColumnDto(
      label: "答题时间",
      key: "answer_time",
      placeholder: "请输入答题时间（分钟）",
      type: FormColumnEnum.number,
    ),
    FormColumnDto(
      label: "题目难度",
      key: "question_level",
      placeholder: "请选择题目难度",
      type: FormColumnEnum.select,
      options: [
        {"value": "低", "label": "低"},
        {"value": "中", "label": "中"},
        {"value": "高", "label": "高"},
      ],
    ),
  ]);

  void add() {
    form.add(
        reset: true,
        submit: (data) => {
              ExecuteApi.executeInsert(params: data).then((value) {
                "插入成功!".toHint();
                find(size, page);
                Get.back();
              })
            });
  }

  void modify(Map<String, dynamic> d, int index) {
    form.data = d;
    form.edit(
        submit: (data) => {
              ExecuteApi.executeUpdate(params: data).then((value) {
                "更新成功!".toHint();
                list.removeAt(index);
                list.insert(index, data);
                Get.back();
              })
            });
  }

  void delete(Map<String, dynamic> d, int index) {
    ExecuteApi.executeDelete(params: {"id": d["id"]}).then((value) {
      list.removeAt(index);
    });
  }

  void batchDelete(List<int> d) {
    print(List);
  }

  void search(String key) {
    ExecuteApi.executeSearch(params: {"key": key}).then((value) {
      refresh();
    });
  }

  void refresh() {
    find(size, page);
  }

  Future<void> exportCurrentPageToCSV() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null) return;

    List<List<dynamic>> rows = [];
    rows.add(columns.map((column) => column.title).toList());

    for (var item in list) {
      rows.add(columns.map((column) => item[column.key]).toList());
    }

    String csv = const ListToCsvConverter().convert(rows);
    File('$directory/executes_current_page.csv').writeAsStringSync(csv);
    "导出当前页成功!".toHint();
  }

  Future<void> exportAllToCSV() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null) return;

    List<Map<String, dynamic>> allItems = [];
    int currentPage = 1;
    int pageSize = 100;

    while (true) {
      var response = await ExecuteApi.executeList(params: {
        "size": pageSize,
        "page": currentPage,
      });

      allItems.addAll((response["list"] as List<dynamic>).toListMap());

      if (allItems.length >= response["total"]) break;
      currentPage++;
    }

    List<List<dynamic>> rows = [];
    rows.add(columns.map((column) => column.title).toList());

    for (var item in allItems) {
      rows.add(columns.map((column) => item[column.key]).toList());
    }

    String csv = const ListToCsvConverter().convert(rows);
    File('$directory/executes_all_pages.csv').writeAsStringSync(csv);
    "导出全部成功!".toHint();
  }

  void importFromCSV() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) {
      PlatformFile file = result.files.first;
      String content = utf8.decode(file.bytes!);

      List<List<dynamic>> rows = const CsvToListConverter().convert(content);
      rows.removeAt(0); // 移除表头

      for (var row in rows) {
        Map<String, dynamic> data = {};
        for (int i = 0; i < columns.length; i++) {
          data[columns[i].key] = row[i];
        }
        ExecuteApi.executeInsert(params: data).then((value) {
          "导入成功!".toHint();
          find(size, page);
        }).catchError((error) {
          "导入失败: $error".toHint();
        });
      }
    }
  }

  void toggleSelectAll() {
    selectedRows.length == list.length
        ? selectedRows.clear()
        : selectedRows.addAll(list.map((item) => item['id']));
  }

  void toggleSelect(int index) {
    selectedRows.contains(index)
        ? selectedRows.remove(index)
        : selectedRows.add(index);
  }

  void selectRow(int index) {
    selectedRowIndex.value = index;
    selectedRows.clear();
    if (index >= 0 && index < list.length) {
      selectedRows.add(list[index]['id']);
    }
  }

  final selectedExecuteId = RxnString();

  void selectExecute(String? id) {
    selectedExecuteId.value = id;
  }
}
