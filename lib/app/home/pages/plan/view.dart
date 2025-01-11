import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:hongshi_admin/component/pagination/view.dart';
import 'package:hongshi_admin/component/table/ex.dart';
import 'package:hongshi_admin/app/home/sidebar/logic.dart';
import 'logic.dart';
import 'package:hongshi_admin/app/home/pages/plan/logic.dart';
import 'package:hongshi_admin/theme/theme_util.dart';

class PlanPage extends StatelessWidget {
  final logic = Get.put(PlanLogic());
  final planLogic = Get.find<PlanLogic>();

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
                source: PlanDataSource(logic: logic),
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
            uniqueId: 'topic_pagination',
            total: logic.total.value,
            changed: (size, page) => logic.find(size, page),
          );
        })
      ],
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "计划管理",
      icon: Icons.app_registration_outlined,
      page: PlanPage(),
    );
  }
}

class PlanDataSource extends DataGridSource {
  final PlanLogic logic;
  final PlanLogic planLogic = Get.find<PlanLogic>();
  List<DataGridRow> _rows = [];

  PlanDataSource({required this.logic}) {
    _buildRows();
  }

  void _buildRows() {
    _rows = logic.list.map<DataGridRow>((data) {
      return DataGridRow(
        cells: [
          DataGridCell<bool>(columnName: 'Select', value: logic.selectedRows.contains(data['id'])),
          ...logic.columns.map<DataGridCell>((column) {
            // 确保所有值都被转换为字符串
            return DataGridCell<String>(columnName: column.key, value: data[column.key]?.toString() ?? '');
          }),
          DataGridCell<String>(columnName: 'Actions', value: data['id'].toString()),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
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
        } else if (dataGridCell.columnName == 'plan_name') {
          final currentValue = dataGridCell.value?.toString() ?? '';
          return Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: currentValue,
              items: [
                DropdownMenuItem<String>(
                  value: currentValue,
                  child: Text(currentValue),
                ),
                ...planLogic.list
                    .where((plan) => plan['name'].toString() != currentValue)
                    .take(5)
                    .map((plan) {
                  return DropdownMenuItem<String>(
                    value: plan['name'].toString(),
                    child: Text(plan['name'].toString()),
                  );
                }).toList(),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  final rowIndex = _rows.indexOf(row);
                  final planId = planLogic.list
                      .firstWhere((plan) => plan['name'] == newValue)['id'];
                  logic.list[rowIndex]['plan_name'] = newValue;
                  logic.list[rowIndex]['plan_id'] = planId;
                  _buildRows();
                  notifyListeners();
                  // 如果需要，这里可以添加一个API调用来更新后端数据
                  // logic.updatePlanplan(logic.list[rowIndex]['id'], planId);
                }
              },
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