import 'package:hongshi_admin/api/classes_api.dart';
import 'package:hongshi_admin/api/job_api.dart';
import 'package:hongshi_admin/ex/ex_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hongshi_admin/api/student_api.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:hongshi_admin/component/dialog.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:url_launcher/url_launcher.dart';
import '../../../../api/institution_api.dart';
import '../../../../api/major_api.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';
import 'student_add_form.dart';
import 'student_edit_form.dart';

class StudentLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;

  final GlobalKey<CascadingDropdownFieldState> majorDropdownKey = GlobalKey<CascadingDropdownFieldState>();
  final GlobalKey<SuggestionTextFieldState> institutionTextFieldKey = GlobalKey<SuggestionTextFieldState>();
  final GlobalKey<SuggestionTextFieldState> classesTextFieldKey = GlobalKey<SuggestionTextFieldState>();

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
  Rx<String> selectedInstitutionId = "0".obs;
  Rx<String> selectedClassesId = "0".obs;

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
        "10.获取专业列表失败".toHint();
      }
    } catch (e) {
      "10.获取专业列表失败: $e".toHint();
    }
  }

  // 当前编辑的题目数据
  var currentEditStudent = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  // 考生列表数据
  Rx<String> selectedProvince = "".obs;
  Rx<String> selectedCityId = "".obs;

  final RxString id = ''.obs;
  final RxString name = ''.obs;
  final RxString phone = ''.obs;
  final RxString institutionId = ''.obs;
  final RxString classId = ''.obs;
  final RxString referrer = ''.obs;
  final RxString jobCode = ''.obs;
  final RxString jobDesc = ''.obs;
  final RxString majorIds = ''.obs;
  final RxString majorNames = ''.obs;
  final RxString status = ''.obs;
  final RxString expireTime = ''.obs;
  final RxString updateTime = ''.obs;

// 如果需要区分新增和更新的变量，可以保留原有的 u 前缀变量
  final RxString uId = ''.obs;
  final RxString uName = ''.obs;
  final RxString uPhone = ''.obs;
  final RxString uPassword = ''.obs;
  final RxString uInstitutionId = ''.obs;
  final RxString uInstitutionName = ''.obs;
  final RxString uClassId = ''.obs;
  final RxString uClassName = ''.obs;
  final RxString uReferrer = ''.obs;
  final RxString uJobCode = ''.obs;
  final RxString uJobName = ''.obs;
  final RxString uJobDesc = ''.obs;
  final RxString uMajorIds = ''.obs;
  final RxString uMajorNames = ''.obs;
  final RxString uStatus = ''.obs;
  final RxString uExpireTime = ''.obs;
  final RxString uUpdateTime = ''.obs;
  final RxList<String> formattedMajorNames = <String>[].obs;
  final RxList<String> formattedJobNames = <String>[].obs;




  void find(int newSize, int newPage) {
    size.value = newSize;
    page.value = newPage;
    list.clear();
    selectedRows.clear();
    loading.value = true;
    // 打印调用堆栈
    try {
      StudentApi.studentList(params: {
        "pageSize": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "major_id": selectedMajorId.value,
        "institution_id": selectedInstitutionId.value,
        "class_id": selectedClassesId.value,
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
    find(size.value, page.value);// Fetch and populate student data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 50),
      ColumnData(title: "姓名", key: "name", width: 80),
      ColumnData(title: "电话", key: "phone", width: 120),
      ColumnData(title: "密码", key: "password", width: 150),
      ColumnData(title: "机构ID", key: "institution_id", width: 0),
      ColumnData(title: "机构名称", key: "institution_name", width: 120),
      ColumnData(title: "班级ID", key: "class_id", width: 0),
      ColumnData(title: "班级名称", key: "class_name", width: 120),
      ColumnData(title: "推荐人", key: "referrer", width: 0),
      ColumnData(title: "岗位编码", key: "job_code", width: 120),
      ColumnData(title: "职位名称", key: "job_name", width: 150),
      ColumnData(title: "职位描述", key: "job_desc", width: 200),
      ColumnData(title: "专业ID", key: "major_ids", width: 0),
      ColumnData(title: "专业名称", key: "major_names", width: 120),
      ColumnData(title: "状态", key: "status_name", width: 80),
      ColumnData(title: "到期时间", key: "expire_time", width: 100),
      ColumnData(title: "更新时间", key: "update_time", width: 0),
    ];
  }

  void add(BuildContext context) {
    DynamicInputDialog.show(
      context: context,
      title: '录入考生',
      child: StudentAddForm(),
      onSubmit: (formData) {
        print('提交的数据: $formData');
      },
    );
  }

  void edit(BuildContext context, Map<String, dynamic> student) {
    currentEditStudent.value = RxMap<String, dynamic>(student);

    DynamicInputDialog.show(
      context: context,
      title: '录入考生',
      child: StudentEditForm(
        studentId: student["id"],
        initialName: student["name"],
        initialPhone: student["phone"],
        initialInstitutionId: student["institution_id"].toString(),
        initialInstitutionName: student["institution_name"],
        initialClassId: student["class_id"].toString(),
        initialClassName: student["class_name"],
        initialReferrer: student["referrer"],
        initialJobCode: student["job_code"],
        initialJobName: student["job_name"],
        initialJobDesc: student["job_desc"],
        initialMajorIds: List<String>.from(student["major_ids"]),
        initialMajorNames: List<String>.from(student["major_names"]),
        initialExpireTime: student["expire_time"],
        initialStatus: student["status"].toString(),
      ),
      onSubmit: (formData) {
        print('提交的数据: $formData');
      },
    );
  }


  Future<bool> saveStudent() async {
    final nameSubmit = name.value;
    final phoneSubmit = phone.value;
    final institutionIdSubmit = institutionId.value;
    final classIdSubmit = classId.value;
    final referrerSubmit = referrer.value;
    final jobCodeSubmit = jobCode.value;
    final majorIdsSubmit = majorIds.value;
    final statusSubmit = status.value;
    // final expireTimeSubmit = expireTime.value;

    bool isValid = true;
    String errorMessage = "";

    if (nameSubmit.isEmpty) {
      isValid = false;
      errorMessage += "考生名称不能为空\n";
    }
    if (phoneSubmit.isEmpty) {
      isValid = false;
      errorMessage += "电话不能为空\n";
    }
    if (classIdSubmit.isEmpty) {
      isValid = false;
      errorMessage += "班级ID不能为空\n";
    }
    if (jobCodeSubmit.isEmpty) {
      isValid = false;
      errorMessage += "岗位代码不能为空\n";
    }
    if (majorIdsSubmit.isEmpty) {
      isValid = false;
      errorMessage += "专业ID不能为空\n";
    }
    if (statusSubmit.isEmpty) {
      isValid = false;
      errorMessage += "考生状态不能为空\n";
    }


    if (isValid) {
      try {
        Map<String, dynamic> params = {
          "name": nameSubmit,
          "phone": phoneSubmit,
          "institution_id": int.parse(institutionIdSubmit),
          "class_id": int.parse(classIdSubmit),
          "referrer": referrerSubmit,
          "job_code": jobCodeSubmit,
          "major_ids": majorIdsSubmit,
          "status_name": statusSubmit,
          "status": int.parse(statusSubmit),
        };

        dynamic result = await StudentApi.studentCreate(params);
        if (result['id'] > 0) {
          "创建考生成功".toHint();
          return true;
        } else {
          "创建考生失败".toHint();
          return false;
        }
      } catch (e) {
        print('Error: $e');
        "创建考生时发生错误：$e".toHint();
        return false;
      }
    } else {
      // 显示错误提示
      errorMessage.toHint();
      return false;
    }
  }


  Future<bool> updateStudent(int studentId) async {
    final uNameSubmit = uName.value;
    final uPhoneSubmit = uPhone.value;
    final uInstitutionIdSubmit = uInstitutionId.value;
    final uInstitutionNameSubmit = uInstitutionName.value;
    final uClassIdSubmit = uClassId.value;
    final uClassNameSubmit = uClassName.value;
    final uReferrerSubmit = uReferrer.value;
    final uJobCodeSubmit = uJobCode.value;
    final uJobNameSubmit = uJobName.value;
    final uJobDescSubmit = uJobDesc.value;
    final uMajorIdsSubmit = uMajorIds.value;
    final uMajorNamesSubmit = uMajorNames.value;
    final uStatusNameSubmit = uStatus.value;
    final uExpireTimeSubmit = uExpireTime.value;
    final uStatusSubmit = uStatus.value;

    bool isValid = true;
    String errorMessage = "";

    if (uNameSubmit.isEmpty) {
      isValid = false;
      errorMessage += "考生名称不能为空\n";
    }
    if (uPhoneSubmit.isEmpty) {
      isValid = false;
      errorMessage += "电话不能为空\n";
    }

    if (isValid) {
      try {
        Map<String, dynamic> params = {
          "name": uNameSubmit,
          "phone": uPhoneSubmit,
          "institution_id": int.parse(uInstitutionIdSubmit),
          "institution_name": uInstitutionNameSubmit,
          "class_id": int.parse(uClassIdSubmit),
          "class_name": uClassNameSubmit,
          "referrer": uReferrerSubmit,
          "job_code": uJobCodeSubmit,
          "job_name": uJobNameSubmit,
          "job_desc": uJobDescSubmit,
          "major_ids": uMajorIdsSubmit,
          "major_names": uMajorNamesSubmit,
          "status_name": uStatusNameSubmit,
          "expire_time": uExpireTimeSubmit,
          "status": int.parse(uStatusSubmit),
        };

        dynamic result = await StudentApi.studentUpdate(studentId, params);
        "更新考生成功".toHint();
        return true;
      } catch (e) {
        print('Error: $e');
        "更新考生时发生错误：$e".toHint();
        return false;
      }
    } else {
      // 显示错误提示
      errorMessage.toHint();
      return false;
    }
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
        final List<Map<String, dynamic>> suggestions = data.whereType<Map>().map((item) {
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

  Future<String> fetchMajor(String id) async {
    try {
      final response = await MajorApi.majorDetail(id);
      if (response['id'] > 0) {
        return "${response['major_name']}(ID：${response['id']})";
      } else {
        // Handle the case where data is not a List
        return "";
      }
    } catch (e) {
      // Handle any exceptions that are thrown
      print('Error fetching classes: $e');
      return "";
    }
  }

  Future<String> fetchJob(String code) async {
    try {
      final response = await JobApi.jobDetailByCode(code);
      if (response != null && response["list"].length > 0) {
          var data = response["list"][0];
        return "${data['name']}(ID：${data['code']})";
      } else {
        // Handle the case where data is not a List
        return "";
      }
    } catch (e) {
      // Handle any exceptions that are thrown
      print('Error fetching jobs: $e');
      return "";
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
      final file = File('$directory/students_selected_$formattedDate.xlsx');
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
          await StudentApi.studentBatchImport(File(file.path!)).then((value) {
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
        var response = await StudentApi.studentList(params:{
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
      final file = File('$directory/students_all_pages_$formattedDate.xlsx');
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
        "请先选择要删除的考生".toHint();
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
    institutionTextFieldKey.currentState?.reset();
    classesTextFieldKey.currentState?.reset();
    majorDropdownKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    find(size.value, page.value);
  }
}
