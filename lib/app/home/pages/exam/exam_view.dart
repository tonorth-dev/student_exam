import 'package:hongshi_admin/app/home/pages/exam/topic_logic.dart';
import 'package:hongshi_admin/app/home/pages/exam/topic_view.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:hongshi_admin/component/pagination/view.dart';
import 'package:hongshi_admin/component/table/ex.dart';
import 'package:hongshi_admin/app/home/sidebar/logic.dart';
import 'package:hongshi_admin/component/widget.dart';
import 'package:hongshi_admin/component/dialog.dart';
import '../../../../api/exam_template_api.dart';
import '../execute/view.dart';
import 'logic.dart';
import 'package:hongshi_admin/theme/theme_util.dart';
import 'package:provider/provider.dart';

class ExamPage extends StatefulWidget {
  final logic = Get.put(ExamLogic());

  @override
  _ExamPageState createState() => _ExamPageState();

  static SidebarTree newThis() {
    return SidebarTree(
      name: "试卷管理",
      icon: Icons.app_registration_outlined,
      page: ExamPage(),
    );
  }
}

class _ExamPageState extends State<ExamPage> {
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ButtonState>(
      create: (_) => ButtonState(),
      child: Column(
        children: [
          Container(
            height: 440,
            color: Color(0xFFF7F7F9),
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "生成试卷",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),

                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInteractiveCardLeft("通过模板创建", 400, 360),
                    SizedBox(width: 40),
                    _buildInteractiveCardRight("生成试卷", 1000, 360),
                  ],
                ),
              ],
            ),
          ),
          TableEx.actions(
            children: [
              SizedBox(width: 16),
              Text(
                "管理试卷",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: 30),
              CustomButton(
                onPressed: () =>
                    widget.logic.batchDelete(widget.logic.selectedRows),
                text: '批量删除',
                width: 90,
                height: 32,
              ),
              SizedBox(width: 240),
              DropdownField(
                key: widget.logic.levelDropdownKey,
                items: widget.logic.questionLevel.toList(),
                hint: '选择难度',
                width: 120,
                height: 34,
                selectedValue: widget.logic.selectedQuestionLevel,
                onChanged: (dynamic newValue) {
                  widget.logic.selectedQuestionLevel.value =
                      newValue.toString();
                  widget.logic.applyFilters();
                },
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: FutureBuilder<void>(
                  future: widget.logic.fetchMajors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('加载失败: ${snapshot.error}');
                    } else {
                      return CascadingDropdownField(
                        key: widget.logic.majorDropdownKey,
                        width: 160,
                        height: 34,
                        hint1: '专业类目一',
                        hint2: '专业类目二',
                        hint3: '专业名称',
                        level1Items: widget.logic.level1Items,
                        level2Items: widget.logic.level2Items,
                        level3Items: widget.logic.level3Items,
                        selectedLevel1: ValueNotifier(null),
                        selectedLevel2: ValueNotifier(null),
                        selectedLevel3: ValueNotifier(null),
                        onChanged:
                            (dynamic level1, dynamic level2, dynamic level3) {
                          widget.logic.selectedMajorId.value =
                              level3.toString();
                        },
                      );
                    }
                  },
                ),
              ),
              SearchBoxWidget(
                key: Key('keywords'),
                hint: '试卷名称、作者',
                onTextChanged: (String value) {
                  widget.logic.searchText.value = value;
                  widget.logic.applyFilters();
                },
                searchText: widget.logic.searchText,
              ),
              SizedBox(width: 26),
              SearchButtonWidget(
                key: Key('search'),
                onPressed: () => widget.logic
                    .find(widget.logic.size.value, widget.logic.page.value),
              ),
              SizedBox(width: 10),
              ResetButtonWidget(
                key: Key('reset'),
                onPressed: () {
                  widget.logic.reset();
                  widget.logic
                      .find(widget.logic.size.value, widget.logic.page.value);
                },
              ),
            ],
          ),
          ThemeUtil.lineH(),
          ThemeUtil.height(),
          Expanded(
            child: Obx(() => widget.logic.loading.value
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1400,
                      child: SfDataGrid(
                        source: ExamDataSource(
                            logic: widget.logic, context: context),
                        headerGridLinesVisibility:
                            GridLinesVisibility.values[1],
                        gridLinesVisibility: GridLinesVisibility.values[1],
                        columnWidthMode: ColumnWidthMode.fill,
                        headerRowHeight: 50,
                        rowHeight: 100,
                        columns: [
                          GridColumn(
                            columnName: 'Select',
                            width: 100,
                            label: Container(
                              color: Color(0xFFF3F4F8),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8.0),
                              child: Checkbox(
                                value: widget.logic.selectedRows.length ==
                                    widget.logic.list.length,
                                onChanged: (value) =>
                                    widget.logic.toggleSelectAll(),
                                fillColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                        (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Color(0xFFD43030);
                                  }
                                  return Colors.white;
                                }),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ),
                          ...widget.logic.columns.map((column) => GridColumn(
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
                      uniqueId: 'exam_pagination',
                      total: widget.logic.total.value,
                      changed: (int newSize, int newPage) {
                        widget.logic.find(newSize, newPage);
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

  Widget _buildInteractiveCardLeft(
      String title, double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xFFE6F0FF),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(color: Color(0xFFE6F0FF), width: 1),
      ),
      padding: EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3.0),
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800]),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SelectableList(
                  key: widget.logic.selectableListKey,
                  items: widget.logic.templateList,
                  onDelete: (Map<String, dynamic> item) async {
                    try {
                      await ExamTemplateApi.templateDelete(item["id"]);
                      "删除成功".toHint();
                    } catch (error) {
                      "删除失败: $error".toHint();
                      throw error;
                    }
                  },
                  onSelected: (Map<String, dynamic> item) {
                    print("Item with ID ${item['id']} and $item is selected");
                    widget.logic.fillTemplate(item);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCardRight(
      String title, double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color(0xFFE6F0FF),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(color: Color(0xFFE6F0FF), width: 1),
      ),
      padding: EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3.0),
        ),
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800]),
            ),
            Row(children: [
              SizedBox(
                width: 900,
                height: 60,
                child: FollowHeader(),
              ),
            ]),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: DropdownField(
                    items: widget.logic.questionLevel.toList(),
                    hint: '选择难度',
                    width: 100,
                    // 注意：这里的宽度设置可能会使内容不能完全贴靠左边
                    height: 34,
                    onChanged: (dynamic newValue) {
                      widget.logic.examSelectedQuestionLevel.value =
                          newValue.toString();
                      widget.logic.applyFilters();
                    },
                    selectedValue: widget.logic.examSelectedQuestionLevel,
                  ),
                ),
                SizedBox(width: 20),
                SizedBox(
                  width: 260,
                  child: Row(
                    children: [
                      for (int i = 0; i < widget.logic.questionCate.length; i += 3)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.logic.questionCate
                              .sublist(
                            i,
                            i + 3 > widget.logic.questionCate.length ? widget.logic.questionCate.length : i + 3,
                          )
                              .map((item) {
                            final String key = item['id'].toString();

                            return ValueListenableBuilder<Map<String, int>>(
                              valueListenable: widget.logic.examQuestionCate,
                              builder: (context, examQuestionCate, _) {
                                final int initialValue = examQuestionCate[key] ?? 0;
                                final TextEditingController controller = TextEditingController(text: initialValue.toString());
                                final FocusNode focusNode = FocusNode();

                                // Clear the text when the TextField gets focus.
                                focusNode.addListener(() {
                                  if (focusNode.hasFocus) {
                                    controller.clear();
                                  } else {
                                    // Restore to 0 if the text is empty when losing focus.
                                    if (controller.text.isEmpty) {
                                      controller.text = '0';
                                      widget.logic.cateSelectedValues[key]?.value = 0;

                                      // Update examQuestionCate
                                      widget.logic.examQuestionCate.value = {
                                        ...(widget.logic.examQuestionCate.value ?? {}),
                                        key: 0,
                                      };
                                    }
                                  }
                                });

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${item['name']}：",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        height: 34,
                                        child: TextField(
                                          focusNode: focusNode,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(2),
                                          ],
                                          controller: controller,
                                          onChanged: (value) {
                                            final int newValue = int.tryParse(value) ?? 0;
                                            final clampedValue = newValue.clamp(0, 99);

                                            // Update cateSelectedValues
                                            widget.logic.cateSelectedValues[key]?.value = clampedValue;

                                            // Update examQuestionCate
                                            widget.logic.examQuestionCate.value = {
                                              ...(widget.logic.examQuestionCate.value ?? {}),
                                              key: clampedValue,
                                            };
                                          },
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        )
                    ],
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: SuggestionTextField(
                    width: 120,
                    height: 34,
                    labelText: '班级选择',
                    hintText: '输入班级名称',
                    key: widget.logic.classesTextFieldKey,
                    fetchSuggestions: widget.logic.fetchClasses,
                    initialValue: widget.logic.selectedClassesMap,
                    onSelected: (value) {
                      if (value == '') {
                        widget.logic.selectedClassesId.value = "";
                        return;
                      }
                      widget.logic.selectedClassesId.value = value['id']!;
                    },
                    onChanged: (value) {
                      if (value == null || value.isEmpty) {
                        widget.logic.selectedClassesId.value = ""; // 确保清空
                      }
                      print(
                          "onChanged selectedInstitutionId value: ${widget.logic.selectedClassesId.value}");
                    },
                  ),
                ),
                SizedBox(width: 66),
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      NumberInputWidget(
                        key: Key("exam_count"),
                        width: 90,
                        height: 34,
                        hint: "0",
                        selectedValue: widget.logic.examQuestionCount,
                        onValueChanged: (value) {
                          widget.logic.examQuestionCount.value = value.toInt();
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 205,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomDateTimePicker(
                          controller: widget.logic.dateTimeControllerStart,
                        hintText: "选择开始时间",
                      ),
                      SizedBox(height: 16),
                      CustomDateTimePicker(
                          controller: widget.logic.dateTimeControllerEnd,
                        hintText: "选择结束时间",
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final result = await widget.logic.saveTemplate();
                    if (result) {
                      await widget.logic.fetchTemplates();
                      refresh();
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.blue), // 设置按钮背景颜色为蓝色
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // 减少圆角半径
                      ),
                    ),
                  ),
                  child: Text("保存模板", style: TextStyle(color: Colors.white)), // 设置文本颜色为白色
                ),
                SizedBox(width: 50),
                ElevatedButton(
                  onPressed: () async {
                    await widget.logic.saveExam();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.red), // 设置按钮背景颜色为红色
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // 减少圆角半径
                      ),
                    ),
                  ),
                  child: Text("生成试卷", style: TextStyle(color: Colors.white)), // 设置文本颜色为白色
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExamDataSource extends DataGridSource {
  final ExamLogic logic;
  final BuildContext context;
  List<DataGridRow> _rows = [];

  ExamDataSource({required this.logic, required this.context}) {
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
                ...logic.columns.map((column) {
                  var value = item[column.key];
                  if (column.key == 'component_desc' && value is List) {
                    value = value.join("\n");
                  }
                  return DataGridCell(
                    columnName: column.key,
                    value: value,
                  );
                }),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => logic.deleteExam(item, rowIndex),
              child: Text("删除", style: TextStyle(color: Color(0xFFFD941D))),
            ),
            TextButton(
              onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ExamTopicView(
                            title: "试卷详情",
                            id: item['id'],
                            ),
                          ), // 替换为实际的 ID
                  );
              },
              child: Text("查看试卷", style: TextStyle(color: Color(0xFFFD941D))),
            ),
          ],
        ),
      ],
    );
  }
}

class FollowHeader extends StatelessWidget {
  final String firstBackgroundImage = 'assets/images/follow_header_bg.png';
  final String otherBackgroundImage = 'assets/images/follow_header_bg.jpg';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Flexible(
                flex: 2, // "选择模板"占用更大的比例
                child: _buildItem(
                  context,
                  '1',
                  '选择模板',
                  isFirst: true,
                ),
              ),
              SizedBox(width: 8.0), // 添加间距
              Expanded(
                child: _buildItem(context, '2', '选择班级'),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: _buildItem(context, '3', '练习次数'),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: _buildItem(context, '4', '练习时间'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, String number, String title, {bool isFirst = false}) {
    return Container(
      height: 60, // 固定高度，确保背景图尺寸一致
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(isFirst ? firstBackgroundImage : otherBackgroundImage),
          fit: BoxFit.cover, // 确保背景图按比例覆盖
        ),
        borderRadius: BorderRadius.circular(8.0), // 圆角半径
      ),
      child: Center(
        child: Text(
          "$number.$title",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontFamily: 'PingFang SC',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}


