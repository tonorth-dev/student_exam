import 'package:admin_flutter/ex/ex_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:admin_flutter/component/pagination/view.dart';
import 'package:admin_flutter/component/table/ex.dart';
import 'package:admin_flutter/app/home/sidebar/logic.dart';
import 'package:admin_flutter/component/widget.dart';
import 'package:admin_flutter/component/dialog.dart';
import 'logic.dart';
import 'package:admin_flutter/theme/theme_util.dart';
import 'package:provider/provider.dart';

class NoteTableView extends StatelessWidget {
  final String title;
  final NoteLogic logic;

  const NoteTableView({super.key, required this.title, required this.logic});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ButtonState>(
      create: (_) => ButtonState(),
      child: Column(
        children: [
          TableEx.actions(
            children: [
              SizedBox(width: 30), // 添加一些间距
              Container(
                height: 50,
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade300],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 260), // 添加一些间距
              SearchBoxWidget(
                key: Key('keywords'),
                hint: '题本名称、创建者',
                width: 200,
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
                  logic.find(logic.size.value, logic.page.value);
                },
              ),
              SizedBox(width: 8),
              ResetButtonWidget(
                key: Key('reset'),
                onPressed: () {
                  logic.reset();
                  logic.find(logic.size.value, logic.page.value);
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
                      child: SfDataGrid(
                        source: NoteDataSource(logic: logic, context: context),
                        headerGridLinesVisibility:
                            GridLinesVisibility.values[1],
                        gridLinesVisibility: GridLinesVisibility.values[1],
                        columnWidthMode: ColumnWidthMode.fill,
                        headerRowHeight: 50,
                        rowHeight: 60,
                        columns: [
                          GridColumn(
                            columnName: 'Select',
                            width: 60,
                            label: Container(
                              color: Color(0xFFF3F4F8),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8.0),
                              child: Checkbox(
                                value: (logic.selectedRows.length ==
                                        logic.list.length &&
                                    logic.selectedRows.isNotEmpty),
                                onChanged: (value) => logic.toggleSelectAll(),
                                fillColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                        (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Color(
                                        0xFFD43030); // Red background when checked
                                  }
                                  return Colors
                                      .white; // Optional color for unchecked state
                                }),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ),
                          ...logic.columns.map((column) => GridColumn(
                                columnName: column.key,
                                width: column.width,
                                label: Container(
                                  color: Color(0xFFF3F4F8),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(8.0),
                                  child: StyledTitleText(
                                    column.title,
                                  ),
                                ),
                              )),
                          GridColumn(
                            columnName: 'Actions',
                            width: 100,
                            label: Container(
                              color: Color(0xFFF3F4F8),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '操作',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
          ),
          Obx(() => Padding(
                padding: EdgeInsets.only(right: 50),
                child: Column(
                  children: [
                    PaginationPage(
                      uniqueId: 'note_pagination',
                      total: logic.total.value,
                      changed: (int newSize, int newPage) {
                        logic.find(newSize, newPage);
                      },
                    ),
                  ],
                ),
              )),
          ThemeUtil.height(height: 30),
        ],
      ),
    );
  }
}

class NoteDataSource extends DataGridSource {
  final NoteLogic logic;
  final BuildContext context; // 增加 BuildContext 成员变量
  List<DataGridRow> _rows = [];

  NoteDataSource({required this.logic, required this.context}) {
    // 构造函数中添加 context 参数
    _buildRows();
  }

  void _buildRows() {
    _rows = logic.list
        .map((item) => DataGridRow(
              cells: [
                DataGridCell(
                  columnName: 'Select',
                  value: logic.selectedRows.contains(item['id']),
                ),
                ...logic.columns.map((column) => DataGridCell(
                      columnName: column.key,
                      value: item[column.key],
                    )),
                DataGridCell(columnName: 'Actions', value: item),
              ],
            ))
        .toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final isSelected = row.getCells().first.value as bool;
    final rowIndex = _rows.indexOf(row);
    final item = row.getCells().last.value;

    return DataGridRowAdapter(
      color: rowIndex.isEven ? Color(0x50F1FDFC) : Colors.white,
      cells: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Checkbox(
            value: isSelected,
            onChanged: (value) => logic.toggleSelect(item['id']),
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              return states.contains(WidgetState.selected)
                  ? Color(0xFFD43030)
                  : Colors.white;
            }),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        ...row.getCells().skip(1).take(row.getCells().length - 2).map((cell) {
          final columnName = cell.columnName;
          final value = cell.value.toString();
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8.0),
            child: StyledNormalText(value),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // 将按钮左对齐
          children: [
            TextButton(
              style: item["teacher_file_path"] != null &&
                      item["teacher_file_path"].isNotEmpty
                  ? ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.blue),
                      overlayColor:
                          MaterialStateProperty.all<Color>(Colors.transparent),
                    )
                  : ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
                      overlayColor:
                          MaterialStateProperty.all<Color>(Colors.transparent),
                    ),
              onPressed: item["teacher_file_path"] != null &&
                      item["teacher_file_path"].isNotEmpty
                  ? () {
                      logic.updatePdfUrl(item["teacher_file_path"]);
                    }
                  : () async {
                      await logic.loadAndUpdatePdfUrl(item["id"]);
                      logic.refresh();
                      "生成成功".toHint();
                    },
              child: item["teacher_file_path"] != null &&
                      item["teacher_file_path"].isNotEmpty
                  ? Text("查看")
                  : Text("生成并查看"),
            ),
          ],
        )
      ],
    );
  }
}
