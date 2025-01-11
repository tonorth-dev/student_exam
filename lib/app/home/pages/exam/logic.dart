import 'package:hongshi_admin/ex/ex_list.dart';
import 'package:hongshi_admin/ex/ex_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:hongshi_admin/api/exam_api.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:hongshi_admin/component/form/enum.dart';
import 'package:hongshi_admin/component/form/form_data.dart';
import 'package:intl/intl.dart';
import '../../../../api/classes_api.dart';
import '../../../../api/config_api.dart';
import '../../../../api/major_api.dart';
import '../../../../api/exam_template_api.dart';
import '../../../../component/pagination/logic.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import '../../config/logic.dart';

class ExamLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;
  var templateSaved = false.obs;

  final ValueNotifier<dynamic> majorSelectedLevel1 = ValueNotifier(null);
  final ValueNotifier<dynamic> majorSelectedLevel2 = ValueNotifier(null);
  final ValueNotifier<dynamic> majorSelectedLevel3 = ValueNotifier(null);

  final GlobalKey<CascadingDropdownFieldState> majorDropdownKey =
      GlobalKey<CascadingDropdownFieldState>();
  final GlobalKey<DropdownFieldState> cateDropdownKey =
      GlobalKey<DropdownFieldState>();
  final GlobalKey<DropdownFieldState> levelDropdownKey =
      GlobalKey<DropdownFieldState>();
  final GlobalKey<SelectableListState> selectableListKey =
      GlobalKey<SelectableListState>();

  // 当前编辑的题目数据
  var currentEditExam = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  ValueNotifier<String?> selectedQuestionCate = ValueNotifier<String?>(null);
  ValueNotifier<String?> selectedQuestionLevel = ValueNotifier<String?>(null);
  RxList<Map<String, dynamic>> questionCate = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> questionLevel = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> templateList = <Map<String, dynamic>>[].obs;

  // 专业列表数据
  List<Map<String, dynamic>> majorList = [];
  Map<String, List<Map<String, dynamic>>> subMajorMap = {};
  Map<String, List<Map<String, dynamic>>> subSubMajorMap = {};
  List<Map<String, dynamic>> level1Items = [];
  Map<String, List<Map<String, dynamic>>> level2Items = {};
  Map<String, List<Map<String, dynamic>>> level3Items = {};
  Rx<String> selectedMajorId = "0".obs;

  final examName = ''.obs;
  final examQuestionCount = 0.obs;

  ValueNotifier<Map<String, int>> examQuestionCate = ValueNotifier<Map<String, int>>({});
  ValueNotifier<String?> examSelectedQuestionLevel = ValueNotifier<String?>(null);
  final Map<String, RxInt> cateSelectedValues = {};

  DateTime todayMidnight = DateTime.now()
      .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  late String initialStartTime;
  CustomDateTimePickerController dateTimeControllerStart =
      CustomDateTimePickerController(initialTime: '2024-12-19 14:30:00');

  DateTime todayLastSecond = DateTime.now()
      .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  late String initialEndTime;
  CustomDateTimePickerController dateTimeControllerEnd =
      CustomDateTimePickerController(initialTime: '2024-12-19 14:30:00');

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
          print("debug Question Cate: $questionCate");
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
          print("debug Question Level: $questionLevel");
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

  Future<void> fetchTemplates() async {
    try {
      var templates =
          await ExamTemplateApi.templateList({'pageSize': "30", 'page': "1"});
      if (templates != null && templates.containsKey("list")) {
        final templateItem = templates["list"] as List<dynamic>;

        templateList = RxList.from(templateItem);

        for (var item in questionCate) {
          cateSelectedValues[item['id']] = 0.obs;
        }
        print("debug selectedValues: $cateSelectedValues");
      }
    } catch (e) {
      print('debug templateList 初始化 templates 失败: $e');
      templateList = RxList<Map<String, dynamic>>();
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
        "7.获取专业列表失败".toHint();
      }
    } catch (e) {
      "7.获取专业列表失败: $e".toHint();
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
      ExamApi.examList({
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "level": getSelectedLevelId() ?? "",
        "major_id": (selectedMajorId.value?.toString() ?? ""),
      }).then((value) async {
        if (value != null && value["list"] != null) {
          total.value = value["total"] ?? 0;
          list.addAll((value["list"] as List<dynamic>).toListMap());
          await Future.delayed(const Duration(milliseconds: 300));
          loading.value = false;
        } else {
          loading.value = false;
          "未获取到试卷数据".toHint();
        }
      }).catchError((error) {
        loading.value = false;
        "获取试卷列表失败: $error".toHint();
      });
    } catch (e) {
      loading.value = false;
      "获取试卷列表失败: $e".toHint();
    }
  }

  List<ColumnData> columns = <ColumnData>[
    ColumnData(title: "ID", key: "id", width: 80),
    ColumnData(title: "试卷名称", key: "name", width: 200),
    ColumnData(title: "班级名称", key: "class_name", width: 120),
    ColumnData(title: "难度", key: "level_name", width: 100),
    ColumnData(
        title: "题型组合",
        key: "component_desc",
        render: (value, rowData, rowIndex, tableData) {
          if (value is List) {
            // 格式化 JSON 数据为友好的字符串
            return Text(value.join("\n"));
          }
          return Text(value?.toString() ?? ""); // 默认处理其他类型
        },
        width: 200),
    ColumnData(title: "题目数量", key: "question_count", width: 80),
    ColumnData(title: "开始时间", key: "start_time", width: 120),
    ColumnData(title: "结束时间", key: "end_time", width: 120),
    ColumnData(title: "创建时间", key: "create_time", width: 120),
  ];

  @override
  Future<void> onInit() async {
    await fetchConfigs();
    await fetchTemplates();
    initialStartTime =
        "${todayMidnight.year}-${todayMidnight.month.toString().padLeft(2, '0')}-${todayMidnight.day.toString().padLeft(2, '0')} 00:00:00";
    initialEndTime =
        "${todayMidnight.year}-${todayMidnight.month.toString().padLeft(2, '0')}-${todayMidnight.day.toString().padLeft(2, '0')} 23:59:59";
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
  }

  var form = FormDto(labelWidth: 80, columns: [
    FormColumnDto(
      label: "名称",
      key: "name",
      placeholder: "请输入名称",
    ),
    FormColumnDto(
      label: "专业ID",
      key: "major_id",
      placeholder: "请输入专业ID",
    ),
    FormColumnDto(
      label: "难度",
      key: "level",
      placeholder: "请选择难度",
      type: FormColumnEnum.select,
      options: [
        {"label": "低", "value": "low"},
        {"label": "中等", "value": "middle"},
        {"label": "高", "value": "high"},
      ],
    ),
    FormColumnDto(
      label: "创建人",
      key: "creator",
      placeholder: "请输入创建人",
    ),
  ]);

  void deleteExam(Map<String, dynamic> d, int index) {
    try {
      ExamApi.examDelete(d["id"].toString()).then((value) {
        list.removeAt(index);
      }).catchError((error) {
        "删除失败: $error".toHint();
      });
    } catch (e) {
      "删除失败: $e".toHint();
    }
  }

  @override
  void refresh() {
    find(size.value, page.value);
  }

  Future<void> exportCurrentPageToCSV() async {
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return;

      List<List<dynamic>> rows = [];
      rows.add(columns.map((column) => column.title).toList());

      for (var item in list) {
        rows.add(columns.map((column) => item[column.key]).toList());
      }

      String csv = const ListToCsvConverter().convert(rows);
      File('$directory/exams_current_page.csv').writeAsStringSync(csv);
      "导出当前页成功!".toHint();
    } catch (e) {
      "导出当前页失败: $e".toHint();
    }
  }

  Future<void> exportAllToCSV() async {
    try {
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory == null) return;

      List<Map<String, dynamic>> allItems = [];
      int currentPage = 1;
      int pageSize = 100;

      while (true) {
        var response = await ExamApi.examList({
          "size": pageSize.toString(),
          "page": currentPage.toString(),
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
      File('$directory/exams_all_pages.csv').writeAsStringSync(csv);
      "导出全部成功!".toHint();
    } catch (e) {
      "导出全部失败: $e".toHint();
    }
  }

  void batchDelete(List<int> ids) {
    try {
      List<String> idsStr = ids.map((id) => id.toString()).toList();
      ExamApi.examDelete(idsStr.join(",")).then((value) {
        "批量删除成功!".toHint();
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
      selectedRows.clear();
    } else {
      selectedRows.addAll(list.map((item) => item['id']));
    }
  }

  void toggleSelect(int index) {
    if (selectedRows.contains(index)) {
      selectedRows.remove(index);
    } else {
      selectedRows.add(index);
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

  void applyFilters() {
    // 这里可以添加应用过滤逻辑
    // print('Selected Major: ${selectedMajor.value}');
    // print('Selected Sub Major
  }

  void reset() {
    majorDropdownKey.currentState?.reset();
    cateDropdownKey.currentState?.reset();
    levelDropdownKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    fetchConfigs();
    fetchMajors();
    find(size.value, page.value);
  }

  Future<void> saveExam() async {
    // 生成试卷的逻辑
    final examNameSubmit = examName.value;
    final examSelectedClassIdSubmit = int.parse(selectedClassesId.value);
    final examSelectedQuestionLevelSubmit = examSelectedQuestionLevel.value;
    final examQuestionCountSubmit = examQuestionCount.value;
    final examStartTimeSubmit = dateTimeControllerStart.time;
    final examEndTimeSubmit = dateTimeControllerEnd.time;
    final examComponents = examQuestionCate.value;

    List<Map<String, dynamic>> examComponentsList = [];
    if (examComponents != null) {
      examComponentsList = examComponents.entries.map((entry) {
        return {'key': entry.key, 'number': entry.value};
      }).toList();
    }

    bool isValid = true;
    String errorMessage = "";

    if (examNameSubmit.isEmpty) {
      // isValid = false;
      // errorMessage += "试卷名称不能为空\n";
    }

    // 验证班级ID是否为空
    if (examSelectedClassIdSubmit == 0) {
      isValid = false;
      errorMessage += "请选择班级\n";
    }

    if (examQuestionCountSubmit <= 0) {
      isValid = false;
      errorMessage += "生成套数必须大于0\n";
    }

    // 验证起始时间和结束时间
    if (examStartTimeSubmit == null || examEndTimeSubmit == null) {
      isValid = false;
      errorMessage += "请选择完整的考试时间段\n";
    } else {
      // 将字符串转换为 DateTime
      DateTime startTime = DateTime.parse(examStartTimeSubmit);
      DateTime endTime = DateTime.parse(examEndTimeSubmit);

      // 获取当前时间
      DateTime now = DateTime.now();

      if (startTime.isAfter(endTime)) {
        isValid = false;
        errorMessage += "开始时间不能晚于结束时间\n";
      }

      if (endTime.isBefore(now)) {
        isValid = false;
        errorMessage += "结束时间不能早于当前时间\n";
      }
    }

    if (isValid) {
      // 提交表单
      print("生成试卷：");
      print("试卷名称: $examNameSubmit");
      print("选择班级: $examSelectedClassIdSubmit");
      print("选择难度: $examSelectedQuestionLevelSubmit");
      print("生成套数: $examQuestionCountSubmit");
      print("开始时间: $examStartTimeSubmit");
      print("结束时间: $examEndTimeSubmit");

      try {
        Map<String, dynamic> params = {
          "name": examNameSubmit,
          "class_id": examSelectedClassIdSubmit,
          "level": examSelectedQuestionLevelSubmit,
          "question_count": examQuestionCountSubmit,
          "component": examComponentsList,
          "start_time": convertToRFC3339(examStartTimeSubmit!),
          // 格式化时间为ISO 8601字符串
          "end_time": convertToRFC3339(examEndTimeSubmit!),
          // 格式化时间为ISO 8601字符串
        };

        dynamic result = await ExamApi.examCreate(params);
        "生成试卷成功".toHint();
      } catch (e) {
        print('Error: $e');
        errorMessage += "生成试卷失败: $e\n";
        errorMessage.toHint();
      }
    } else {
      // 显示错误提示
      errorMessage.toHint();
    }
  }

  String convertToRFC3339(String inputDateTime, {String timeZone = '+08:00'}) {
    // 定义输入格式和输出格式
    final inputFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    final outputFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

    // 解析输入字符串为 DateTime 对象
    DateTime dateTime;
    try {
      dateTime = inputFormat.parse(inputDateTime);
    } catch (e) {
      throw FormatException("Invalid date format: $inputDateTime");
    }

    // 将 DateTime 对象格式化为 RFC3339 字符串，并添加时区信息
    String rfc3339String = outputFormat.format(dateTime);

    // 如果需要特定时区，可以手动调整
    if (timeZone.isNotEmpty) {
      // 添加指定的时区偏移
      rfc3339String = '$rfc3339String$timeZone';
    }

    return rfc3339String;
  }

  Future<bool> saveTemplate() async {
    var examSelectedClassIdSubmit = 0;
    // 生成试卷的逻辑
    if (selectedClassesId.value.isEmpty) {
      examSelectedClassIdSubmit = 0;
    } else {
      examSelectedClassIdSubmit = int.parse(selectedClassesId.value);
    }

    final examSelectedQuestionCateSubmit = examQuestionCate.value;
    final examSelectedQuestionLevelSubmit = examSelectedQuestionLevel.value;
    final examQuestionCountSubmit = examQuestionCount.value;
    final examComponents = examQuestionCate.value;

    List<Map<String, dynamic>> examComponentsList = [];
    if (examComponents != null) {
      examComponentsList = examComponents.entries.map((entry) {
        return {'key': entry.key, 'number': entry.value};
      }).toList();
    }

    bool isValid = true;
    String errorMessage = "";

    if (examSelectedQuestionLevelSubmit == null ||
        examSelectedQuestionLevelSubmit.isEmpty) {
      isValid = false;
      errorMessage += "请选择难度\n";
    }
    if (examQuestionCountSubmit <= 0) {
      isValid = false;
      errorMessage += "生成套数必须大于0\n";
    }

    List<Map<String, dynamic>> components = questionCate.map((item) {
      String key = item['id'] ?? '';
      int value = item['value'] ?? 0;
      return {
        'key': key,
        'number': value ?? 0,
      };
    }).toList();

    if (isValid) {
      // 提交表单
      print("生成模板：");
      print("选择题型: $examQuestionCate");
      print("选择难度: $examSelectedQuestionLevel");
      print("生成套数: $examQuestionCount");
      try {
        Map<String, dynamic> params = {
          "class_id": examSelectedClassIdSubmit, // 新增字段
          "level": examSelectedQuestionLevelSubmit,
          "question_count": examQuestionCountSubmit,
          "component": examComponentsList,
        };

        dynamic result = await ExamTemplateApi.templateCreate(params);
        templateSaved.value = true;
        "保存模板成功".toHint();
        return true; // 操作成功
      } catch (e) {
        print('Error: $e');
        "保存模板失败: $e".toHint();
        return false; // 操作失败
      }
    } else {
      // 显示错误提示
      errorMessage.toHint();
      return false; // 操作失败
    }
  }

  void fillTemplate(Map<String, dynamic> item) {
    // 填充数据到表单
    selectedClassesId.value = item['class_id'].toString();
    selectedClassesMap.value = {
      "id": item['class_id'],
      "name": item['class_name'],
    };
    examSelectedQuestionLevel.value = item['level'];
    examQuestionCount.value = item['question_count'];

    // 更新题型数量
    var components = item['component'];
    print("components.value: $components");

    if (components != null && components is Iterable) {
      Map<String, int> updatedExamQuestionCate = Map.from(examQuestionCate.value ?? {});

      for (var comp in components) {
        final key = comp['key'] as String;
        final number = comp['number'] as int? ?? 0;

        // 更新新的 Map 中的值
        updatedExamQuestionCate[key] = number;
      }

      // 更新 ValueNotifier 并通知监听器
      examQuestionCate.value = updatedExamQuestionCate;
      examQuestionCate.notifyListeners(); // 一次性通知监听器更新
    }

    print("examQuestionCate.value: ${examQuestionCate.value}");
  }

  void deleteTemplate(Map<String, dynamic> d) async {
    try {
      await ExamTemplateApi.templateDelete(d["id"]);
      "删除成功".toHint();
    } catch (error) {
      "删除失败: $error".toHint();
    }
    await fetchTemplates();
  }

  final GlobalKey<SuggestionTextFieldState> classesTextFieldKey =
      GlobalKey<SuggestionTextFieldState>();

  Future<List<Map<String, dynamic>>> fetchClasses(String query) async {
    print("query:$query");
    try {
      final response = await ClassesApi.classesList(params: {
        "pageSize": 10,
        "page": 1,
        "keyword": query ?? "",
      });
      var data = response['list'];
      print("response: $data");
      // 检查数据是否为 List
      if (data is List) {
        final List<Map<String, dynamic>> suggestions =
            data.whereType<Map>().map((item) {
          // 检查每个 item 是否包含 'class_name' 和 'id' 字段
          if (item.containsKey('class_name') && item.containsKey('id')) {
            return {
              'name': item['class_name'],
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
      print('Error fetching classes: $e');
      return [];
    }
  }

  Rx<String> selectedClassesId = "0".obs;
  ValueNotifier<Map?> selectedClassesMap = ValueNotifier<Map?>(null);
}
