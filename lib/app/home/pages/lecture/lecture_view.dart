import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:student_exam/component/pagination/view.dart';
import 'package:student_exam/component/table/ex.dart';
import 'package:student_exam/component/widget.dart';
import 'package:student_exam/common/app_providers.dart';
import 'logic.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:provider/provider.dart';

class LectureTableView extends StatelessWidget {
  final String title;
  final LectureLogic logic;

  const LectureTableView({super.key, required this.title, required this.logic});

  @override
  Widget build(BuildContext context) {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return ChangeNotifierProvider<ButtonState>(
      create: (_) => ButtonState(),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(width: screenAdapter.getAdaptiveWidth(10)),
              SearchBoxWidget(
                key: Key('keywords'),
                hint: '输入讲义名称',
                width: screenAdapter.getAdaptiveWidth(170),
                onTextChanged: (String value) {
                  logic.searchText.value = value;
                },
                searchText: logic.searchText,
              ),
              SizedBox(width: screenAdapter.getAdaptiveWidth(10)),
              SearchButtonWidget(
                width: screenAdapter.getAdaptiveWidth(55),
                height: screenAdapter.getAdaptiveHeight(30),
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
                ? Center(
                    child: SizedBox(
                      width: screenAdapter.getAdaptiveWidth(24),
                      height: screenAdapter.getAdaptiveHeight(24),
                      child: CircularProgressIndicator(
                        strokeWidth: screenAdapter.getAdaptiveWidth(2),
                      ),
                    ),
                  )
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                color: Colors.white,
                width: screenAdapter.getAdaptiveWidth(270),
                child: SfDataGrid(
                  source: LectureDataSource(logic: logic, context: context),
                  headerGridLinesVisibility: GridLinesVisibility.none,
                  gridLinesVisibility: GridLinesVisibility.none,
                  columnWidthMode: ColumnWidthMode.fill,
                  headerRowHeight: screenAdapter.getAdaptiveHeight(35),
                  rowHeight: screenAdapter.getAdaptiveHeight(35),
                  columns: logic.columns.map((column) {
                    return GridColumn(
                      columnName: column.key,
                      width: screenAdapter.getAdaptiveWidth(column.width),
                      label: Container(
                        color: Color(0xFFF3F4F8), // 自定义标题背景色
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(8.0)),
                        child: Text( // 使用 SelectableText 使文本可选
                          column.title,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: screenAdapter.getAdaptiveFontSize(14),
                            fontWeight: FontWeight.w700
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            )),
          ),
          Obx(() => Padding(
            padding: EdgeInsets.only(right: screenAdapter.getAdaptivePadding(50)),
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
          ThemeUtil.height(height: screenAdapter.getAdaptiveHeight(30)),
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
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    final rowIndex = _rows.indexOf(row);
    final item = logic.list[rowIndex];

    return DataGridRowAdapter(
      color: _selectedRowIndex == rowIndex
          ? const Color(0xFFE3F2FD)
          : Colors.white,
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
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              alignment: Alignment.center,
              padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(8.0)),
              child: Text(
                value,
                style: TextStyle(
                  color: Color(0xff26395f),
                  fontWeight: FontWeight.w500,
                  fontSize: screenAdapter.getAdaptiveFontSize(14)
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}