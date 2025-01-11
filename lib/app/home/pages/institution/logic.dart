import 'package:admin_flutter/app/home/pages/book/book.dart';
import 'package:admin_flutter/ex/ex_list.dart';
import 'package:admin_flutter/ex/ex_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin_flutter/api/institution_api.dart';
import 'package:admin_flutter/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:admin_flutter/component/form/enum.dart';
import 'package:admin_flutter/component/form/form_data.dart';
import 'package:admin_flutter/component/dialog.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:url_launcher/url_launcher.dart';
import '../../../../api/config_api.dart';
import '../../../../api/institution_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import 'institution_add_form.dart';
import 'institution_edit_form.dart';

class InstitutionLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;

  final GlobalKey<ProvinceCityDistrictSelectorState> provinceCityDistrictKey = GlobalKey<ProvinceCityDistrictSelectorState>();

  // 当前编辑的题目数据
  var currentEditInstitution = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  // 机构列表数据
  Rx<String> selectedProvince = "".obs;
  Rx<String> selectedCityId = "".obs;

  final RxString name = ''.obs;
  final RxString province = ''.obs;
  final RxString city = ''.obs;
  final RxString password = ''.obs;
  final RxString leader = ''.obs;
  final RxString status = '2'.obs;

  final uName = ''.obs;
  final uProvince = ''.obs;
  final uCity = ''.obs;
  final uPassword = ''.obs;
  final uLeader = ''.obs;
  final uStatus = '2'.obs;


  void find(int newSize, int newPage) {
    size.value = newSize;
    page.value = newPage;
    list.clear();
    selectedRows.clear();
    loading.value = true;
    // 打印调用堆栈
    try {
      InstitutionApi.institutionList(params: {
        "pageSize": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "province": selectedProvince.value,
        "city": selectedCityId.value,
      }).then((value) async {
        if (value != null && value["list"] != null) {
          total.value = value["total"] ?? 0;
          list.assignAll((value["list"] as List<dynamic>).toListMap());
          await Future.delayed(const Duration(milliseconds: 300));
          loading.value = false;
        } else {
          loading.value = false;
          "未获取到机构数据".toHint();
        }
      }).catchError((error) {
        loading.value = false;
        print("获取机构列表失败: $error");
        "获取机构列表失败: $error".toHint();
      });
    } catch (e) {
      loading.value = false;
      print("获取机构列表失败: $e");
      "获取机构列表失败: $e".toHint();
    }
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    super.onInit();
    find(size.value, page.value);// Fetch and populate institution data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 80),
      ColumnData(title: "名称", key: "name", width: 200),
      ColumnData(title: "省份", key: "province_name", width: 200),
      ColumnData(title: "城市", key: "city_name", width: 200),
      ColumnData(title: "密码", key: "password", width: 200),
      ColumnData(title: "负责人", key: "leader", width: 200),
      ColumnData(title: "状态", key: "status_name", width: 100),
      ColumnData(title: "入驻时间", key: "create_time", width: 200),
    ];
  }

  void add(BuildContext context) {
    DynamicInputDialog.show(
      context: context,
      title: '录入机构',
      child: InstitutionAddForm(),
      onSubmit: (formData) {
        print('提交的数据: $formData');
      },
    );
  }

  void edit(BuildContext context, Map<String, dynamic> institution) {
    currentEditInstitution.value = RxMap<String, dynamic>(institution);

    DynamicInputDialog.show(
      context: context,
      title: '录入机构',
      child: InstitutionEditForm(
        institutionId: institution["id"],
        initialName: institution["name"],
        initialProvince: institution["province"],
        initialCity: institution["city"],
        initialPassword: institution["password"],
        initialLeader: institution["leader"],
        initialStatus: institution["status"].toString(),
      ),
      onSubmit: (formData) {
        print('提交的数据: $formData');
      },
    );
  }


  Future<bool> saveInstitution() async {
    final nameSubmit = name.value;
    final provinceSubmit = province.value;
    final citySubmit = city.value;
    final leaderSubmit = leader.value;
    final statusSubmit = status.value;

    bool isValid = true;
    String errorMessage = "";

    if (nameSubmit.isEmpty) {
      isValid = false;
      errorMessage += "机构名称不能为空\n";
    }
    if (provinceSubmit.isEmpty) {
      isValid = false;
      errorMessage += "省份不能为空\n";
    }
    if (citySubmit.isEmpty) {
      isValid = false;
      errorMessage += "城市不能为空\n";
    }
    if (leaderSubmit.isEmpty) {
      isValid = false;
      errorMessage += "负责人不能为空\n";
    }

    if (isValid) {
      try {
        Map<String, dynamic> params = {
          "name": nameSubmit,
          "province": provinceSubmit,
          "city": citySubmit,
          "leader": leaderSubmit,
          "status": int.parse(statusSubmit),
        };

        dynamic result = await InstitutionApi.institutionCreate(params);
        if (result['id'] > 0) {
          "创建机构成功".toHint();
          return true;
        } else {
          "创建机构失败".toHint();
          return false;
        }
      } catch (e) {
        print('Error: $e');
        "创建机构时发生错误：$e".toHint();
        return false;
      }
    } else {
      // 显示错误提示
      errorMessage.toHint();
      return false;
    }
  }



  Future<bool> updateInstitution(int institutionId) async {
    // 生成题本的逻辑
    final uNameSubmit = uName.value;
    final uProvinceSubmit = uProvince.value;
    final uCitySubmit = uCity.value;
    final uLeaderSubmit = uLeader.value;
    final uStatusSubmit = uStatus.value;

    bool isValid = true;
    String errorMessage = "";

    if (uNameSubmit.isEmpty) {
      isValid = false;
      errorMessage += "机构名称不能为空\n";
    }
    if (uProvinceSubmit.isEmpty) {
      isValid = false;
      errorMessage += "省份不能为空\n";
    }
    if (uCitySubmit.isEmpty) {
      isValid = false;
      errorMessage += "城市不能为空\n";
    }
    if (uLeaderSubmit.isEmpty) {
      isValid = false;
      errorMessage += "负责人不能为空\n";
    }

    if (isValid) {
      try {
        Map<String, dynamic> params = {
          "name": uNameSubmit,
          "province": uProvinceSubmit,
          "city": uCitySubmit,
          "leader": uLeaderSubmit,
          "status": int.parse(uStatusSubmit),
        };

        dynamic result = await InstitutionApi.institutionUpdate(institutionId, params);
        "更新机构成功".toHint();
        return true;
      } catch (e) {
        print('Error: $e');
        "更新机构时发生错误：$e".toHint();
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
      InstitutionApi.institutionDelete(d["id"].toString()).then((value) {
        list.removeAt(index);
      }).catchError((error) {
        "删除失败: $error".toHint();
      });
    } catch (e) {
      "删除失败: $e".toHint();
    }
  }

  Future<void> audit(int institutionId, int status) async {
    try {
      await InstitutionApi.auditInstitution(institutionId, status);
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
      final file = File('$directory/institutions_selected_$formattedDate.xlsx');
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
          await InstitutionApi.institutionBatchImport(File(file.path!)).then((value) {
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
        var response = await InstitutionApi.institutionList(params: {
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
      final file = File('$directory/institutions_all_pages_$formattedDate.xlsx');
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
        "请先选择要删除的机构".toHint();
        return;
      }
      InstitutionApi.institutionDelete(idsStr.join(",")).then((value) {
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
    provinceCityDistrictKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    find(size.value, page.value);
  }
}
