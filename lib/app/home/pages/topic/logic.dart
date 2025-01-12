import 'package:hongshi_admin/app/home/pages/book/book.dart';
import 'package:hongshi_admin/ex/ex_list.dart';
import 'package:hongshi_admin/ex/ex_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hongshi_admin/api/topic_api.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:hongshi_admin/component/form/enum.dart';
import 'package:hongshi_admin/component/form/form_data.dart';
import 'package:hongshi_admin/component/dialog.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pinyin/pinyin.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../api/config_api.dart';
import '../../../../api/major_api.dart';
import '../../../../common/config_util.dart';
import '../../../../common/encr_util.dart';
import '../../../../component/pagination/logic.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import '../../config/logic.dart';
import 'topic_add_form.dart';
import 'topic_edit_form.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class TopicLogic extends GetxController {
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
  var currentEditTopic = RxMap<String, dynamic>({}).obs;
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

  final topicTitle = ''.obs;
  ValueNotifier<String?> topicSelectedQuestionCate =
  ValueNotifier<String?>(null);
  ValueNotifier<String?> topicSelectedQuestionLevel =
  ValueNotifier<String?>(null);
  final topicSelectedMajorId = "".obs;
  final topicAnswer = "".obs;
  final topicAuthor = "".obs;
  final topicTag = "".obs;
  final topicStatus = 0.obs;

  final uTopicTitle = ''.obs;
  final uTopicSelectedQuestionCate = "".obs;
  final uTopicSelectedQuestionLevel = "".obs;
  final uTopicSelectedMajorId = "".obs;
  final uTopicAnswer = "".obs;
  final uTopicAuthor = "".obs;
  final uTopicTag = "".obs;
  final uTopicStatus = 0.obs;

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
        "5.获取专业列表失败".toHint();
      }
    } catch (e) {
      "5.获取专业列表失败: $e".toHint();
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
    fetchConfigs();
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
      ColumnData(title: "ID", key: "id", width: 65),
      ColumnData(title: "题型", key: "cate_name", width: 80),
      ColumnData(title: "难度", key: "level_name", width: 80),
      ColumnData(title: "题干", key: "title", width: 280),
      ColumnData(title: "答案", key: "answer", width: 400),
      ColumnData(title: "专业ID", key: "major_id", width: 0),
      ColumnData(title: "专业名称", key: "major_name", width: 90),
      ColumnData(title: "标签", key: "tag", width: 100),
      ColumnData(title: "录入人", key: "author", width: 80),
      ColumnData(title: "状态", key: "status_name", width: 60),
      ColumnData(title: "创建时间", key: "create_time", width: 0),
      ColumnData(title: "更新时间", key: "update_time", width: 80),
    ];

    // 初始化数据
    // find(size.value, page.value);
  }

  var form = FormDto(labelWidth: 80, columns: [
    FormColumnDto(
      label: "问题内容",
      key: "topic_text",
      placeholder: "请输入问题内容",
    ),
    FormColumnDto(
      label: "答案",
      key: "answer",
      placeholder: "请输入答案",
    ),
    FormColumnDto(
      label: "专业ID",
      key: "specialty_id",
      placeholder: "请输入专业ID",
    ),
    FormColumnDto(
      label: "问题类型",
      key: "topic_type",
      placeholder: "请选择问题类型",
      type: FormColumnEnum.select,
      options: [
        {"label": "简答题", "value": "简答题"},
        {"label": "选择题", "value": "选择题"},
        {"label": "判断题", "value": "判断题"},
      ],
    ),
    FormColumnDto(
      label: "录入人",
      key: "entry_person",
      placeholder: "请输入录入人",
    ),
  ]);

  void add(BuildContext context) {
    DynamicInputDialog.show(
      context: context,
      title: '录入试题',
      child: TopicAddForm(),
      onSubmit: (formData) {
        print('提交的数据: $formData');
      },
    );
  }

  void edit(BuildContext context, Map<String, dynamic> topic) {
    currentEditTopic.value = RxMap<String, dynamic>(topic);
    var level2MajorId = getLevel2IdFromLevel3Id(topic["major_id"].toString());
    var level3MajorId = getLevel1IdFromLevel2Id(level2MajorId);

    DynamicInputDialog.show(
      context: context,
      title: '录入试题',
      child: TopicEditForm(
          topicId: topic["id"],
          initialTitle: topic["title"],
          initialAnswer: topic["answer"],
          initialQuestionCate: ValueNotifier<String?>(topic["cate"]),
          initialQuestionLevel: ValueNotifier<String?>(topic["level"]),
          initialLevel1MajorId: level3MajorId,
          initialLevel2MajorId: level2MajorId,
          initialMajorId: topic["major_id"].toString(),
          initialAuthor: topic["author"],
          initialTag: topic["tag"],
          initialStatus: topic["status"]),
      onSubmit: (formData) {
        print('提交的数据: $formData');
      },
    );
  }

  Future<bool> saveTopic() async {
    // 生成题本的逻辑
    final topicTitleSubmit = topicTitle.value;
    final int topicSelectedMajorIdSubmit = topicSelectedMajorId.value.toInt();
    final topicSelectedQuestionCateSubmit = topicSelectedQuestionCate.value;
    final topicSelectedQuestionLevelSubmit = topicSelectedQuestionLevel.value;
    final topicAnswerSubmit = topicAnswer.value;
    final topicAuthorSubmit = topicAuthor.value;
    final topicTagSubmit = topicTag.value;
    final topicStatusSubmit = topicStatus.value;

    bool isValid = true;
    String errorMessage = "";

    if (topicTitleSubmit.isEmpty) {
      isValid = false;
      errorMessage += "问题提干不能为空\n";
    }
    if (topicSelectedMajorIdSubmit == 0 || topicSelectedMajorIdSubmit <= 0) {
      isValid = false;
      errorMessage += "请选择专业\n";
    }
    if (topicSelectedQuestionCateSubmit == null ||
        topicSelectedQuestionCateSubmit.isEmpty) {
      isValid = false;
      errorMessage += "请选择题型\n";
    }
    if (topicSelectedQuestionLevelSubmit == null ||
        topicSelectedQuestionLevelSubmit.isEmpty) {
      isValid = false;
      errorMessage += "请选择难度\n";
    }
    if (topicAnswerSubmit.isEmpty && topicStatusSubmit == 2) {
      isValid = false;
      errorMessage += "完成状态下的问题，答案不能为空\n";
    }
    if (topicStatusSubmit == 0) {
      isValid = false;
      errorMessage += "请选择问题状态\n";
    }

    if (isValid) {
      try {
        String encrAnswer = await EncryptionUtil.encryptAES256(topicAnswerSubmit);
        Map<String, dynamic> params = {
          "title": topicTitleSubmit,
          "cate": topicSelectedQuestionCateSubmit,
          "level": topicSelectedQuestionLevelSubmit,
          "answer_encr": encrAnswer,
          "answer_py": PinyinHelper.getShortPinyin(topicAnswerSubmit),
          "author": "杜立东",
          "major_id": topicSelectedMajorIdSubmit,
          "tag": topicTagSubmit,
          "status": topicStatusSubmit,
        };

        dynamic result = await TopicApi.topicCreate(params);
        if (result['id'] > 0) {
          "创建试题成功".toHint();
          return true;
        } else {
          "创建试题失败".toHint();
          return false;
        }
      } catch (e) {
        print('Error: $e');
        "创建试题时发生错误：$e".toHint();
        return false;
      }
    } else {
      // 显示错误提示
      errorMessage.toHint();
      return false;
    }
  }

  Future<bool> updateTopic(int topicId) async {
    // 生成题本的逻辑
    final topicTitleSubmit = uTopicTitle.value;
    final topicSelectedMajorIdSubmit = uTopicSelectedMajorId.value.toInt();
    final topicSelectedQuestionCateSubmit = uTopicSelectedQuestionCate.value;
    final topicSelectedQuestionLevelSubmit = uTopicSelectedQuestionLevel.value;
    final topicAnswerSubmit = uTopicAnswer.value;
    final topicAuthorSubmit = uTopicAuthor.value;
    final topicTagSubmit = uTopicTag.value;
    final topicStatusSubmit = uTopicStatus.value;

    bool isValid = true;
    String errorMessage = "";

    if (topicId == 0) {
      isValid = false;
      errorMessage += "问题ID为0，请检查\n";
    }

    if (topicTitleSubmit.isEmpty) {
      isValid = false;
      errorMessage += "问题提干不能为空\n";
    }
    if (topicSelectedMajorIdSubmit <= 0) {
      isValid = false;
      errorMessage += "请选择专业\n";
    }
    if (topicSelectedQuestionCateSubmit.isEmpty) {
      isValid = false;
      errorMessage += "请选择题型\n";
    }
    if (topicSelectedQuestionLevelSubmit.isEmpty) {
      isValid = false;
      errorMessage += "请选择难度\n";
    }
    if (topicAnswerSubmit.isEmpty && topicStatusSubmit == 2) {
      isValid = false;
      errorMessage += "完成状态下的问题，答案不能为空\n";
    }
    if (topicStatusSubmit == 0) {
      isValid = false;
      errorMessage += "请选择问题状态\n";
    }

    if (isValid) {
      try {
        String encrAnswer = await EncryptionUtil.encryptAES256(topicAnswerSubmit);
        Map<String, dynamic> params = {
          "title": topicTitleSubmit,
          "cate": topicSelectedQuestionCateSubmit,
          "level": topicSelectedQuestionLevelSubmit,
          "answer_encr": encrAnswer,
          "answer_py": PinyinHelper.getShortPinyin(topicAnswerSubmit),
          "author": "杜立东",
          "major_id": topicSelectedMajorIdSubmit,
          "tag": topicTagSubmit,
          "status": topicStatusSubmit,
        };

        dynamic result = await TopicApi.topicUpdate(topicId, params);
        "更新试题成功".toHint();
        return true;
      } catch (e) {
        print('Error: $e');
        "更新试题时发生错误：$e".toHint();
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
      TopicApi.topicDelete(d["id"].toString()).then((value) {
        list.removeAt(index);
      }).catchError((error) {
        "删除失败: $error".toHint();
      });
    } catch (e) {
      "删除失败: $e".toHint();
    }
  }

  Future<void> audit(int topicId, int status) async {
    try {
      await TopicApi.auditTopic(topicId, status);
      "审核完成".toHint();
      find(size.value, page.value);
    } catch (e) {
      "审核失败: $e".toHint();
    }
  }

  void generateAndOpenLink(BuildContext context,
      Map<String, dynamic> item) async {
    final url =
    Uri.parse("${ConfigUtil.fullUrl}/static/h5/?topicId=${item['id']}");
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
        sheet
            .getRangeByIndex(1, colIndex + 1)
            .cellStyle
            .bold = true;
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
      final file = File('$directory/topics_selected_$formattedDate.xlsx');
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
        sheet
            .getRangeByIndex(1, colIndex + 1)
            .cellStyle
            .bold = true;
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
      final file = File('$directory/topics_all_pages_$formattedDate.xlsx');
      await file.writeAsBytes(workbook.saveAsStream());
      workbook.dispose();

      "导出全部成功!".toHint();
    } catch (e) {
      "导出全部失败: $e".toHint();
    }
  }

  // 辅助方法：设置单元格的值
  void _setCellValue(xlsio.Worksheet sheet, int rowIndex, int colIndex,
      dynamic value) {
    if (value is int || value is double) {
      sheet.getRangeByIndex(rowIndex, colIndex).setNumber(value.toDouble());
    } else if (value is DateTime) {
      sheet.getRangeByIndex(rowIndex, colIndex).setDateTime(value);
    } else {
      sheet.getRangeByIndex(rowIndex, colIndex).setText(
          value?.toString() ?? '');
    }
  }

  void batchDelete(List<int> ids) {
    try {
      List<String> idsStr = ids.map((id) => id.toString()).toList();
      if (idsStr.isEmpty) {
        "请先选择要删除的试题".toHint();
        return;
      }
      TopicApi.topicDelete(idsStr.join(",")).then((value) {
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

  void applyFilters() {
    // 这里可以添加应用过滤逻辑
    // print('Selected Major: ${selectedMajor.value}');
    // print('Selected Sub Major: ${selectedSubMajor.value}');
    // print('Selected Sub Sub Major: ${selectedSubSubMajor.value}');
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
