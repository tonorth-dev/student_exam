import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:admin_flutter/api/classes_api.dart'; // 导入 classes_api.dart
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../component/widget.dart';
import 'c_logic.dart';

class ClassesAddForm extends StatefulWidget {
  const ClassesAddForm({super.key});

  @override
  State<ClassesAddForm> createState() => _ClassesAddFormState();
}

class _ClassesAddFormState extends State<ClassesAddForm> {
  final logic = Get.put(CLogic());
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.saveClasses();
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
                        Text('班级名称'),
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
                      hint: "输入班级名称",
                      text: logic.name,
                      onTextChanged: (value) {
                        logic.name.value = value;
                      },
                      validator:
                      FormBuilderValidators.required(errorText: '班级名称不能为空'),
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
                        Text('教师姓名'),
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
                      hint: "输入教师姓名",
                      text: logic.teacher,
                      onTextChanged: (value) {
                        logic.teacher.value = value;
                      },
                      validator:
                      FormBuilderValidators.required(errorText: '教师姓名不能为空'),
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
