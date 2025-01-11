import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:admin_flutter/api/job_api.dart'; // 导入 job_api.dart
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class JobAddForm extends StatefulWidget {
  const JobAddForm({super.key});

  @override
  State<JobAddForm> createState() => _JobAddFormState();
}

class _JobAddFormState extends State<JobAddForm> {
  final logic = Get.put(JobLogic());
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.saveJob();
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
                        Text('岗位代码'),
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
                      hint: "输入岗位代码",
                      text: logic.jobCode,
                      onTextChanged: (value) {
                        logic.jobCode.value = value;
                      },
                      validator:
                          FormBuilderValidators.required(errorText: '岗位代码不能为空'),
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
                        Text('岗位名称'),
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
                      hint: "输入岗位名称",
                      text: logic.jobName,
                      onTextChanged: (value) {
                        logic.jobName.value = value;
                      },
                      validator:
                          FormBuilderValidators.required(errorText: '岗位名称不能为空'),
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
                        Text('从事工作'),
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
                      hint: "输入从事工作",
                      text: logic.jobDesc,
                      onTextChanged: (value) {
                        logic.jobDesc.value = value;
                      },
                      validator:
                      FormBuilderValidators.required(errorText: '从事工作不能为空'),
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
                        Text('岗位类别'),
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
                      hint: "输入岗位类别",
                      text: logic.jobCate,
                      onTextChanged: (value) {
                        logic.jobCate.value = value;
                      },
                      validator:
                          FormBuilderValidators.required(errorText: '岗位类别不能为空'),
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
                        Text('招生数量'),
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
                      hint: "招生数量",
                      selectedValue: 0.obs,
                      onValueChanged: (value) {
                        logic.enrollmentNum.value = value;
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
                        Text('入围比例'),
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
                      hint: "输入入围比例",
                      text: logic.enrollmentRatio,
                      onTextChanged: (value) {
                        logic.enrollmentRatio.value = value;
                      },
                      validator:
                          FormBuilderValidators.required(errorText: '入围比例不能为空'),
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
                        Text('单位序号'),
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
                      hint: "输入单位序号",
                      text: logic.companyCode,
                      onTextChanged: (value) {
                        logic.companyCode.value = value;
                      },
                      validator:
                      FormBuilderValidators.required(errorText: '单位序号不能为空'),
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
                        Text('单位名称'),
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
                      hint: "输入单位名称",
                      text: logic.companyName,
                      onTextChanged: (value) {
                        logic.companyName.value = value;
                      },
                      validator:
                      FormBuilderValidators.required(errorText: '单位名称不能为空'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                SizedBox(
                  width: 150,
                  child: Row(
                    children: const [
                      Text('报名条件'),
                      Text('*', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
                Container(
                    // color: Colors.grey[100], // 设置背景色
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Row(
                                    children: const [
                                      Text('来源类别'),
                                      Text('*',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: DropdownField(
                                    key: UniqueKey(),
                                    items: [
                                      {'id': '1', 'name': '高校毕业生'},
                                      {'id': '2', 'name': '社会人才'},
                                      {'id': '3', 'name': '高校毕业生或社会人才'}
                                    ],
                                    hint: '',
                                    label: true,
                                    width: 100,
                                    height: 34,
                                    selectedValue: ValueNotifier<String?>(null),
                                    onChanged: (dynamic newValue) {
                                      logic.conditionSource.value =
                                          newValue.toString();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 30,
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Row(
                                    children: const [
                                      Text('学历'),
                                      Text('*',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: DropdownField(
                                    key: UniqueKey(),
                                    items: [
                                      {'id': '1', 'name': '全日制本科以上'},
                                      {'id': '2', 'name': '全日制研究生以上'},
                                    ],
                                    hint: '',
                                    label: true,
                                    width: 150,
                                    height: 34,
                                    selectedValue: ValueNotifier<String?>(null),
                                    onChanged: (dynamic newValue) {
                                      logic.conditionQualification.value =
                                          newValue.toString();
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 30,
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Row(
                                    children: const [
                                      Text('学位'),
                                      Text('*',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: DropdownField(
                                    key: UniqueKey(),
                                    items: [
                                      {'id': '1', 'name': '学士以上'},
                                      {'id': '2', 'name': '硕士以上'},
                                      {'id': '3', 'name': '博士以上'},
                                    ],
                                    hint: '',
                                    label: true,
                                    width: 100,
                                    height: 34,
                                    selectedValue: ValueNotifier<String?>(null),
                                    onChanged: (dynamic newValue) {
                                      logic.conditionDegree.value =
                                          newValue.toString();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Row(
                                    children: const [
                                      Text('所学专业'),
                                      Text('*',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 530,
                                  child: TextInputWidget(
                                    width: 240,
                                    height: 80,
                                    maxLines: 8,
                                    hint: "输入所学专业",
                                    text: logic.conditionMajor,
                                    onTextChanged: (value) {
                                      logic.conditionMajor.value = value;
                                    },
                                    validator: FormBuilderValidators.required(
                                        errorText: '所学专业不能为空'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Row(
                                    children: const [
                                      Text('考试专业'),
                                      Text('*',
                                          style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 530,
                                  child: TextInputWidget(
                                    width: 240,
                                    height: 34,
                                    maxLines: 8,
                                    hint: "输入专业科目",
                                    text: logic.conditionExam,
                                    onTextChanged: (value) {
                                      logic.conditionExam.value = value;
                                    },
                                    validator: FormBuilderValidators.required(
                                        errorText: '专业科目不能为空'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Row(
                                    children: const [
                                      Text('其它条件'),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 530,
                                  child: TextInputWidget(
                                    width: 240,
                                    height: 120,
                                    maxLines: 8,
                                    hint: "输入其它条件",
                                    text: logic.conditionOther,
                                    onTextChanged: (value) {
                                      logic.conditionOther.value = value;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ]),
                    )),
              ]),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Row(
                      children: const [
                        Text('工作地点'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 620,
                    child: TextInputWidget(
                      width: 240,
                      height: 34,
                      maxLines: 8,
                      hint: "输入工作地点",
                      text: logic.jobCity,
                      onTextChanged: (value) {
                        logic.jobCity.value = value;
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
                        Text('咨询电话'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 620,
                    child: TextInputWidget(
                      width: 240,
                      height: 34,
                      maxLines: 8,
                      hint: "输入咨询电话",
                      text: logic.jobPhone,
                      onTextChanged: (value) {
                        logic.jobPhone.value = value;
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
