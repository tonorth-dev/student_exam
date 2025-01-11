import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hongshi_admin/api/topic_api.dart'; // 导入 topic_api.dart
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class TopicAddForm extends StatefulWidget {
  const TopicAddForm({super.key});

  @override
  State<TopicAddForm> createState() => _TopicAddFormState();
}

class _TopicAddFormState extends State<TopicAddForm> {
  final logic = Get.put(TopicLogic());
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.saveTopic();
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
              const SizedBox(width: 800),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Row(
                      children: const [
                        Text('题干'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: TextInputWidget(
                      width: 240,
                      height: 65,
                      maxLines: 8,
                      hint: "输入问题题干",
                      text: logic.topicTitle,
                      onTextChanged: (value) {
                        logic.topicTitle.value = value;
                      },
                      validator:
                          FormBuilderValidators.required(errorText: '题干不能为空'),
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
                        Text('题型'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: DropdownField(
                      items: logic.questionCate.toList(),
                      hint: '',
                      label: true,
                      width: 120,
                      height: 34,
                      selectedValue: logic.topicSelectedQuestionCate,
                      onChanged: (dynamic newValue) {
                        logic.topicSelectedQuestionCate.value =
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
                    width: 150,
                    child: Row(
                      children: const [
                        Text('难度'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: DropdownField(
                      items: logic.questionLevel.toList(),
                      hint: '',
                      label: true,
                      width: 120,
                      height: 34,
                      selectedValue: logic.topicSelectedQuestionLevel,
                      onChanged: (dynamic newValue) {
                        logic.topicSelectedQuestionLevel.value =
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
                    width: 150,
                    child: Row(
                      children: const [
                        Text('专业'),
                        Text('*', style: TextStyle(color: Colors.red)),
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
                        logic.topicSelectedMajorId.value = level3.toString();
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
                        Text('答案'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    height: 300,
                    child: TextInputWidget(
                      width: 240,
                      height: 300,
                      maxLines: 40,
                      hint: "输入问题答案",
                      text: logic.topicAnswer,
                      onTextChanged: (value) {
                        logic.topicAnswer.value = value;
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
                        Text('作者：'),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    child: TextInputWidget(
                      width: 240,
                      height: 34,
                      hint: "输入作者名称",
                      text: logic.topicAuthor,
                      onTextChanged: (value) {
                        logic.topicAuthor.value = value;
                      },
                      // validator: FormBuilderValidators.compose([
                      //   FormBuilderValidators.match(
                      //     RegExp(r'^[a-zA-Z0-9\u4e00-\u9fa5]+$'),
                      //     errorText: '作者名字只能由英文和汉字组成',
                      //   ),
                      // ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: const Text('标签：'),
                  ),
                  SizedBox(
                    width: 600,
                    child: TextInputWidget(
                      width: 240,
                      height: 34,
                      hint: "可以给问题打一个标签",
                      text: logic.topicTag,
                      onTextChanged: (value) {
                        logic.topicTag.value = value;
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
                        Text('试题状态'),
                        Text('*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: SingleSelectForm(
                      // key: Key("status_select"),
                      items: RxList<Map<String, dynamic>>([
                        {'id': 1, 'name': '草稿', 'selected': false},
                        {'id': 2, 'name': '完成', 'selected': false},
                      ]),
                      onSelected: (item) => {
                        logic.topicStatus.value = item['id']
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
