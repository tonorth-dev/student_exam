import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:admin_flutter/component/pagination/view.dart';
import 'package:admin_flutter/component/table/ex.dart';
import 'package:admin_flutter/component/widget.dart';
import 'logic.dart';
import 'package:admin_flutter/theme/theme_util.dart';
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
              SizedBox(width: 8), // 添加一些间距
              CustomButton(
                onPressed: () => logic.add(context),
                text: '新增',
                width: 70, // 自定义宽度
                height: 32, // 自定义高度
              ),
              SizedBox(width: 50), // 添加一些间距
              SearchBoxWidget(
                key: Key('keywords'),
                hint: '讲义名称、创建者',
                width: 180,
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
                width: 600,
                child: SfDataGrid(
                  source:
                  LectureDataSource(logic: logic, context: context),
                  headerGridLinesVisibility:
                  GridLinesVisibility.values[1],
                  gridLinesVisibility: GridLinesVisibility.values[1],
                  columnWidthMode: ColumnWidthMode.fill,
                  headerRowHeight: 50,
                  rowHeight: 60,
                  columns: [
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
                      width: 120,
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
  final BuildContext context; // 增加 BuildContext 成员变量
  List<DataGridRow> _rows = [];

  LectureDataSource({required this.logic, required this.context}) {
    // 构造函数中添加 context 参数
    _buildRows();
  }

  void _buildRows() {
    _rows = logic.list
        .map((item) => DataGridRow(
      cells: [
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
    final rowIndex = _rows.indexOf(row);
    final item = row.getCells().last.value;

    return DataGridRowAdapter(
      color: rowIndex.isEven ? Color(0x50F1FDFC) : Colors.white,
      cells: [
        ...row.getCells().skip(0).take(row.getCells().length - 1).map((cell) {
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
            // HoverTextButton(
            //   text: "编辑",
            //   onTap: () => logic.edit(context, item),
            // ),
            HoverTextButton(
              text: "管理",
              onTap: () {
                print(item);
                logic.loadDirectoryTree(item['id'].toString(), false);
              },
            ),
            HoverTextButton(
              text: "删除",
              onTap: () async {
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("确认删除"),
                      content: Text("你确定要删除这项吗？"),
                      actions: [
                        TextButton(
                          child: Text("取消"),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        TextButton(
                          child: Text("确定"),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    );
                  },
                );

                if (shouldDelete == true) {
                  logic.delete(item, rowIndex);
                }
              },
            ),
            SizedBox(width: 5), // 控制按钮之间的间距
          ],
        )
      ],
    );
  }
}
