import 'package:hongshi_admin/app/home/head/logic.dart';
import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hongshi_admin/api/student_api.dart'; // 导入 student_api.dart
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class StudentEditForm extends StatefulWidget {
  final int studentId;
  final String initialName;
  final String initialPhone;
  final String initialInstitutionId;
  final String initialInstitutionName;
  final String initialClassId;
  final String initialClassName;
  final String initialReferrer;
  final String initialJobCode;
  final String initialJobName;
  final String initialJobDesc;
  final List<String> initialMajorIds;
  final List<String> initialMajorNames;
  final String initialStatus;
  final DateTime? initialExpireTime;

  StudentEditForm({
    required this.studentId,
    required this.initialName,
    required this.initialStatus,
    required this.initialPhone,
    required this.initialInstitutionId,
    required this.initialInstitutionName,
    required this.initialClassId,
    required this.initialClassName,
    required this.initialReferrer,
    required this.initialJobCode,
    required this.initialJobName,
    required this.initialJobDesc,
    required this.initialMajorIds,
    required this.initialMajorNames,
    this.initialExpireTime,
  });

  @override
  State<StudentEditForm> createState() => _StudentEditFormState();
}

class _StudentEditFormState extends State<StudentEditForm> {
  final logic = Get.put(StudentLogic());
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    logic.uName.value = widget.initialName;
    logic.uStatus.value = widget.initialStatus;
    logic.uPhone.value = widget.initialPhone;
    logic.uInstitutionId.value = widget.initialInstitutionId;
    logic.uInstitutionName.value = widget.initialInstitutionName;
    logic.uClassId.value = widget.initialClassId;
    logic.uClassName.value = widget.initialClassName;
    logic.uReferrer.value = widget.initialReferrer;
    logic.uJobCode.value = widget.initialJobCode;
    logic.uJobName.value = widget.initialJobName;
    logic.uJobDesc.value = widget.initialJobDesc;
    logic.uMajorIds.value = widget.initialMajorIds.join(",");
    logic.uMajorNames.value = widget.initialMajorNames.join(",");
    logic.uExpireTime.value = widget.initialExpireTime?.toIso8601String() ?? '';

    // 组装 major names
    List<String> formattedMajorNames = [];
    for (int i = 0; i < widget.initialMajorIds.length; i++) {
      formattedMajorNames.add(
          '${widget.initialMajorNames[i]}（ID：${widget.initialMajorIds[i]}）');
    }
    logic.formattedMajorNames.value = formattedMajorNames;

    List<String> formattedJobNames = [];
    formattedJobNames
        .add("${widget.initialJobName}（ID：${widget.initialJobCode}）");
    logic.formattedJobNames.value = formattedJobNames;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.updateStudent(widget.studentId);
      if (result) {
        Navigator.pop(context);
        // 可以根据需要添加其他逻辑，例如刷新列表
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
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Row(
                      children: const [
                        Text('考生名称'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: TextInputWidget(
                      width: 240,
                      height: 34,
                      maxLines: 1,
                      hint: "输入考生名称",
                      text: logic.uName,
                      onTextChanged: (value) {
                        logic.uName.value = value;
                      },
                      validator:
                          FormBuilderValidators.required(errorText: '考生名称不能为空'),
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
                        Text('状态'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: DropdownField(
                      key: UniqueKey(),
                      items: [
                        {'id': '1', 'name': '未生效'},
                        {'id': '2', 'name': '生效中'},
                        {'id': '5', 'name': '已过期'},
                      ],
                      hint: '',
                      label: true,
                      width: 100,
                      height: 34,
                      selectedValue:
                          ValueNotifier<String?>(logic.uStatus.value),
                      onChanged: (dynamic newValue) {
                        logic.uStatus.value = newValue;
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
                        Text('手机号'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: TextInputWidget(
                      width: 240,
                      height: 34,
                      maxLines: 1,
                      hint: "输入手机号",
                      text: logic.uPhone,
                      onTextChanged: (value) {
                        logic.uPhone.value = value;
                      },
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '手机号不能为空'),
                        FormBuilderValidators.numeric(errorText: '请输入有效的手机号'),
                        FormBuilderValidators.minLength(11,
                            errorText: '手机号至少11位'),
                        FormBuilderValidators.maxLength(11,
                            errorText: '手机号最多11位'),
                      ]),
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
                        Text('机构ID'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: SuggestionTextField(
                      width: 600,
                      height: 34,
                      labelText: '请选择机构',
                      hintText: '输入机构名称',
                      key: Key("add_student_institution_id"),
                      fetchSuggestions: logic.fetchInstructions,
                      initialValue: ValueNotifier<Map<dynamic, dynamic>?>(
                      {
                        'name': logic.uInstitutionName.value,
                        'id': logic.uInstitutionId.value,
                      }),
                      onSelected: (value) {
                        if (value.isEmpty) {
                          logic.institutionId.value = "";
                          return;
                        }
                        logic.institutionId.value = value['id']!;
                      },
                      onChanged: (value) {
                        if (value == null || value.isEmpty) {
                          logic.institutionId.value = ""; // 确保清空
                        }
                        print(
                            "onChanged selectedInstitutionId value: ${logic.selectedInstitutionId.value}");
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
                        Text('班级ID'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: SuggestionTextField(
                      width: 600,
                      height: 34,
                      labelText: '班级选择',
                      hintText: '输入班级名称',
                      key: Key("edit_student_class_id"),
                      fetchSuggestions: logic.fetchClasses,
                      initialValue: ValueNotifier<Map<dynamic, dynamic>?>({
                        'name': logic.uClassName.value,
                        'id': logic.uClassId.value,
                      }),
                      onSelected: (value) {
                        if (value.isEmpty) {
                          logic.uClassId.value = "";
                          return;
                        }
                          logic.uClassId.value = value['id']!;
                      },
                      onChanged: (value) {
                        if (value == null || value.isEmpty) {
                          logic.uClassId.value = ""; // 确保清空
                        }
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
                        Text('专业选择'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: TagInputField(
                      height: 34,
                      width: 600,
                      defaultTags: logic.formattedMajorNames,
                      onTagsUpdated: (tags) {
                        if (tags.length > 3) {
                          return Future.error("专业数量超出限制");
                        }
                        final RegExp idPattern = RegExp(r'ID：(\d+)');

                        // 抽取所有ID并转换为整数列表
                        List<String> ids = tags
                            .map((item) => idPattern.firstMatch(item)?.group(1))
                            .whereType<String>() // 过滤掉可能的null值
                            .toList();
                        // 将ID列表连接成一个由逗号分隔的字符串
                        logic.uMajorIds.value = ids.join(",");
                        return Future.value(); // 返回成功
                      },
                      onTagModifyAsync: (tag) async {
                        if (!RegExp(r'^[0-9]+$').hasMatch(tag)) {
                          return null;
                        }
                        tag = await logic.fetchMajor(tag);
                        if (tag.isEmpty) {
                          return null;
                        }
                        return tag;
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
                        Text('职位代码'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: TagInputField(
                      height: 34,
                      width: 600,
                      defaultTags: logic.formattedJobNames,
                      onTagsUpdated: (tags) {
                        if (tags.length > 1) {
                          return Future.error("只能对应一个岗位");
                        }
                        final RegExp idPattern = RegExp(r'ID：(\d+)');

                        // 抽取所有ID并转换为整数列表
                        List<String> ids = tags
                            .map((item) => idPattern.firstMatch(item)?.group(1))
                            .whereType<String>() // 过滤掉可能的null值
                            .toList();

                        // 将ID列表连接成一个由逗号分隔的字符串
                        logic.uJobCode.value = ids.join(",");
                        return Future.value(); // 返回成功
                      },
                      onTagModifyAsync: (tag) async {
                        if (!RegExp(r'^[0-9]+$').hasMatch(tag)) {
                          return null;
                        }
                        tag = await logic.fetchJob(tag);
                        if (tag.isEmpty) {
                          return null;
                        }
                        return tag;
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
                        Text('推荐人'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: TextInputWidget(
                      width: 240,
                      height: 34,
                      maxLines: 1,
                      hint: "输入推荐人",
                      text: logic.uReferrer,
                      onTextChanged: (value) {
                        logic.uReferrer.value = value;
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
                    onPressed: () => Navigator.pop(context),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25B7E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('保存'),
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
