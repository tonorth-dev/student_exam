import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:hongshi_admin/component/pagination/view.dart';
import 'package:hongshi_admin/component/table/ex.dart';
import 'package:hongshi_admin/app/home/sidebar/logic.dart';
import 'package:hongshi_admin/app/home/pages/corres/m_logic.dart';
import 'package:hongshi_admin/app/home/pages/corres/j_logic.dart';
import 'package:hongshi_admin/theme/theme_util.dart';
import '../../../../component/widget.dart';

class CorresPage extends StatelessWidget {
  final mLogic = Get.put(MLogic());
  final jLogic = Get.put(JLogic());

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: MajorTableView(
                key: const Key("major_table"), title: "专业列表", logic: mLogic),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: JobTableView(
                key: const Key("job_table"), title: "岗位列表", logic: jLogic),
          ),
        ),
      ],
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "专业对应岗位",
      icon: Icons.app_registration_outlined,
      page: CorresPage(),
    );
  }
}

class MajorTableView extends StatelessWidget {
  final String title;
  final MLogic logic;

  const MajorTableView({super.key, required this.title, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableEx.actions(
          children: [
            SizedBox(width: 10),
            Container(
              height: 50,
              width: 80,
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
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: FutureBuilder<void>(
                      future: logic.fetchMajors(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
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
                            selectedLevel1: logic.selectedLevel1,
                            selectedLevel2: logic.selectedLevel2,
                            selectedLevel3: logic.selectedLevel3,
                            onChanged: (dynamic level1, dynamic level2,
                                dynamic level3) {
                              logic.selectedMajorId.value = level3.toString();
                            },
                          );
                        }
                      },
                    ),
                  ),
                  SearchBoxWidget(
                    key: Key('keywords'),
                    hint: '类目名称、专业名称',
                    onTextChanged: (String value) {
                      logic.searchText.value = value;
                    },
                    searchText: logic.searchText,
                  ),
                  SizedBox(width: 5),
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
              width: 800,
              height: Get.height,
              child: SfDataGrid(
                source: MajorDataSource(logic: logic),
                headerGridLinesVisibility: GridLinesVisibility.values[1],
                columnWidthMode: ColumnWidthMode.fill,
                headerRowHeight: 50,
                columns: [
                  GridColumn(
                    width: 50,
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
            uniqueId: 'major_pagination',
            total: logic.total.value,
            changed: (size, page) => logic.find(size, page),
          );
        })
      ],
    );
  }
}

class MajorDataSource extends DataGridSource {
  final MLogic logic;
  List<DataGridRow> _rows = [];

  MajorDataSource({required this.logic}) {
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
                valueListenable: logic.blueButtonStates[id]!,
                builder: (context, isEnabled, child) {
                  return TextButton(
                    onPressed: () {
                      // 按钮操作逻辑
                      logic.blueButtonAction(id);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isEnabled ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    ),
                    child: Text("关联岗位"),
                  );
                },
              ),
              SizedBox(width: 20),
              ValueListenableBuilder<bool>(
                valueListenable: logic.grayButtonStates[id]!,
                builder: (context, isEnabled, child) {
                  return TextButton(
                    onPressed: () {
                      // 按钮操作逻辑
                      logic.grayButtonAction(id);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor:
                      isEnabled ? Colors.grey[400] : Colors.grey,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                    ),
                    child: Text("取消"),
                  );
                },
              ),
              SizedBox(width: 20),
              ValueListenableBuilder<bool>(
                valueListenable: logic.redButtonStates[id]!,
                builder: (context, isEnabled, child) {
                  return TextButton(
                    onPressed: () {
                      logic.redButtonAction(id);
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
                    child: Text("保存关联"),
                  );
                },
              ),
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

class JobTableView extends StatelessWidget {
  final String title;
  final JLogic logic;
  final GlobalKey _tableKey = GlobalKey(); // 用于获取表格尺寸

  JobTableView({super.key, required this.title, required this.logic});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableEx.actions(
          children: [
            SizedBox(width: 10),
            Container(
              height: 50,
              width: 80,
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
                      logic.findForMajor(logic.size.value, logic.page.value);
                    },
                  ),
                  SizedBox(width: 8),
                  ResetButtonWidget(
                    key: Key('reset'),
                    onPressed: () {
                      logic.reset();
                      logic.findForMajor(logic.size.value, logic.page.value);
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
          child: Obx(() {
            return Stack(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    key: _tableKey, // 绑定 GlobalKey
                    width: 800,
                    child: SfDataGrid(
                      source: JobDataSource(logic: logic),
                      headerGridLinesVisibility: GridLinesVisibility.values[1],
                      columnWidthMode: ColumnWidthMode.fill,
                      headerRowHeight: 50,
                      gridLinesVisibility: GridLinesVisibility.both,
                      columns: [
                        GridColumn(
                          width: 50,
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
            );
          }),
        ),
        Obx(() {
          return PaginationPage(
            uniqueId: 'job1_pagination',
            total: logic.total.value,
            changed: (size, page) => logic.findForMajor(size, page),
          );
        })
      ],
    );
  }
}

class JobDataSource extends DataGridSource {
  final JLogic logic;
  List<DataGridRow> _rows = [];

  JobDataSource({required this.logic}) {
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
                    padding: const EdgeInsets.all(3.0),
                    width: double.infinity, // 确保单元格充满整个宽度
                    height: 40,
                    child: StyledNormalText(value),
                  ),
                ),
              ));
        }),
      ],
    );
  }
}
