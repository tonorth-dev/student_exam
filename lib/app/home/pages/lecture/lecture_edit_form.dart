import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:admin_flutter/api/lecture_api.dart';
import 'package:get/get.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class LectureEditForm extends StatefulWidget {
  final int lectureId;
  final String initialLectureName;
  final String initialLectureMajorId;
  final String initialLectureJobCode;
  final String initialLectureJobName;
  final int initialSort;

  LectureEditForm({
    required this.lectureId,
    required this.initialLectureName,
    required this.initialLectureMajorId,
    required this.initialLectureJobCode,
    required this.initialLectureJobName,
    required this.initialSort,
  });

  @override
  State<LectureEditForm> createState() => _LectureEditFormState();
}

class _LectureEditFormState extends State<LectureEditForm> {
  final logic = Get.put(LectureLogic());
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.updateLecture(widget.lectureId);
      if (result) {
        Navigator.pop(context);
        logic.find(logic.size.value, logic.page.value); // 刷新列表
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 设置初始值
    logic.uLectureName.value = widget.initialLectureName;
    logic.uMajorId.value = widget.initialLectureMajorId;
    logic.uJobCode.value = widget.initialLectureJobCode;
    logic.uSort.value = widget.initialSort;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Row(
                        children: const [
                          Text('讲义名称'),
                          Text('*', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 620,
                      child: TextInputWidget(
                        key: UniqueKey(),
                        width: 240,
                        height: 34,
                        maxLines: 8,
                        hint: "输入讲义名称",
                        text: logic.uLectureName,
                        onTextChanged: (value) {
                          logic.uLectureName.value = value;
                        },
                        validator:
                        FormBuilderValidators.required(errorText: '讲义名称不能为空'),
                      ),
                    ),
                  ],
                ),
                // Row(
                //   children: [
                //     SizedBox(
                //       width: 150,
                //       child: Row(
                //         children: const [
                //           Text('专业'),
                //         ],
                //       ),
                //     ),
                //     SizedBox(
                //       width: 500,
                //       child: CascadingDropdownField(
                //         key: UniqueKey(),
                //         width: 160,
                //         height: 34,
                //         hint1: '专业类目一',
                //         hint2: '专业类目二',
                //         hint3: '专业名称',
                //         level1Items: logic.level1Items,
                //         level2Items: logic.level2Items,
                //         level3Items: logic.level3Items,
                //         selectedLevel1: ValueNotifier(
                //             logic.getLevel1IdFromLevel2Id(
                //                 logic.getLevel2IdFromLevel3Id(
                //                     widget.initialLectureMajorId))),
                //         selectedLevel2: ValueNotifier(logic
                //             .getLevel2IdFromLevel3Id(widget.initialLectureMajorId)),
                //         selectedLevel3: ValueNotifier(widget.initialLectureMajorId),
                //         onChanged:
                //             (dynamic level1, dynamic level2, dynamic level3) {
                //           print(
                //               "level1: $level1, level2: $level2, level3: $level3");
                //           logic.uMajorId.value = level3.toString();
                //           // 这里可以处理选择的 id
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 10),
                // Row(
                //   children: [
                //     SizedBox(
                //       width: 150,
                //       child: Row(
                //         children: const [
                //           Text('岗位代码'),
                //         ],
                //       ),
                //     ),
                //     SizedBox(
                //       width: 620,
                //       child: SuggestionTextField(
                //         width: 600,
                //         height: 34,
                //         labelText: '请输入岗位代码',
                //         hintText: '输入岗位代码',
                //         key: UniqueKey(),
                //         fetchSuggestions: logic.fetchJobs,
                //         initialValue: ValueNotifier<Map<dynamic, dynamic>?>(
                //             {
                //               'code': widget.initialLectureJobCode,
                //               'name': widget.initialLectureJobName,
                //             }),
                //         onSelected: (value) {
                //           if (value.isEmpty) {
                //             logic.uJobCode.value = "";
                //             return;
                //           }
                //           logic.uJobCode.value = value['code']!;
                //         },
                //         onChanged: (value) {
                //           if (value == null || value.isEmpty) {
                //             logic.uJobCode.value = ""; // 确保清空
                //           }
                //           print("onChanged selectedInstitutionId value: ${logic.uJobCode.value}");
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Row(
                        children: const [
                          Text('排序'),
                          Text('*', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 620,
                      child: NumberInputWidget(
                        key: UniqueKey(),
                        width: 90,
                        height: 34,
                        hint: "输入排序",
                        selectedValue: logic.uSort,
                        onValueChanged: (value) {
                          logic.uSort.value = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // 关闭弹窗
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF25B7E8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
