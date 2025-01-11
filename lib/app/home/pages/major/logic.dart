import 'package:hongshi_admin/ex/ex_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hongshi_admin/api/major_api.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:hongshi_admin/component/dialog.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../api/major_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import 'major_add_form.dart';
import 'major_edit_form.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

class MajorLogic extends GetxController {
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
        "1.获取专业列表失败".toHint();
      }
    } catch (e) {
      "1.获取专业列表失败: $e".toHint();
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
    fetchMajors();
    super.onInit();
    find(size.value,
        page.value); // Fetch and populate major data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 80),
      ColumnData(title: "一级类别", key: "first_level_category", width: 200),
      ColumnData(title: "二级类别", key: "second_level_category", width: 200),
      ColumnData(title: "专业名称", key: "major_name", width: 200),
      ColumnData(title: "年份", key: "year", width: 0),
      ColumnData(title: "创建时间", key: "create_time", width: 200),
      ColumnData(title: "更新时间", key: "update_time", width: 200),
    ];
  }

  void add(BuildContext context) {
    DynamicInputDialog.show(
      context: context,
      title: '录入专业',
      child: MajorAddForm(),
      onSubmit: (formData) {
        print('提交的数据: $formData');
      },
    );
  }

  void edit(BuildContext context, Map<String, dynamic> major) {
    currentEditMajor.value = RxMap<String, dynamic>(major);
    var level2MajorId = getLevel2IdFromLevel3Id(major["major_id"].toString());
    var level3MajorId = getLevel1IdFromLevel2Id(level2MajorId);

    DynamicInputDialog.show(
      context: context,
      title: '录入专业',
      child: MajorEditForm(
        majorId: major["id"],
        initialMajorName: major["major_name"],
        initialFirstLevelCategory: major["first_level_category"],
        initialSecondLevelCategory: major["second_level_category"],
      ),
      onSubmit: (formData) {
        print('提交的数据: $formData');
      },
    );
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

  void generateAndOpenLink(
      BuildContext context, Map<String, dynamic> item) async {
    final url =
        Uri.parse('http://localhost:8888/static/h5/?majorId=${item['id']}');
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
      final file = File('$directory/majors_selected_$formattedDate.xlsx');
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
          await MajorApi.majorBatchImport(File(file.path!)).then((value) {
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
        var response = await MajorApi.majorList(params: {
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
      final file = File('$directory/majors_all_pages_$formattedDate.xlsx');
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

  void reset() {
    majorDropdownKey.currentState?.reset();
    cateDropdownKey.currentState?.reset();
    levelDropdownKey.currentState?.reset();
    statusDropdownKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    fetchMajors();
    find(size.value, page.value);
  }
}
