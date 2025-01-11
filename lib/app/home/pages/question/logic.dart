import 'package:admin_flutter/ex/ex_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin_flutter/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../../../api/config_api.dart';
import '../../../../api/major_api.dart';
import '../../../../api/topic_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class QuestionLogic extends GetxController {
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
  var currentEditQuestion = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  ValueNotifier<String?> selectedQuestionCate = ValueNotifier<String?>(null);
  ValueNotifier<String?> selectedQuestionLevel = ValueNotifier<String?>(null);
  ValueNotifier<String?> selectedQuestionStatus = ValueNotifier<String?>(null);
  RxList<Map<String, dynamic>> questionCate = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> questionLevel = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> questionStatus = <Map<String, dynamic>>[
    {'id': '0', 'name': '全部'},
    {'id': '1', 'name': '草稿'},
    {'id': '2', 'name': '生效中'},
    {'id': '4', 'name': '审核中'},
  ].obs;

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

  final questionTitle = ''.obs;
  ValueNotifier<String?> questionSelectedQuestionCate = ValueNotifier<String?>(null);
  ValueNotifier<String?> questionSelectedQuestionLevel = ValueNotifier<String?>(null);
  final questionSelectedMajorId = "".obs;
  final questionAnswer = "".obs;
  final questionAuthor = "".obs;
  final questionTag = "".obs;

  final uQuestionTitle = ''.obs;
  final uQuestionSelectedQuestionCate = "".obs;
  final uQuestionSelectedQuestionLevel = "".obs;
  final uQuestionSelectedMajorId = "".obs;
  final uQuestionAnswer = "".obs;
  final uQuestionAuthor = "".obs;
  final uQuestionTag = "".obs;
  final uQuestionStatus = 0.obs;

  Future<void> fetchConfigs() async {
    try {
      var configData = await ConfigApi.configList();
      if (configData != null && configData.containsKey("list")) {
        final list = configData["list"] as List<dynamic>;
        final questionCateItem = list.firstWhere(
          (item) => item["name"] == "question_cate",
          orElse: () => null,
        );

        if (questionCateItem != null &&
            questionCateItem.containsKey("attr") &&
            questionCateItem["attr"].containsKey("cates")) {
          questionCate = RxList.from(questionCateItem["attr"]["cates"]);
        } else {
          print("配置数据中未找到 'question_cate' 或其 'cates' 属性");
          questionCate = RxList<Map<String, dynamic>>(); // 作为默认值，防止未初始化
        }

        final questionLevelItem = list.firstWhere(
          (item) => item["name"] == "question_level",
          orElse: () => null,
        );

        if (questionLevelItem != null &&
            questionLevelItem.containsKey("attr") &&
            questionLevelItem["attr"].containsKey("levels")) {
          questionLevel = RxList.from(questionLevelItem["attr"]["levels"]);
        } else {
          print("配置数据中未找到 'question_cate' 或其 'cates' 属性");
          questionLevel = RxList<Map<String, dynamic>>(); // 作为默认值，防止未初始化
        }
      } else {
        print("配置数据中未找到 'config' 或其 'list' 属性");
        questionCate = RxList<Map<String, dynamic>>();
      }
    } catch (e) {
      print('初始化 config 失败: $e');
      questionCate = RxList<Map<String, dynamic>>();
    }
  }

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
        print("questionLevel:$questionLevel");
        print('majorList: $majorList');
        print('subMajorMap: $subMajorMap');
        print('subSubMajorMap: $subSubMajorMap');
        print('level1Items: $level1Items');
        print('level2Items: $level2Items');
        print('level3Items: $level3Items');
        print('level3IdToLevel2Id: $level3IdToLevel2Id');
        print('level2IdToLevel1Id: $level2IdToLevel1Id');
      } else {
        "9.获取专业列表失败".toHint();
      }
    } catch (e) {
      "9.获取专业列表失败: $e".toHint();
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
    loading.value = true;
    // 打印调用堆栈
    try {
      TopicApi.topicList({
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "cate": getSelectedCateId() ?? "",
        "level": getSelectedLevelId() ?? "",
        "status": selectedQuestionStatus.value.toString(),
        "major_id": (selectedMajorId.value?.toString() ?? ""),
      }).then((value) async {
        if (value != null && value["list"] != null) {
          total.value = value["total"] ?? 0;
          list.assignAll((value["list"] as List<dynamic>).toListMap());
          await Future.delayed(const Duration(milliseconds: 300));
          loading.value = false;
        } else {
          loading.value = false;
          "未获取到题库数据".toHint();
        }
      }).catchError((error) {
        loading.value = false;
        print("获取题库列表失败: $error");
        "获取题库列表失败: $error".toHint();
      });
    } catch (e) {
      loading.value = false;
      print("获取题库列表失败: $e");
      "获取题库列表失败: $e".toHint();
    }
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    ever(
      questionCate,
      (value) {
        if (questionCate.isNotEmpty) {
          // 当 questionCate 被赋值后再执行表单加载逻辑
          super.onInit();
          find(size.value, page.value);
        }
      },
    );

    columns = [
      ColumnData(title: "ID", key: "id", width: 80),
      ColumnData(title: "题型", key: "cate_name"),
      ColumnData(title: "难度", key: "level_name"),
      ColumnData(title: "题干", key: "title"),
      ColumnData(title: "答案", key: "answer"),
      ColumnData(title: "专业ID", key: "major_id"),
      ColumnData(title: "专业名称", key: "major_name"),
      ColumnData(title: "标签", key: "tag"),
      ColumnData(title: "录入人", key: "author"),
      ColumnData(title: "状态", key: "status_name"),
      ColumnData(title: "创建时间", key: "create_time"),
      ColumnData(title: "更新时间", key: "update_time"),
    ];

    // 初始化数据
    // find(size.value, page.value);
  }

  @override
  void refresh() {
    find(size.value, page.value);
  }

  List<dynamic> convertToCellValues(List<dynamic> row) {
    return row.map((e) {
      if (e is int || e is double || e is String || e is DateTime) {
        return e;
      } else {
        return e?.toString() ?? '';
      }
    }).toList();
  }

  // 导出选中项到 XLSX 文件
  Future<void> exportSelectedItemsToXLSX() async {
    try {
      if (selectedRows.isEmpty) {
        "请选择要导出的数据".toHint();
        return;
      }

      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return;

      // 创建 Excel 工作簿和工作表
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = "Sheet1";

      // 添加表头
      for (int colIndex = 0; colIndex < columns.length; colIndex++) {
        final column = columns[colIndex];
        sheet.getRangeByIndex(1, colIndex + 1).setText(column.title);
        sheet.getRangeByIndex(1, colIndex + 1).cellStyle.bold = true;
      }

      // 添加选中行的数据
      int rowIndex = 2;
      for (var item in list) {
        if (selectedRows.contains(item['id'])) {
          for (int colIndex = 0; colIndex < columns.length; colIndex++) {
            final column = columns[colIndex];
            final value = item[column.key];
            _setCellValue(sheet, rowIndex, colIndex + 1, value);
          }
          rowIndex++;
        }
      }

      // 保存文件
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmm').format(now);
      final file = File('$directory/questions_selected_$formattedDate.xlsx');
      await file.writeAsBytes(workbook.saveAsStream());
      workbook.dispose();

      "导出选中项成功!".toHint();
    } catch (e) {
      "导出选中项失败: $e".toHint();
    }
  }

  // 导入 XLSX 文件
  void importFromXLSX() async {
    try {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (result != null) {
        PlatformFile file = result.files.first;

        if (file.path != null) {
          final bytes = await File(file.path!).readAsBytes();
          if (bytes.isEmpty) {
            "无法读取 XLSX 文件".toHint();
            return;
          }

          // 调用 API 执行导入
          await TopicApi.topicBatchImport(File(file.path!)).then((value) {
            "导入成功!".toHint();
            refresh();
          }).catchError((error) {
            "导入失败: $error".toHint();
          });
        } else {
          "文件路径为空，无法读取文件".toHint();
        }
      } else {
        "没有选择文件".toHint();
      }
    } catch (e) {
      "导入失败: $e".toHint();
    }
  }

  // 导出全部到 XLSX 文件
  Future<void> exportAllToXLSX() async {
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return;

      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = "Sheet1";

      // 获取所有数据
      List<Map<String, dynamic>> allItems = [];
      int currentPage = 1;
      int pageSize = 100;

      while (true) {
        var response = await TopicApi.topicList({
          "size": pageSize.toString(),
          "page": currentPage.toString(),
        });

        allItems.addAll((response["list"] as List<dynamic>).toListMap());
        if (allItems.length >= response["total"]) break;
        currentPage++;
      }

      // 添加表头
      for (int colIndex = 0; colIndex < columns.length; colIndex++) {
        final column = columns[colIndex];
        sheet.getRangeByIndex(1, colIndex + 1).setText(column.title);
        sheet.getRangeByIndex(1, colIndex + 1).cellStyle.bold = true;
      }

      // 添加所有行数据
      int rowIndex = 2;
      for (var item in allItems) {
        for (int colIndex = 0; colIndex < columns.length; colIndex++) {
          final column = columns[colIndex];
          final value = item[column.key];
          _setCellValue(sheet, rowIndex, colIndex + 1, value);
        }
        rowIndex++;
      }

      // 保存文件
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyyMMdd_HHmm').format(now);
      final file = File('$directory/questions_all_pages_$formattedDate.xlsx');
      await file.writeAsBytes(workbook.saveAsStream());
      workbook.dispose();

      "导出全部成功!".toHint();
    } catch (e) {
      "导出全部失败: $e".toHint();
    }
  }

  // 辅助方法：设置单元格的值
  void _setCellValue(xlsio.Worksheet sheet, int rowIndex, int colIndex, dynamic value) {
    if (value is int || value is double) {
      sheet.getRangeByIndex(rowIndex, colIndex).setNumber(value.toDouble());
    } else if (value is DateTime) {
      sheet.getRangeByIndex(rowIndex, colIndex).setDateTime(value);
    } else {
      sheet.getRangeByIndex(rowIndex, colIndex).setText(value?.toString() ?? '');
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

  void toggleSelect(int id) {
    if (selectedRows.contains(id)) {
      // 当前行已被选中，取消选中
      selectedRows.remove(id);
    } else {
      // 当前行未被选中，选中
      selectedRows.add(id);
    }
  }

  String? getSelectedCateId() {
    if (selectedQuestionCate.value == '全部题型') {
      return "";
    }
    return selectedQuestionCate.value?.toString() ?? "";
  }

  String? getSelectedLevelId() {
    if (selectedQuestionLevel.value == '全部难度') {
      return "";
    }
    return selectedQuestionLevel.value?.toString() ?? "";
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
}
