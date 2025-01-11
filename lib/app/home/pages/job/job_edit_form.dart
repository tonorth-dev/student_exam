import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hongshi_admin/api/job_api.dart';
import 'package:get/get.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class JobEditForm extends StatefulWidget {
  final int jobId;
  final String initialJobCode;
  final String initialJobName;
  final String initialJobDesc;
  final String initialJobCate;
  final int initialEnrollmentNum;
  final String initialEnrollmentRatio;
  final String initialCompanyCode;
  final String initialCompanyName;
  final String initialConditionSource;
  final String initialConditionQualification;
  final String initialConditionDegree;
  final String initialConditionMajor;
  final String initialConditionExam;
  final String initialConditionOther;
  final String initialJobCity;
  final String initialJobPhone;

  JobEditForm({
    required this.jobId,
    required this.initialJobCode,
    required this.initialJobName,
    required this.initialJobDesc,
    required this.initialJobCate,
    required this.initialEnrollmentNum,
    required this.initialEnrollmentRatio,
    required this.initialCompanyCode,
    required this.initialCompanyName,
    required this.initialConditionSource,
    required this.initialConditionQualification,
    required this.initialConditionDegree,
    required this.initialConditionMajor,
    required this.initialConditionExam,
    required this.initialConditionOther,
    required this.initialJobCity,
    required this.initialJobPhone,
  });

  @override
  State<JobEditForm> createState() => _JobEditFormState();
}

class _JobEditFormState extends State<JobEditForm> {
  final logic = Get.put(JobLogic());
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.updateJob(widget.jobId);
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
    logic.uJobCode.value = widget.initialJobCode;
    logic.uJobName.value = widget.initialJobName;
    logic.uJobDesc.value = widget.initialJobDesc;
    logic.uJobCate.value = widget.initialJobCate;
    logic.uEnrollmentNum.value = widget.initialEnrollmentNum;
    logic.uEnrollmentRatio.value = widget.initialEnrollmentRatio;
    logic.uCompanyCode.value = widget.initialCompanyCode;
    logic.uCompanyName.value = widget.initialCompanyName;
    logic.uConditionSource.value = widget.initialConditionSource;
    logic.uConditionQualification.value = widget.initialConditionQualification;
    logic.uConditionDegree.value = widget.initialConditionDegree;
    logic.uConditionMajor.value = widget.initialConditionMajor;
    logic.uConditionExam.value = widget.initialConditionExam;
    logic.uConditionOther.value = widget.initialConditionOther;
    logic.uJobCity.value = widget.initialJobCity;
    logic.uJobPhone.value = widget.initialJobPhone;
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
                        text: logic.uJobCode,
                        onTextChanged: (value) {
                          logic.uJobCode.value = value;
                        },
                        validator: FormBuilderValidators.required(errorText: '岗位代码不能为空'),
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
                        text: logic.uJobName,
                        onTextChanged: (value) {
                          logic.uJobName.value = value;
                        },
                        validator: FormBuilderValidators.required(errorText: '岗位名称不能为空'),
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
                        text: logic.uJobDesc,
                        onTextChanged: (value) {
                          logic.uJobDesc.value = value;
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
                        text: logic.uJobCate,
                        onTextChanged: (value) {
                          logic.uJobCate.value = value;
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
                        selectedValue: logic.uEnrollmentNum,
                        onValueChanged: (value) {
                          logic.uEnrollmentNum.value = value;
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
                        text: logic.uEnrollmentRatio,
                        onTextChanged: (value) {
                          logic.uEnrollmentRatio.value = value;
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
                        text: logic.uCompanyCode,
                        onTextChanged: (value) {
                          logic.uCompanyCode.value = value;
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
                        text: logic.uCompanyName,
                        onTextChanged: (value) {
                          logic.uCompanyName.value = value;
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
                                      selectedValue: ValueNotifier<String?>(logic.uConditionSource.value),
                                      onChanged: (dynamic newValue) {
                                        logic.uConditionSource.value =
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
                                      selectedValue: ValueNotifier<String?>(logic.uConditionQualification.value),
                                      onChanged: (dynamic newValue) {
                                        logic.uConditionQualification.value =
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
                                      selectedValue: ValueNotifier<String?>(logic.uConditionDegree.value),
                                      onChanged: (dynamic newValue) {
                                        logic.uConditionDegree.value =
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
                                      text: logic.uConditionMajor,
                                      onTextChanged: (value) {
                                        logic.uConditionMajor.value = value;
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
                                      text: logic.uConditionExam,
                                      onTextChanged: (value) {
                                        logic.uConditionExam.value = value;
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
                                      text: logic.uConditionOther,
                                      onTextChanged: (value) {
                                        logic.uConditionOther.value = value;
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
                        text: logic.uJobCity,
                        onTextChanged: (value) {
                          logic.uJobCity.value = value;
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
                        text: logic.uJobPhone,
                        onTextChanged: (value) {
                          logic.uJobPhone.value = value;
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
