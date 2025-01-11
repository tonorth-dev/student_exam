import 'package:admin_flutter/ex/ex_list.dart';
import 'package:admin_flutter/ex/ex_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:admin_flutter/api/book_api.dart';
import 'package:admin_flutter/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:admin_flutter/component/form/enum.dart';
import 'package:admin_flutter/component/form/form_data.dart';
import '../../../../api/config_api.dart';
import '../../../../api/major_api.dart';
import '../../../../api/book_template_api.dart';
import '../../../../api/topic_api.dart';
import '../../../../common/http_util.dart';
import '../../../../component/pagination/logic.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import '../../config/logic.dart';

class BookLogic extends GetxController {
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
  var currentEditBook = RxMap<String, dynamic>({}).obs;
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

  final bookName = ''.obs;
  final bookTag = ''.obs;
  final bookQuestionCount = 0.obs;
  final bookSelectedMajorId = "0".obs;
  final bookSelectedQuestionCate = "".obs;
  ValueNotifier<String?> bookSelectedQuestionLevel = ValueNotifier<String?>(null);
  final Map<String, RxInt> cateSelectedValues = {};

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
          await BookTemplateApi.templateList({'pageSize': "30", 'page': "1"});
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
        "6.获取专业列表失败".toHint();
      }
    } catch (e) {
      "6.获取专业列表失败: $e".toHint();
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
      BookApi.bookList({
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
          "未获取到题本数据".toHint();
        }
      }).catchError((error) {
        loading.value = false;
        "获取题本列表失败: $error".toHint();
      });
    } catch (e) {
      loading.value = false;
      "获取题本列表失败: $e".toHint();
    }
  }

  var columns = <ColumnData>[
    ColumnData(title: "ID", key: "id", width: 80),
    ColumnData(title: "题本名称", key: "name"),
    ColumnData(title: "专业名称", key: "major_name"),
    ColumnData(title: "难度", key: "level_name"),
    ColumnData(
      title: "题目组合",
      key: "component_desc",
      render: (value, rowData, rowIndex, tableData) {
        if (value is List) {
          // 格式化 JSON 数据为友好的字符串
          return Text(value.join("\n"));
        }
        return Text(value?.toString() ?? ""); // 默认处理其他类型
      },
    ),
    ColumnData(title: "题目份数", key: "unit_number"),
    ColumnData(title: "题目数量", key: "questions_number"),
    ColumnData(title: "创建人", key: "creator"),
    ColumnData(title: "模板名称", key: "template_name"),
    ColumnData(title: "标签", key: "tag"),
    ColumnData(title: "创建时间", key: "update_time"),
  ];

  @override
  Future<void> onInit() async {
    await fetchConfigs();
    await fetchTemplates();
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

    // 初始化数据
    // find(size.value, page.value);
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

  void deleteBook(Map<String, dynamic> d, int index) {
    try {
      BookApi.bookDelete(d["id"].toString()).then((value) {
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
      File('$directory/books_current_page.csv').writeAsStringSync(csv);
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
        var response = await BookApi.bookList({
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
      File('$directory/books_all_pages.csv').writeAsStringSync(csv);
      "导出全部成功!".toHint();
    } catch (e) {
      "导出全部失败: $e".toHint();
    }
  }

  void batchDelete(List<int> ids) {
    try {
      List<String> idsStr = ids.map((id) => id.toString()).toList();
      BookApi.bookDelete(idsStr.join(",")).then((value) {
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
    find(size.value, page.value);
  }

  Future<void> saveBook() async {
    // 生成题本的逻辑
    final bookNameSubmit = bookName.value;
    final bookTagSubmit = bookTag.value;
    final int bookSelectedMajorIdSubmit = bookSelectedMajorId.value.toInt();
    final bookSelectedQuestionCateSubmit = bookSelectedQuestionCate.value;
    final bookSelectedQuestionLevelSubmit = bookSelectedQuestionLevel.value;
    final bookQuestionCountSubmit = bookQuestionCount.value;

    bool isValid = true;
    String errorMessage = "";

    if (bookNameSubmit.isEmpty) {
      isValid = false;
      errorMessage += "题本名称不能为空\n";
    }
    print("bookSelectedMajorIdSubmit:$bookSelectedMajorIdSubmit");
    if (bookSelectedMajorIdSubmit == 0) {
      isValid = false;
      errorMessage += "请选择专业\n";
    }
    // if (bookSelectedQuestionCateSubmit.isEmpty) {
    //   isValid = false;
    //   errorMessage += "请选择题型\n";
    // }
    // if (bookSelectedQuestionLevelSubmit == null || bookSelectedQuestionLevelSubmit.isEmpty) {
    //   isValid = false;
    //   errorMessage += "请选择难度\n";
    // }
    if (bookQuestionCountSubmit <= 0) {
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

    print("debug questionCate: $questionCate");
    print("debug components: $components");

    if (isValid) {
      // 提交表单
      print("生成题本：");
      print("题本名称: $bookName");
      print("选择专业: $bookSelectedMajorId");
      print("选择题型: $bookSelectedQuestionCate");
      print("选择难度: $bookSelectedQuestionLevel");
      print("生成套数: $bookQuestionCount");
      try {
        Map<String, dynamic> params = {
          "name": bookNameSubmit,
          "tag": bookTagSubmit,
          "major_id": bookSelectedMajorIdSubmit,
          "level": bookSelectedQuestionLevelSubmit,
          "component": components,
          "unit_number": bookQuestionCountSubmit,
          "template_id": 1,
          "template_name": "demo",
        };

        dynamic result = await BookApi.bookCreate(params);
        "生成题本成功".toHint();
      } catch (e) {
        print('Error: $e');
      }
    } else {
      // 显示错误提示
      errorMessage.toHint();
    }
  }

  Future<bool> saveTemplate() async {
    // 生成题本的逻辑
    final bookNameSubmit = bookName.value;
    final bookTagSubmit = bookTag.value;
    final int bookSelectedMajorIdSubmit = bookSelectedMajorId.value.toInt();
    final bookSelectedQuestionLevelSubmit = bookSelectedQuestionLevel.value;
    final bookQuestionCountSubmit = bookQuestionCount.value;

    bool isValid = true;
    String errorMessage = "";

    if (bookNameSubmit.isEmpty) {
      isValid = false;
      errorMessage += "题本名称不能为空\n";
    }
    if (bookSelectedMajorIdSubmit == 0) {
      isValid = false;
      errorMessage += "请选择专业\n";
    }
    // if (bookSelectedQuestionLevelSubmit == null || bookSelectedQuestionLevelSubmit.isEmpty) {
    //   isValid = false;
    //   errorMessage += "请选择难度\n";
    // }
    if (bookQuestionCountSubmit <= 0) {
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

    print("debug questionCate: $questionCate");
    print("debug components: $components");

    if (isValid) {
      // 提交表单
      print("生成题本：");
      print("题本名称: $bookName");
      print("选择专业: $bookSelectedMajorId");
      print("选择题型: $bookSelectedQuestionCate");
      print("选择难度: $bookSelectedQuestionLevel");
      print("生成套数: $bookQuestionCount");
      try {
        Map<String, dynamic> params = {
          "name": bookNameSubmit,
          "tag": bookTagSubmit,
          "major_id": bookSelectedMajorIdSubmit,
          "level": bookSelectedQuestionLevelSubmit,
          "component": components,
          "unit_number": bookQuestionCountSubmit,
          "template_id": 1,
          "template_name": "demo",
        };

        dynamic result = await BookTemplateApi.templateCreate(params);
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
    print("debug fillTemplate:$item");
    // 填充数据到表单
    bookName.value = item['name'];
    bookTag.value = item['tag'];
    var level2MajorId = getLevel2IdFromLevel3Id(item["major_id"].toString());
    var level1MajorId = getLevel1IdFromLevel2Id(level2MajorId);

    majorSelectedLevel1.value = level1MajorId;
    majorSelectedLevel2.value = level2MajorId;
    majorSelectedLevel3.value = item["major_id"].toString();
    bookSelectedMajorId.value = item["major_id"].toString();

    bookSelectedQuestionLevel.value = item['level'];
    bookQuestionCount.value = item['unit_number'];

    // 更新题型数量
    for (var comp in item['component']) {
      final key = comp['key'];
      final number = comp['number'] ?? 0;
      cateSelectedValues[key]?.value = number;
    }
    print("debug bookSelectedQuestionLevel.value");
    print(bookSelectedQuestionLevel.value);
  }

  void deleteTemplate(Map<String, dynamic> d) async {
    try {
      await BookTemplateApi.templateDelete(d["id"]);
      "删除成功".toHint();
    } catch (error) {
      "删除失败: $error".toHint();
    }
  }

  final GlobalKey<SuggestionTextFieldState> topicTextFieldKey = GlobalKey<SuggestionTextFieldState>();
  Rx<int> newTopicId = 0.obs;
  final Map<String, String?> _selectedQuestions = {};

  Future<List<Map<String, dynamic>>> fetchTopics(String query) async {
    print("query:$query");
    try {
      final response = await TopicApi.topicList({
        "pageSize": "10",
        "page": "1",
        "keyword": query ?? "",
      });
      var data = response['list'];
      // 检查数据是否为 List
      if (data is List) {
        final List<Map<String, dynamic>> suggestions = data.map((item) {
          // 检查每个 item 是否包含 'name' 和 'id' 字段
          if (item is Map && item.containsKey('title') && item.containsKey('id')) {
            return {
              'name': "${item['title'].length > 15 ? item['title'].substring(0, 15) + '...' : item['title']}（${item['id'].toString()}）",
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

  Future<dynamic> changeTopic(int bookId, int oldId, int newId) async {
    try {
      await BookApi.updateQuestions(bookId, {
          "new_question_id" : newId,
          "old_question_id" : oldId,
        });
    } catch (e) {
      print('Error in updateDirectory: $e');
      rethrow; // 重新抛出异常以便调用者处理
    }
  }
}
