import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hongshi_admin/api/lecture_api.dart'; // 导入 lecture_api.dart
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class LectureAddForm extends StatefulWidget {
  const LectureAddForm({super.key});

  @override
  State<LectureAddForm> createState() => _LectureAddFormState();
}

class _LectureAddFormState extends State<LectureAddForm> {
  final logic = Get.put(LectureLogic());
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.saveLecture();
      if (result) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 850),
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
                      width: 240,
                      height: 34,
                      maxLines: 8,
                      hint: "输入讲义名称",
                      text: logic.lectureName,
                      onTextChanged: (value) {
                        logic.lectureName.value = value;
                      },
                      validator:
                      FormBuilderValidators.required(errorText: '讲义名称不能为空'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Row(
                      children: const [
                        Text('专业'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 500,
                    child: CascadingDropdownField(
                      width: 160,
                      height: 34,
                      hint1: '专业类目一',
                      hint2: '专业类目二',
                      hint3: '专业名称',
                      selectedLevel1: logic.selectedLevel1,
                      selectedLevel2: logic.selectedLevel2,
                      selectedLevel3: logic.selectedLevel3,
                      level1Items: logic.level1Items,
                      level2Items: logic.level2Items,
                      level3Items: logic.level3Items,
                      onChanged:
                          (dynamic level1, dynamic level2, dynamic level3) {
                        logic.majorId.value = level3.toString();
                        // 这里可以处理选择的 id
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Row(
                      children: const [
                        Text('岗位代码'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 620,
                    child: SuggestionTextField(
                      width: 600,
                      height: 34,
                      labelText: '请输入岗位代码',
                      hintText: '输入岗位代码',
                      key: Key("add_lecture_job_id"),
                      fetchSuggestions: logic.fetchJobs,
                      initialValue: ValueNotifier<Map<dynamic, dynamic>?>({}),
                      onSelected: (value) {
                        if (value.isEmpty) {
                          logic.jobCode.value = "";
                          return;
                        }
                        logic.jobCode.value = value['code']!;
                      },
                      onChanged: (value) {
                        if (value == null || value.isEmpty) {
                          logic.jobCode.value = ""; // 确保清空
                        }
                        print("onChanged selectedInstitutionId value: ${logic.jobCode.value}");
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
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
                      selectedValue: logic.sort,
                      onValueChanged: (value) {
                        logic.sort.value = value;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Row(
              //   children: [
              //     SizedBox(
              //       width: 150,
              //       child: Row(
              //         children: const [
              //           Text('讲义类别'),
              //           Text('*', style: TextStyle(color: Colors.red)),
              //         ],
              //       ),
              //     ),
              //     SizedBox(
              //       width: 620,
              //       child: TextInputWidget(
              //         width: 240,
              //         height: 34,
              //         maxLines: 8,
              //         hint: "输入讲义类别",
              //         text: logic.lectureCategory,
              //         onTextChanged: (value) {
              //           logic.lectureCategory.value = value;
              //         },
              //         validator:
              //         FormBuilderValidators.required(errorText: '讲义类别不能为空'),
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 10),
              // Row(
              //   children: [
              //     SizedBox(
              //       width: 150,
              //       child: Row(
              //         children: const [
              //           Text('页码数'),
              //           Text('*', style: TextStyle(color: Colors.red)),
              //         ],
              //       ),
              //     ),
              //     SizedBox(
              //       width: 620,
              //       child: NumberInputWidget(
              //         key: UniqueKey(),
              //         width: 90,
              //         height: 34,
              //         hint: "输入页码数",
              //         selectedValue: logic.pageCount,
              //         onValueChanged: (value) {
              //           logic.pageCount.value = value;
              //         },
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 10),
              // Row(
              //   children: [
              //     SizedBox(
              //       width: 150,
              //       child: Row(
              //         children: const [
              //           Text('状态'),
              //           Text('*', style: TextStyle(color: Colors.red)),
              //         ],
              //       ),
              //     ),
              //     SizedBox(
              //       width: 620,
              //       child: NumberInputWidget(
              //         key: UniqueKey(),
              //         width: 90,
              //         height: 34,
              //         hint: "输入状态",
              //         selectedValue: logic.status,
              //         onValueChanged: (value) {
              //           logic.status.value = value;
              //         },
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 10),
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
                    child: const Text('提交'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
