import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:student_exam/component/pagination/view.dart';
import 'package:student_exam/component/table/ex.dart';
import 'package:student_exam/component/widget.dart';
import 'logic.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:provider/provider.dart';

class LectureTableView extends StatelessWidget {
  final String title;
  final LectureLogic logic;

  const LectureTableView({super.key, required this.title, required this.logic});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ButtonState>(
      create: (_) => ButtonState(),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: 10),
              SearchBoxWidget(
                key: Key('keywords'),
                hint: '输入讲义名称',
                width: 170,
                onTextChanged: (String value) {
                  logic.searchText.value = value;
                },
                searchText: logic.searchText,
              ),
              SizedBox(width: 10),
              SearchButtonWidget(
                width: 55,
                height: 30,
                key: Key('search'),
                onPressed: () {
                  logic.selectedRows.clear();
                  logic.find(logic.size.value, logic.page.value);
                },
              ),
            ],
          ),
          ThemeUtil.height(),
          ThemeUtil.lineH(),
          ThemeUtil.height(),
          Expanded(
            child: Obx(() => logic.loading.value
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 250,
                child: SfDataGrid(
                  source: LectureDataSource(logic: logic, context: context),
                  headerGridLinesVisibility: GridLinesVisibility.none,
                  gridLinesVisibility: GridLinesVisibility.none,
                  columnWidthMode: ColumnWidthMode.fill,
                  headerRowHeight: 35,
                  rowHeight: 35,
                  columns: logic.columns.map((column) {
                    return GridColumn(
                      columnName: column.key,
                      width: column.width,
                      label: Container(
                        color: Color(0xFFF3F4F8), // 自定义标题背景色
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8.0),
                        child: Text( // 使用 SelectableText 使文本可选
                          column.title,
                          style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            )),
          ),
          Obx(() => Padding(
            padding: EdgeInsets.only(right: 50),
            child: Column(
              children: [
                PaginationPage(
                  uniqueId: 'lecture_pagination',
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

class LectureDataSource extends DataGridSource {
  final LectureLogic logic;
  final BuildContext context;
  List<DataGridRow> _rows = [];
  int? _selectedRowIndex;

  LectureDataSource({required this.logic, required this.context}) {
    _buildRows();
  }

  void _buildRows() {
    _rows = logic.list.map((item) {
      return DataGridRow(
        cells: logic.columns.map((column) {
          return DataGridCell(columnName: column.key, value: item[column.key]);
        }).toList(),
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final rowIndex = _rows.indexOf(row);
    final item = logic.list[rowIndex];

    return DataGridRowAdapter(
      color: _selectedRowIndex == rowIndex
          ? const Color(0xFFE0F7FA)
          : rowIndex.isEven
              ? const Color(0x50F1FDFC)
              : Color(0x70FFFFFF),
      cells: row.getCells().map((cell) {
        final value = cell.value.toString();
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            _selectedRowIndex = rowIndex;
            logic.loadDirectoryTree(item['id'].toString(), false);
            notifyListeners();
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                value,
                style: const TextStyle(color: Color(0xff26395f), fontWeight: FontWeight.w500
                    , fontSize: 14),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}