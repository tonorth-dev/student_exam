import 'package:admin_flutter/app/home/head/logic.dart';
import 'package:admin_flutter/ex/ex_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:admin_flutter/api/student_api.dart'; // 导入 student_api.dart
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class StudentAddForm extends StatefulWidget {
  const StudentAddForm({super.key});

  @override
  State<StudentAddForm> createState() => _StudentAddFormState();
}

class _StudentAddFormState extends State<StudentAddForm> {
  final logic = Get.put(StudentLogic());
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.saveStudent();
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
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Row(
                      children: const [
                        Text('考生姓名'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: TextInputWidget(
                      width: 240,
                      height: 34,
                      maxLines: 8,
                      hint: "输入姓名",
                      text: logic.name,
                      onTextChanged: (value) {
                        logic.name.value = value;
                      },
                      validator:
                          FormBuilderValidators.required(errorText: '姓名不能为空'),
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
                      maxLines: 8,
                      hint: "输入手机号",
                      text: logic.phone,
                      onTextChanged: (value) {
                        logic.phone.value = value;
                      },
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(errorText: '手机号不能为空'),
                        FormBuilderValidators.phoneNumber(errorText: '请输入有效的手机号')
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
                        Text('机构选择'),
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
                      initialValue: ValueNotifier<Map<dynamic, dynamic>?>({}),
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
                        print("onChanged selectedInstitutionId value: ${logic.selectedInstitutionId.value}");
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
                        Text('班级选择'),
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
                      key: Key("add_student_class_id"),
                      fetchSuggestions: logic.fetchClasses,
                      initialValue: ValueNotifier<Map<dynamic, dynamic>?>({}),
                      onSelected: (value) {
                        if (value == '') {
                          logic.classId.value = "";
                          return;
                        }
                        logic.classId.value = value['id']!;
                      },
                      onChanged: (value) {
                        if (value == null || value.isEmpty) {
                          logic.classId.value = ""; // 确保清空
                        }
                        print("onChanged selectedInstitutionId value: ${logic.classId.value}");
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
                      // defaultTags: ['Flutter', 'Dart'],
                      // onChange: (value) {
                      //   print('Current input: $value');
                      // },
                      onTagsUpdated: (tags) {
                        print('Selected tags: $tags');
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
                        print('选中的ID列表：${ids.join(",")}');

                        logic.majorIds.value = ids.join(",");
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
                    ),),
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
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: TagInputField(
                      height: 34,
                      width: 600,
                      // defaultTags: ['Flutter', 'Dart'],
                      // onChange: (value) {
                      //   print('Current input: $value');
                      // },
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
                        print('选中的ID列表：${ids.join(",")}');
                        logic.jobCode.value = ids.join(",");
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
                    ),),
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
                      maxLines: 8,
                      hint: "输入推荐人",
                      text: logic.referrer,
                      onTextChanged: (value) {
                        logic.referrer.value = value;
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
                      ],
                      hint: '',
                      label: true,
                      width: 100,
                      height: 34,
                      selectedValue:
                          ValueNotifier<String?>(logic.status.value.toString()),
                      onChanged: (dynamic newValue) {
                        print(newValue);
                        logic.status.value = newValue;
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
