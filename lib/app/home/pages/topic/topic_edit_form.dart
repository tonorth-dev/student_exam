import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class TopicEditForm extends StatefulWidget {
  final int topicId;
  final String initialTitle;
  final String initialAnswer;
  ValueNotifier<String?> initialQuestionCate;
  ValueNotifier<String?> initialQuestionLevel;
  final String initialLevel1MajorId;
  final String initialLevel2MajorId;
  final String initialMajorId;
  final String initialAuthor;
  final String initialTag;
  final int initialStatus;

  TopicEditForm({
    required this.topicId,
    required this.initialTitle,
    required this.initialAnswer,
    required this.initialQuestionCate,
    required this.initialQuestionLevel,
    required this.initialLevel1MajorId,
    required this.initialLevel2MajorId,
    required this.initialMajorId,
    required this.initialAuthor,
    required this.initialTag,
    required this.initialStatus,
  });

  @override
  State<TopicEditForm> createState() => _EditTopicDialogState();
}

class _EditTopicDialogState extends State<TopicEditForm> {
  final logic = Get.find<TopicLogic>();
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.updateTopic(widget.topicId);
      if (result) {
        Navigator.pop(context);
        logic.find(logic.size.value, logic.page.value); // todo 这里改成只刷新某条数据
      }
    }
  }

  @override
  void initState() {
    print("initialStatus");
    print(widget.initialStatus);
    super.initState();
    logic.uTopicTitle.value = widget.initialTitle;
    logic.uTopicSelectedQuestionCate.value = widget.initialQuestionCate.value!;
    logic.uTopicSelectedQuestionLevel.value = widget.initialQuestionLevel.value!;
    logic.uTopicSelectedMajorId.value = widget.initialMajorId;
    logic.uTopicAnswer.value = widget.initialAnswer;
    logic.uTopicAuthor.value = widget.initialAuthor;
    logic.uTopicTag.value = widget.initialTag;
    logic.uTopicStatus.value = widget.initialStatus;
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
                        text: widget.initialTitle.obs,
                        onTextChanged: (value) {
                          logic.uTopicTitle.value = value;
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
                        selectedValue: widget.initialQuestionCate,
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
                        selectedValue: widget.initialQuestionLevel,
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
                        level1Items: logic.level1Items,
                        level2Items: logic.level2Items,
                        level3Items: logic.level3Items,
                        selectedLevel1: ValueNotifier(
                            logic.getLevel1IdFromLevel2Id(
                                logic.getLevel2IdFromLevel3Id(
                                    widget.initialMajorId))),
                        selectedLevel2: ValueNotifier(logic
                            .getLevel2IdFromLevel3Id(widget.initialMajorId)),
                        selectedLevel3: ValueNotifier(widget.initialMajorId),
                        onChanged:
                            (dynamic level1, dynamic level2, dynamic level3) {
                          print(
                              "level1: $level1, level2: $level2, level3: $level3");
                          logic.uTopicSelectedMajorId.value = level3.toString();
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
                      child: TextInputWidget(
                        width: 240,
                        height: 300,
                        maxLines: 40,
                        hint: "输入问题答案",
                        text: widget.initialAnswer.obs,
                        onTextChanged: (value) {
                          logic.uTopicAnswer.value = value;
                        },
                        validator:
                            FormBuilderValidators.required(errorText: '答案不能为空'),
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
                          Text('作者'),
                          Text('*', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 600,
                      child: TextInputWidget(
                        width: 240,
                        maxLines: 1,
                        hint: "输入作者名称",
                        text: widget.initialAuthor.obs,
                        onTextChanged: (value) {
                          logic.uTopicAuthor.value = value;
                        },
                        validator:
                            FormBuilderValidators.required(errorText: '作者不能为空'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: const Text('标签'),
                    ),
                    SizedBox(
                      width: 600,
                      child: TextInputWidget(
                        width: 240,
                        maxLines: 1,
                        hint: "可以给问题打一个标签",
                        text: widget.initialTag.obs,
                        onTextChanged: (value) {
                          logic.uTopicTag.value = value;
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
                      width: 240,
                      child: SingleSelectForm(
                        key: Key("status_select"),
                        defaultSelectedId: widget.initialStatus,
                        items: RxList<Map<String, dynamic>>([
                          {'id': 1, 'name': '草稿'},
                          {'id': 2, 'name': '完成'},
                        ]),
                        onSelected: (item) =>
                            {logic.uTopicStatus.value = item['id']},
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
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700]),
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
      ),
    );
  }
}
