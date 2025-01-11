import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:hongshi_admin/component/pagination/view.dart';
import 'package:hongshi_admin/component/table/ex.dart';
import 'package:hongshi_admin/app/home/sidebar/logic.dart';
import 'package:hongshi_admin/app/home/pages/student_question/stu_logic.dart';
import 'package:hongshi_admin/app/home/pages/student_question/que_logic.dart';
import 'package:hongshi_admin/theme/theme_util.dart';
import '../../../../component/widget.dart';

class StudentQuestionPage extends StatelessWidget {
  final sLogic = Get.put(StuLogic());
  final qLogic = Get.put(QueLogic());

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StudentTableView(
                key: const Key("student_table"), title: "考生列表", logic: sLogic),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: QuestionTableView(
                key: const Key("question_table"), title: "试题列表", logic: qLogic),
          ),
        ),
      ],
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "考生试题",
      icon: Icons.app_registration_outlined,
      page: StudentQuestionPage(),
    );
  }
}

class QuestionTableView extends StatelessWidget {
  final String title;
  final QueLogic logic;

  const QuestionTableView({super.key, required this.title, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableEx.actions(
          children: [
            SizedBox(width: 30),
            Container(
              height: 50,
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
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
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SearchBoxWidget(
                    key: Key('keywords'),
                    hint: '试题标题',
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
                      logic.findForStudent(logic.size.value, logic.page.value);
                    },
                  ),
                  SizedBox(width: 8),
                  ResetButtonWidget(
                    key: Key('reset'),
                    onPressed: () {
                      logic.reset();
                      logic.findForStudent(logic.size.value, logic.page.value);
                    },
                  ),
                  ThemeUtil.width(width: 30),
                ],
              ),
            ),
          ],
        ),
        ThemeUtil.lineH(),
        ThemeUtil.height(),
        Expanded(
          child: Obx(() => Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: 1000,
                      height: Get.height,
                      child: SfDataGrid(
                        source: QuestionDataSource(logic: logic),
                        headerGridLinesVisibility:
                            GridLinesVisibility.values[1],
                        columnWidthMode: ColumnWidthMode.fill,
                        headerRowHeight: 50,
                        gridLinesVisibility: GridLinesVisibility.both,
                        columns: [
                          GridColumn(
                            width: 80,
                            columnName: 'Select',
                            label: Container(
                              decoration: BoxDecoration(
                                color: Colors.indigo[50],
                              ),
                              child: Center(
                                child: Obx(() => Checkbox(
                                      value: logic.isRowsSelectable.value &&
                                          logic.selectedRows.length ==
                                              logic.list.length,
                                      onChanged: (value) {
                                        if (logic.isRowsSelectable.value) {
                                          logic.toggleSelectAll();
                                        }
                                      },
                                      activeColor: Colors.teal,
                                    )),
                              ),
                            ),
                          ),
                          ...logic.columns.map((column) => GridColumn(
                                width: column.width,
                                columnName: column.key,
                                label: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.indigo[50],
                                  ),
                                  child: Center(
                                    child: StyledTitleText(
                                      column.title,
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              )),
        ),
        Obx(() {
          return PaginationPage(
            uniqueId: 'classes1_pagination',
            total: logic.total.value,
            changed: (size, page) => logic.findForStudent(size, page),
          );
        })
      ],
    );
  }
}

class QuestionDataSource extends DataGridSource {
  final QueLogic logic;
  List<DataGridRow> _rows = [];

  QuestionDataSource({required this.logic}) {
    _buildRows();
  }

  void _buildRows() {
    _rows = logic.list
        .map((item) => DataGridRow(
              cells: [
                DataGridCell(
                    columnName: 'Select',
                    value: logic.selectedRows.contains(item['id'])),
                ...logic.columns.map((column) => DataGridCell(
                      columnName: column.key,
                      value: item[column.key],
                    )),
              ],
            ))
        .toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final rowId = row.getCells()[1].value; // 假设 ID 在第二列
    final isSelected = logic.selectedRows.contains(rowId);
    final rowIndex = _rows.indexOf(row);

    // 定义不同的蒙层颜色
    final disabledOverlayColor = Colors.grey.withOpacity(0.1);
    final selectedDisabledOverlayColor = Colors.teal.withOpacity(0.3); // 更明显的蒙层

    return DataGridRowAdapter(
      color: logic.isRowsSelectable.value
          ? (isSelected
              ? Colors.teal.withOpacity(0.6) // 选中颜色
              : (rowIndex.isEven
                  ? Colors.teal.withOpacity(0.05)
                  : Colors.white)) // 交替行颜色
          : (isSelected
              ? selectedDisabledOverlayColor // 如果行被选择过，使用更明显的蒙层
              : disabledOverlayColor), // 禁用选择时的浅色蒙层
      cells: [
        Obx(() => MouseRegion(
              cursor: logic.isRowsSelectable.value
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Checkbox(
                  value: isSelected,
                  onChanged: logic.isRowsSelectable.value
                      ? (value) => logic.toggleSelect(rowId) // 点击行时触发选择
                      : null,
                  activeColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            )),
        ...row.getCells().skip(1).map((cell) {
          final columnName = cell.columnName;
          final value = cell.value.toString();
          return Obx(() => MouseRegion(
                cursor: logic.isRowsSelectable.value
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap: logic.isRowsSelectable.value
                      ? () => logic.toggleSelect(rowId)
                      : null, // 点击行时触发选择
                  behavior: HitTestBehavior.opaque, // 确保点击整个区域都能响应
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8.0),
                    width: double.infinity, // 确保单元格充满整个宽度
                    child: StyledNormalText(value),
                  ),
                ),
              ));
        }),
      ],
    );
  }
}

class StudentTableView extends StatelessWidget {
  final String title;
  final StuLogic logic;

  const StudentTableView({super.key, required this.title, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableEx.actions(
          children: [
            SizedBox(width: 30), // 添加一些间距
            Container(
              height: 50,
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade700, Colors.red.shade300],
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
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    height: 50,
                    child: Padding(
                      padding: EdgeInsets.all(0),
                      child: SuggestionTextField(
                        width: 600,
                        height: 34,
                        labelText: '请选择机构',
                        hintText: '输入机构名称',
                        key: logic.institutionTextFieldKey,
                        fetchSuggestions: logic.fetchInstructions,
                        initialValue: ValueNotifier<Map<dynamic, dynamic>?>({}),
                        onSelected: (value) {
                          if (value.isEmpty) {
                            logic.selectedInstitutionId.value = "";
                            return;
                          }
                          logic.selectedInstitutionId.value = value['id']!;
                        },
                        onChanged: (value) {
                          if (value == null || value.isEmpty) {
                            logic.selectedInstitutionId.value = ""; // 确保清空
                          }
                          print("onChanged selectedInstitutionId value: ${logic.selectedInstitutionId.value}");
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  SearchBoxWidget(
                    key: Key('keywords'),
                    hint: '班级名称、教师姓名',
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
                  ThemeUtil.width(width: 30),
                ],
              ),
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
                    width: 900,
                    height: Get.height,
                    child: SfDataGrid(
                      source: StudentDataSource(logic: logic, context: context),
                      headerGridLinesVisibility: GridLinesVisibility.values[1],
                      columnWidthMode: ColumnWidthMode.fill,
                      headerRowHeight: 50,
                      columns: [
                        GridColumn(
                          width: 80,
                          columnName: 'Select',
                          label: Container(
                            decoration: BoxDecoration(
                              color: Color(0xfff8e6dd),
                            ),
                            child: Center(
                              child: Checkbox(
                                value: logic.selectedRows.isNotEmpty,
                                onChanged: null,
                              ),
                            ),
                          ),
                        ),
                        ...logic.columns.map((column) => GridColumn(
                              width: column.width,
                              columnName: column.key,
                              label: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xfff8e6dd),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: StyledTitleText(
                                    column.title,
                                  ),
                                ),
                              ),
                            )),
                        GridColumn(
                          width: 0,
                          columnName: 'Actions',
                          label: Container(
                            decoration: BoxDecoration(
                              color: Color(0xfff8e6dd),
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
                      ],
                    ),
                  ),
                )),
        ),
        Obx(() {
          return PaginationPage(
            uniqueId: 'classes_pagination',
            total: logic.total.value,
            changed: (size, page) => logic.find(size, page),
          );
        })
      ],
    );
  }
}

class StudentDataSource extends DataGridSource {
  final StuLogic logic;
  final BuildContext context; // 新增 context 字段
  List<DataGridRow> _rows = [];

  StudentDataSource({required this.logic, required this.context}) {
    // 修改构造函数
    _buildRows();
  }

  void _buildRows() {
    _rows = logic.list.map((item) {
      final id = item['id'];
      // 初始化按钮状态
      logic.blueButtonStates[id] = ValueNotifier<bool>(true);
      logic.grayButtonStates[id] = ValueNotifier<bool>(false);
      logic.redButtonStates[id] = ValueNotifier<bool>(false);

      return DataGridRow(
        cells: [
          DataGridCell(
              columnName: 'Select', value: logic.selectedRows.contains(id)),
          ...logic.columns.map((column) => DataGridCell(
                columnName: column.key,
                value: item[column.key],
              )),
          DataGridCell(columnName: 'Actions', value: item),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final isSelected = row.getCells().first.value as bool;
    final rowIndex = _rows.indexOf(row);
    final item = row.getCells().last.value;
    final id = item['id'];

    return DataGridRowAdapter(
      color: isSelected
          ? Colors.red.shade100 // 选中颜色
          : (rowIndex.isEven ? Color(0x06FF5733) : Colors.white), // 交替行颜色
      cells: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) => logic.toggleSelect(id),
              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                return states.contains(MaterialState.selected)
                    ? Color(0xFFD43030)
                    : Colors.white;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        ...row.getCells().skip(1).take(row.getCells().length - 2).map((cell) {
          final value = cell.value.toString();
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => logic.toggleSelect(id), // 点击行时触发选择
              behavior: HitTestBehavior.opaque, // 确保点击整个区域都能响应
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8.0),
                width: double.infinity, // 确保单元格充满整个宽度
                child: StyledNormalText(value),
              ),
            ),
          );
        }),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: logic.redButtonStates[id]!,
                builder: (context, isEnabled, child) {
                  return TextButton(
                    onPressed: () {

                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isEnabled ? Colors.red : Colors.grey,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    ),
                    child: Text("保存考生"),
                  );
                },
              ),
              // SizedBox(width: 10),
            ],
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    // 清理 ValueNotifier
    logic.blueButtonStates.values.forEach((notifier) => notifier.dispose());
    logic.grayButtonStates.values.forEach((notifier) => notifier.dispose());
    logic.redButtonStates.values.forEach((notifier) => notifier.dispose());
    super.dispose();
  }
}
