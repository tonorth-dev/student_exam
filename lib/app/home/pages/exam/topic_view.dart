import 'package:hongshi_admin/app/home/pages/exam/topic_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:hongshi_admin/component/pagination/view.dart';
import 'package:hongshi_admin/component/table/ex.dart';
import 'package:hongshi_admin/app/home/sidebar/logic.dart';
import 'package:hongshi_admin/component/widget.dart';
import 'package:hongshi_admin/component/dialog.dart';
import 'logic.dart';
import 'package:hongshi_admin/theme/theme_util.dart';
import 'package:provider/provider.dart';

class ExamTopicView extends StatelessWidget {
  final String title;
  final int id;

  const ExamTopicView({Key? key, required this.id, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("ExamTopicView id: $id");
    Get.replace<ExamTopicLogic>(ExamTopicLogic(id));
    final logic = Get.find<ExamTopicLogic>();

    return Scaffold( // 使用 Scaffold 包裹
        appBar: AppBar(
          title: Text(title),
        ),
        body:ChangeNotifierProvider<ButtonState>(
      create: (_) => ButtonState(),
      child: Column(
        children: [
          TableEx.actions(
            children: [
              SizedBox(width: 30), // 添加一些间距
              SearchBoxWidget(
                key: Key('keywords'),
                hint: '岗位代码、岗位名称、单位序号、单位名称',
                onTextChanged: (String value) {
                  logic.searchText.value = value;
                },
                searchText: logic.searchText,
              ),
              SizedBox(width: 10),
              SearchButtonWidget(
                key: Key('search'),
                onPressed: () {
                  logic.selectedRows.clear();
                  logic.find();
                },
              ),
              SizedBox(width: 8),
              ResetButtonWidget(
                key: Key('reset'),
                onPressed: () {
                  logic.reset();
                  logic.find();
                },
              ),
            ],
          ),
          ThemeUtil.lineH(),
          ThemeUtil.height(),
          Expanded(
            child: Obx(() => logic.loading.value
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1700,
                child: Obx(()=> SfDataGrid( // Wrap with Obx
                  source: ExamTopicDataSource(logic: logic, context: context),
                  columns: logic.columns.value, // Use the observable list of columns
                  headerGridLinesVisibility: GridLinesVisibility.values[1],
                  gridLinesVisibility: GridLinesVisibility.values[1],
                  columnWidthMode: ColumnWidthMode.fill,
                  headerRowHeight: 50,
                  rowHeight: 60,
                )),
              ),
            )),
          ),
          ThemeUtil.height(height: 30),
        ],
      ),
    ));
  }
}

class ExamTopicDataSource extends DataGridSource {
  final ExamTopicLogic logic;
  final BuildContext context;
  List<DataGridRow> _rows = [];
  Map<int, bool> _expandedUnits = {};

  ExamTopicDataSource({required this.logic, required this.context}) {
    _buildRows();
  }

  void _buildRows() {
    _rows.clear();
    for (var unit in logic.unitList) {
      // Initialize unit as collapsed if not yet in _expandedUnits
      _expandedUnits.putIfAbsent(unit.id, () => false);

      // Unit Row
      _rows.add(DataGridRow(cells: [
        DataGridCell(columnName: 'ID', value: unit.id),
        DataGridCell(columnName: '试卷名称', value: unit.examName),
        DataGridCell(columnName: '班级名称', value: unit.className),
        DataGridCell(columnName: '考生名称', value: unit.studentName),
        // Placeholder for topic-specific columns
        DataGridCell(columnName: '试题', value: null),
        DataGridCell(columnName: '答案', value: null),
        DataGridCell(columnName: '专业名称', value: null),
        DataGridCell(columnName: '练习状态', value: null),
        DataGridCell(columnName: '练习时间', value: null),
        DataGridCell(columnName: '操作', value: unit),
      ]));

      // Topic Rows (only if unit is expanded)
      if (_expandedUnits[unit.id] ?? false) {
        for (var topic in unit.topics) {
          _rows.add(DataGridRow(cells: [
            DataGridCell(columnName: 'ID', value: topic.topicId),
            DataGridCell(columnName: '试卷名称', value: topic.examName),
            DataGridCell(columnName: '班级名称', value: topic.className),
            DataGridCell(columnName: '考生名称', value: topic.studentName),
            DataGridCell(columnName: '试题', value: topic.topicTitle),
            DataGridCell(columnName: '答案', value: topic.topicAnswer),
            DataGridCell(columnName: '专业名称', value: topic.majorName),
            DataGridCell(columnName: '练习状态', value: topic.statusName),
            DataGridCell(columnName: '练习时间', value: topic.practiceTime),
            DataGridCell(columnName: '操作', value: topic),
          ]));
        }
      }
    }
  }

  @override
  List<DataGridRow> get rows => _rows;
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = _rows.indexOf(row);
    final isUnitRow = logic.unitList.any((unit) => unit.id == row.getCells()[0].value);
    int indentation = isUnitRow ? 0 : 1; // Indentation for topics

    if (isUnitRow) {
      // 单元行合并所有单元格
      final unit = logic.unitList.firstWhere((unit) => unit.id == row.getCells()[0].value);
      return DataGridRowAdapter(
        color: index.isEven ? Color(0x50F1FDFC) : Colors.white,
        cells: [
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _expandedUnits[unit.id] ?? false
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  onPressed: () {
                    _toggleUnit(unit);
                  },
                ),
                Expanded(
                  child: Text(
                    "${unit.examName} - ${unit.className} - ${unit.studentName}",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // 普通行
      return DataGridRowAdapter(
        color: index.isEven ? Color(0x50F1FDFC) : Colors.white,
        cells: row.getCells().asMap().entries.map((entry) {
          final cellIndex = entry.key;
          final cell = entry.value;
          if (cell.columnName == '操作') {
            // Topic-specific operations
            return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(left: indentation * 20.0, right: 8.0, top: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HoverTextButton(
                    text: "重置试题",
                    onTap: () async {
                      // Reset topic logic
                    },
                  ),
                  SizedBox(width: 5),
                ],
              ),
            );
          } else {
            return Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: indentation * 20.0, right: 8.0, top: 8.0, bottom: 8.0),
              child: Text(
                cell.value?.toString() ?? '',
                style: TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }
        }).toList(),
      );
    }
  }

  void _toggleUnit(Unit unit) {
    _expandedUnits[unit.id] = !(_expandedUnits[unit.id] ?? false);
    _buildRows();  // Rebuild rows to update visibility
    notifyListeners(); // Notify datagrid to refresh
  }
}