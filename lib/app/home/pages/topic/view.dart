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

class TopicPage extends StatelessWidget {
  final logic = Get.put(TopicLogic());

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ButtonState>(
      create: (_) => ButtonState(),
      child: Column(
        children: [
          TableEx.actions(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 10), // 添加一些间距
                  CustomButton(
                    onPressed: () => logic.add(context),
                    text: '新增',
                    width: 70,
                    height: 32,
                  ),
                  SizedBox(width: 8),
                  CustomButton(
                    onPressed: () => logic.batchDelete(logic.selectedRows),
                    text: '批量删除',
                    width: 90,
                    height: 32,
                  ),
                  SizedBox(width: 8),
                  CustomButton(
                    onPressed: logic.exportSelectedItemsToXLSX,
                    text: '导出选中',
                    width: 90,
                    height: 32,
                  ),
                  SizedBox(width: 8),
                  CustomButton(
                    onPressed: logic.exportAllToXLSX,
                    text: '导出全部',
                    width: 90,
                    height: 32,
                  ),
                  SizedBox(width: 8),
                  CustomButton(
                    onPressed: logic.importFromXLSX,
                    text: '从Excel导入',
                    width: 110,
                    height: 32,
                  ),
                ],
              ),
              SizedBox(width: 20), // ### 添加换行间距 ###
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DropdownField(
                    key: logic.cateDropdownKey,
                    items: logic.questionCate.toList(),
                    hint: '选择题型',
                    label: true,
                    width: 110,
                    height: 34,
                    selectedValue: logic.selectedQuestionCate,
                    onChanged: (dynamic newValue) {
                      logic.selectedQuestionCate.value = newValue.toString();
                    },
                  ),
                  SizedBox(width: 8),
                  DropdownField(
                    key: logic.levelDropdownKey,
                    items: logic.questionLevel.toList(),
                    hint: '选择难度',
                    label: true,
                    width: 110,
                    height: 34,
                    selectedValue: logic.selectedQuestionLevel,
                    onChanged: (dynamic newValue) {
                      logic.selectedQuestionLevel.value = newValue.toString();
                      logic.applyFilters();
                    },
                  ),
                  SizedBox(width: 8),
                  DropdownField(
                    key: logic.statusDropdownKey,
                    items: logic.questionStatus.toList(),
                    hint: '选择状态',
                    label: true,
                    width: 110,
                    height: 34,
                    selectedValue: logic.selectedQuestionStatus,
                    onChanged: (dynamic newValue) {
                      logic.selectedQuestionStatus.value = newValue;
                      logic.applyFilters();
                    },
                  ),
                ],
              ),
              SizedBox(height: 16), // ### 添加换行间距 ###
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: FutureBuilder<void>(
                      future: logic.fetchMajors(),
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
                            onChanged: (dynamic level1, dynamic level2, dynamic level3) {
                              logic.selectedMajorId.value = level3.toString();
                            },
                          );
                        }
                      },
                    ),
                  ),
                  SearchBoxWidget(
                    key: Key('keywords'),
                    hint: '题干、答案、标签',
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
                        source: TopicDataSource(logic: logic, context: context),
                        headerGridLinesVisibility:
                            GridLinesVisibility.values[1],
                        gridLinesVisibility: GridLinesVisibility.values[1],
                        columnWidthMode: ColumnWidthMode.fill,
                        headerRowHeight: 50,
                        rowHeight: 90,
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
                      uniqueId: 'topic_pagination',
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

  static SidebarTree newThis() {
    return SidebarTree(
      name: "题库管理",
      icon: Icons.app_registration_outlined,
      page: TopicPage(),
    );
  }
}

class TopicDataSource extends DataGridSource {
  final TopicLogic logic;
  final BuildContext context; // 增加 BuildContext 成员变量
  List<DataGridRow> _rows = [];

  TopicDataSource({required this.logic, required this.context}) {
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

          if (columnName == 'title' || columnName == 'answer') {
            // LayoutBuilder 处理溢出和文本显示
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
                  final isOverflowing = value.length > 340; // 判断是否溢出
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            value,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
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
              ),// 控制按钮之间的间距
            ],
          ),
        if (item['status'] != 4)
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
                onTap: () => logic.delete(item, rowIndex),
              ),
              SizedBox(width: 5), // 控制按钮之间的间距
              if (item['status'] == 1) // 假设 status 字段表示数据状态
                HoverTextButton(
                  text: "邀请",
                  onTap: () => logic.generateAndOpenLink(context, item),
                )
            ],
          )
      ],
    );
  }
}
