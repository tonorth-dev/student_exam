// import 'package:admin_flutter/ex/ex_hint.dart';
// import 'package:admin_flutter/ex/ex_list.dart';
// import 'package:get/get.dart';
// import 'package:admin_flutter/component/table/table_data.dart';
// import 'package:admin_flutter/api/question_api.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
// import 'dart:convert';
// import 'package:csv/csv.dart';
// import 'package:admin_flutter/component/form/enum.dart';
// import 'package:admin_flutter/component/form/form_data.dart';
//
// class QuestionLogic extends GetxController {
//   var list = <Map<String, dynamic>>[].obs;
//   var total = 0.obs;
//   var size = 0;
//   var page = 0;
//   var loading = false.obs;
//   RxList<int> selectedRows = <int>[].obs;
//
//   void find(int size, int page) {
//     this.size = size;
//     this.page = page;
//     list.clear();
//     loading.value = true;
//     QuestionApi.questionList(params: {
//       "size": size,
//       "page": page,
//     }).then((value) async {
//       total.value = value["total"];
//       list.addAll((value["list"] as List<dynamic>).toListMap());
//       list.refresh();
//       print('question Data loaded: ${list}');
//       await Future.delayed(const Duration(milliseconds: 300));
//       loading.value = false;
//     });
//   }
//
//   var columns = <ColumnData>[];
//
//   @override
//   void onInit() {
//     super.onInit();
//     columns = [
//       ColumnData(title: "问题ID", key: "id", width: 80),
//       ColumnData(title: "问题内容", key: "question_text"),
//       ColumnData(title: "答案", key: "answer"),
//       ColumnData(title: "专业ID", key: "specialty_id"),
//       ColumnData(title: "问题类型", key: "question_type"),
//       ColumnData(title: "录入人", key: "entry_person"),
//       ColumnData(title: "创建时间", key: "created_time"),
//     ];
//   }
//
//   var form = FormDto(labelWidth: 80, columns: [
//     FormColumnDto(
//       label: "问题内容",
//       key: "question_text",
//       placeholder: "请输入问题内容",
//     ),
//     FormColumnDto(
//       label: "答案",
//       key: "answer",
//       placeholder: "请输入答案",
//     ),
//     FormColumnDto(
//       label: "专业ID",
//       key: "specialty_id",
//       placeholder: "请输入专业ID",
//     ),
//     FormColumnDto(
//       label: "问题类型",
//       key: "question_type",
//       placeholder: "请选择问题类型",
//       type: FormColumnEnum.select,
//       options: [
//         {"label": "简答题", "value": "简答题"},
//         {"label": "选择题", "value": "选择题"},
//         {"label": "判断题", "value": "判断题"},
//       ],
//     ),
//     FormColumnDto(
//       label: "录入人",
//       key: "entry_person",
//       placeholder: "请输入录入人",
//     ),
//   ]);
//
//   void add() {
//     form.add(
//         reset: true,
//         submit: (data) => {
//           QuestionApi.questionInsert(params: data).then((value) {
//             "插入成功!".toHint();
//             find(size, page);
//             Get.back();
//           })
//         });
//   }
//
//   void modify(Map<String, dynamic> d, int index) {
//     form.data = d;
//     form.edit(
//         submit: (data) => {
//           QuestionApi.questionUpdate(params: data).then((value) {
//             "更新成功!".toHint();
//             list.removeAt(index);
//             list.insert(index, data);
//             Get.back();
//           })
//         });
//   }
//
//   void delete(Map<String, dynamic> d, int index) {
//     QuestionApi.questionDelete(params: {"id": d["id"]}).then((value) {
//       list.removeAt(index);
//     });
//   }
//
//   void search(String key) {
//     QuestionApi.questionSearch(params: {"key": key}).then((value) {
//       refresh();
//     });
//   }
//
//   void refresh() {
//     find(size, page);
//   }
//
//   Future<void> exportCurrentPageToCSV() async {
//     final directory = await FilePicker.platform.getDirectoryPath();
//     if (directory == null) return;
//
//     List<List<dynamic>> rows = [];
//     rows.add(columns.map((column) => column.title).toList());
//
//     for (var item in list) {
//       rows.add(columns.map((column) => item[column.key]).toList());
//     }
//
//     String csv = const ListToCsvConverter().convert(rows);
//     File('$directory/questions_current_page.csv').writeAsStringSync(csv);
//     "导出当前页成功!".toHint();
//   }
//
//   Future<void> exportAllToCSV() async {
//     final directory = await FilePicker.platform.getDirectoryPath();
//     if (directory == null) return;
//
//     List<Map<String, dynamic>> allItems = [];
//     int currentPage = 1;
//     int pageSize = 100;
//
//     while (true) {
//       var response = await QuestionApi.questionList(params: {
//         "size": pageSize,
//         "page": currentPage,
//       });
//
//       allItems.addAll((response["list"] as List<dynamic>).toListMap());
//
//       if (allItems.length >= response["total"]) break;
//       currentPage++;
//     }
//
//     List<List<dynamic>> rows = [];
//     rows.add(columns.map((column) => column.title).toList());
//
//     for (var item in allItems) {
//       rows.add(columns.map((column) => item[column.key]).toList());
//     }
//
//     String csv = const ListToCsvConverter().convert(rows);
//     File('$directory/questions_all_pages.csv').writeAsStringSync(csv);
//     "导出全部成功!".toHint();
//   }
//
//   void importFromCSV() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
//     if (result != null) {
//       PlatformFile file = result.files.first;
//       String content = utf8.decode(file.bytes!);
//
//       List<List<dynamic>> rows = const CsvToListConverter().convert(content);
//       rows.removeAt(0); // 移除表头
//
//       for (var row in rows) {
//         Map<String, dynamic> data = {};
//         for (int i = 0; i < columns.length; i++) {
//           data[columns[i].key] = row[i];
//         }
//         QuestionApi.questionInsert(params: data).then((value) {
//           "导入成功!".toHint();
//           find(size, page);
//         }).catchError((error) {
//           "导入失败: $error".toHint();
//         });
//       }
//     }
//   }
//
//   void batchDelete(List<int> d) {
//     print(List);
//   }
//
//   void toggleSelectAll() {
//     selectedRows.length == list.length ? selectedRows.clear() : selectedRows.addAll(list.map((item) => item['id']));
//   }
//
//   void toggleSelect(int index) {
//     selectedRows.contains(index) ? selectedRows.remove(index) : selectedRows.add(index);
//   }
// }