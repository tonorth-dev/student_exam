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

class JobPage extends StatelessWidget {
  final logic = Get.put(JobLogic());

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ButtonState>(
      create: (_) => ButtonState(),
      child: Column(
        children: [
          TableEx.actions(
            children: [
              SizedBox(width: 30), // 添加一些间距
              CustomButton(
                onPressed: () => logic.add(context),
                text: '新增',
                width: 70, // 自定义宽度
                height: 32, // 自定义高度
              ),
              SizedBox(width: 8), // 添加一些间距
              CustomButton(
                onPressed: () async {
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
                    logic.batchDelete(logic.selectedRows);
                  }
                },
                text: '批量删除',
                width: 90, // 自定义宽度
                height: 32, // 自定义高度
              ),
              SizedBox(width: 8), // 添加一些间距
              CustomButton(
                onPressed: logic.exportSelectedItemsToXLSX,
                text: '导出选中',
                width: 90, // 自定义宽度
                height: 32, // 自定义高度
              ),
              SizedBox(width: 8), // 添加一些间距
              CustomButton(
                onPressed: logic.exportAllToXLSX,
                text: '导出全部',
                width: 90, // 自定义宽度
                height: 32, // 自定义高度
              ),
              SizedBox(width: 8), // 添加一些间距
              CustomButton(
                onPressed: logic.importFromXLSX,
                text: '从Excel导入',
                width: 110, // 自定义宽度
                height: 32, // 自定义高度
              ),
              SizedBox(width: 240), // 添加一些间距
              Padding(
                padding: EdgeInsets.all(16.0),
                child: FutureBuilder<void>(
                  future: logic.fetchMajors(), // 调用 fetchMajors 方法
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator()); // 加载中显示进度条
                    } else if (snapshot.hasError) {
                      return Text('加载失败: ${snapshot.error}');
                    } else {
                      return CascadingDropdownField(
                        key: logic.majorDropdownKey,
                        width: 110,
                        height: 34,
                        hint1: '专业类目一',
                        hint2: '专业类目二',
                        hint3: '专业名称',
                        level1Items: logic.level1Items,
                        level2Items: logic.level2Items,
                        level3Items: logic.level3Items,
                        selectedLevel1: ValueNotifier(null),
                        selectedLevel2: ValueNotifier(null),
                        selectedLevel3: ValueNotifier(null),
                        onChanged:
                            (dynamic level1, dynamic level2, dynamic level3) {
                          logic.selectedMajorId.value = level3.toString();
                          // 这里可以处理选择的 id
                        },
                      );
                    }
                  },
                ),
              ),
              SearchBoxWidget(
                key: Key('keywords'),
                hint: '岗位代码、岗位名称、单位序号、单位名称',
                onTextChanged: (String value) {
                  logic.searchText.value = value;
                  logic.applyFilters();
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
                        source: JobDataSource(logic: logic, context: context),
                        headerGridLinesVisibility:
                            GridLinesVisibility.values[1],
                        gridLinesVisibility: GridLinesVisibility.values[1],
                        columnWidthMode: ColumnWidthMode.fill,
                        headerRowHeight: 50,
                        rowHeight: 60,
                        columns: [
                          GridColumn(
                            columnName: 'Select',
                            width: 100,
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
                                width: _getColumnWidth(column.key),
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
                            width: 140,
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
                      uniqueId: 'job_pagination',
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

  double _getColumnWidth(String key) {
    switch (key) {
      case 'id':
        return 0;
      case 'code':
        return 80;
      case 'name':
        return 120;
      case 'cate':
        return 80;
      case 'company_code':
        return 80;
      case 'company_name':
        return 120;
      case 'course_desc':
        return 200;
      case 'major_name':
        return 120;
      case 'condition_name':
        return 350;
      case 'source':
      case 'city':
      case 'ext':
      case 'status':
      case 'major_id':
      case 'create_time':
      case 'condition':
        return 0;
      default:
        return 100; // 默认宽度
    }
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "岗位管理",
      icon: Icons.app_registration_outlined,
      page: JobPage(),
    );
  }
}

class JobDataSource extends DataGridSource {
  final JobLogic logic;
  final BuildContext context; // 增加 BuildContext 成员变量
  List<DataGridRow> _rows = [];

  JobDataSource({required this.logic, required this.context}) {
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

          if (columnName == 'condition_name') {
            return Tooltip(
              message: "点击右侧复制或查看全文",
              verticalOffset: 25.0,
              showDuration: Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // 使用TextPainter来检查文本是否会在给定宽度内溢出
                  final textPainter = TextPainter(
                    text: TextSpan(text: value, style: TextStyle(fontSize: 14)),
                    maxLines: 2,
                    textDirection: TextDirection.ltr,
                  )..layout(
                      maxWidth: constraints.maxWidth - 10); // 减去Padding的宽度

                  final isOverflowing = textPainter.didExceedMaxLines;
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(8.0),
                          child: StyledNormalText(value),
                        ),
                      ),
                      isOverflowing
                          ? TextButton(
                              onPressed: () {
                                CopyDialog.show(context, value);
                              },
                              child: Text("全文"),
                            )
                          : TextButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: value));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("复制成功"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Text("复制"),
                            ),
                    ],
                  );
                },
              ),
            );
          } else {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8.0),
              child: StyledNormalText(value),
            );
          }
        }),
        if (item['status'] == 4)
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // 将按钮左对齐
            children: [
              HoverTextButton(
                text: "审核通过",
                onTap: () => logic.audit(item['id'], 2),
              ),
              SizedBox(width: 5),
              HoverTextButton(
                text: "审核拒绝",
                onTap: () => logic.audit(item['id'], 1),
              ), // 控制按钮之间的间距
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // 将按钮左对齐
          children: [
            HoverTextButton(
              text: "编辑",
              onTap: () => logic.edit(context, item),
            ),
            SizedBox(width: 5),
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
