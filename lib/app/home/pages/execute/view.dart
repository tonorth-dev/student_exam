import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:hongshi_admin/component/pagination/view.dart';
import 'package:hongshi_admin/component/table/ex.dart';
import 'package:hongshi_admin/app/home/sidebar/logic.dart';
import 'logic.dart';
import 'package:hongshi_admin/app/home/pages/execute/logic.dart';
import 'package:hongshi_admin/theme/theme_util.dart';

class ExecutePage extends StatelessWidget {
  final logic = Get.put(ExecuteLogic());
  final ExecuteLogic executeLogic = Get.find<ExecuteLogic>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableEx.actions(
          children: [
            ThemeUtil.width(width: 50),
            SizedBox(
              width: 150,
              child: Obx(() => DropdownButton<String?>(
                value: logic.selectedMajor.value,
                hint: Text('选择专业'),
                isExpanded: true,
                onChanged: (String? newValue) {
                  logic.selectedMajor.value = logic.majorList.isNotEmpty? logic.majorList[0] : null;
                  logic.applyFilters();
                },
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('全部专业'),
                  ),
                  ...logic.majorList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ],
              )),
            ),
            ThemeUtil.width(),

// 添加题型筛选下拉列表
            SizedBox(
              width: 150,
              child: Obx(() => DropdownButton<String?>(
                value: logic.selectedQuestionType.value,
                hint: Text('选择题型'),
                isExpanded: true,
                onChanged: (String? newValue) {
                  logic.selectedQuestionType.value = logic.questionTypeList.isNotEmpty? logic.questionTypeList[0] : null;
                  logic.applyFilters();
                },
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('全部题型'),
                  ),
                  ...logic.questionTypeList.map<DropdownMenuItem<String?>>((String value) {
                    return DropdownMenuItem<String?>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ],
              )),
            ),
            ThemeUtil.width(),
            SizedBox(
              width: 260,
              child: TextField(
                key: const Key('search_box'),
                decoration: const InputDecoration(
                  hintText: '计划名称',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => logic.search(value),
              ),
            ),
            ThemeUtil.width(),
            ElevatedButton(
              onPressed: () => logic.search(""),
              child: const Text("搜索"),
            ),
            const Spacer(),
            FilledButton(
              onPressed: logic.add,
              child: const Text("新增"),
            ),
            FilledButton(
              onPressed: () => logic.batchDelete(logic.selectedRows),
              child: const Text("批量删除"),
            ),
            FilledButton(
              onPressed: logic.exportCurrentPageToCSV,
              child: const Text("导出当前页"),
            ),
            FilledButton(
              onPressed: logic.exportAllToCSV,
              child: const Text("导出全部"),
            ),
            FilledButton(
              onPressed: logic.importFromCSV,
              child: const Text("从 CSV 导入"),
            ),
            ThemeUtil.width(width: 30),
          ],
        ),
        ThemeUtil.lineH(),
        ThemeUtil.height(),
        Expanded(
          child: Obx(() => logic.loading.value
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: 1600,
              height: Get.height,
              child: SfDataGrid(
                source: ExecuteDataSource(logic: logic),
                headerGridLinesVisibility: GridLinesVisibility.values[1],
                columnWidthMode: ColumnWidthMode.fill,
                headerRowHeight: 50,
                columns: [
                  GridColumn(
                    columnName: 'Select',
                    label: Container(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                        ),
                        child: Center(
                          child: Checkbox(
                            value: logic.selectedRows.length == logic.list.length,
                            onChanged: (value) => logic.toggleSelectAll(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...logic.columns.map((column) => GridColumn(
                    width: 120,
                    columnName: column.key,
                    label: Container(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                        ),
                        child: Center(
                          child: Text(
                            column.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
                  GridColumn(
                    columnName: 'Actions',
                    width: 0,
                    label: Container(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                        ),
                        child: Center(
                          child: Text(
                            '操作',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ),
        Obx(() {
          return PaginationPage(
            uniqueId: 'book_pagination',
            total: logic.total.value,
            changed: (size, page) => logic.find(size, page),
          );
        })
      ],
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "计划执行明细",
      icon: Icons.app_registration_outlined,
      page: ExecutePage(),
    );
  }
}

class ExecuteDataSource extends DataGridSource {
  final ExecuteLogic logic;
  final ExecuteLogic executeLogic = Get.find<ExecuteLogic>();
  List<DataGridRow> _rows = [];

  ExecuteDataSource({required this.logic}) {
    _buildRows();
  }

  void _buildRows() {
    _rows = logic.list.map<DataGridRow>((data) {
      return DataGridRow(
        cells: [
          DataGridCell<bool>(columnName: 'Select', value: logic.selectedRows.contains(data['id'])),
          // 修改这部分代码，将指定列改为按钮
          ...logic.columns.map<DataGridCell>((column) {
            if (column.key != 'ext_questions_json') {
              return DataGridCell<String>(columnName: column.key, value: data[column.key]?.toString()?? '');
            } else {
              return DataGridCell<Widget>(columnName: column.key, value: _buildButton(data[column.key].toString()));
            }
          }),
          DataGridCell<String>(columnName: 'Actions', value: data['id'].toString()),
        ],
      );
    }).toList();
  }

  Widget _buildButton(String? jsonData) {
    if (jsonData!= null && jsonData.isNotEmpty) {
      try {
        var decodedData = jsonDecode(jsonData);
        if (decodedData is List<dynamic>) {
          // 定义表头
          final headers = ['id', 'question_text', 'answer', 'specialty_id', 'question_type', 'entry_person', 'created_time', 'answer_time', 'answer_student', 'create_time'];
          final headersCN = ['ID', '问题', '答案', '专业ID', '题型', '班级名称', '创建时间', '练习次数', '练习考生', '创建时间'];
          return ElevatedButton(
            onPressed: () {
              showDialog(
                context: Get.context!,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('执行明细'),
                    content: SingleChildScrollView(
                      child: SizedBox(
                        width: 1000,
                        child: Table(
                          border: TableBorder.all(),
                          // 添加表头行
                          children: [
                            TableRow(
                              children: headersCN.map((header) => TableCell(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(header),
                                ),
                              )).toList(),
                            ),
                            // 数据行
                            ...decodedData.map((item) {
                              if (item is Map<String, dynamic>) {
                                return TableRow(
                                  children: headers.map((header) => TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(item[header]?.toString()?? ''),
                                    ),
                                  )).toList(),
                                );
                              } else {
                                return TableRow(
                                  children: [
                                    TableCell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('无法解析的项'),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('关闭'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('执行明细'),
          );
        } else {
          return ElevatedButton(
            onPressed: null,
            child: const Text('不是列表数据，无法解析'),
          );
        }
      } catch (e) {
        return ElevatedButton(
          onPressed: null,
          child: const Text('无法解析数据'),
        );
      }
    } else {
      return ElevatedButton(
        onPressed: null,
        child: const Text('不是有效的数据格式'),
      );
    }
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((dataGridCell) {
        if (dataGridCell.columnName == 'Select') {
          return Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(8.0),
            child: Checkbox(
              value: dataGridCell.value,
              onChanged: (bool? value) {
                final rowIndex = _rows.indexOf(row);
                logic.toggleSelect(rowIndex);
                notifyListeners();
              },
            ),
          );
        } else if (dataGridCell.columnName == 'execute_name') {
          return Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: dataGridCell.value?.toString() ?? '',
              onChanged: (String? newValue) {
                final rowIndex = _rows.indexOf(row);
                logic.modify(rowIndex as Map<String, dynamic>, newValue as int);
                notifyListeners();
              }, items: [],
            ),
          );
        } else if (dataGridCell.columnName == 'Actions') {
          return Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => logic.modify(dataGridCell.value, 1),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => logic.delete(dataGridCell.value, 1),
                ),
              ],
            ),
          );
        } else if (dataGridCell.columnName == 'ext_questions_json') {
          return dataGridCell.value as Widget;
        } else {
          return Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(dataGridCell.value.toString()),
          );
        }
      }).toList(),
    );
  }

  void updateDataSource() {
    _buildRows();
    notifyListeners();
  }
}