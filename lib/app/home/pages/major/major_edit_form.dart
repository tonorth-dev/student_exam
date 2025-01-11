import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class MajorEditForm extends StatefulWidget {
  final int majorId;
  final String initialMajorName;
  final String initialFirstLevelCategory;
  final String initialSecondLevelCategory;

  MajorEditForm({
    required this.majorId,
    required this.initialMajorName,
    required this.initialFirstLevelCategory,
    required this.initialSecondLevelCategory,
  });

  @override
  State<MajorEditForm> createState() => _EditMajorDialogState();
}
class _EditMajorDialogState extends State<MajorEditForm> {
  final logic = Get.find<MajorLogic>();
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final result = await logic.updateMajor(widget.majorId);
      if (result) {
        Navigator.pop(context);
        logic.find(logic.size.value, logic.page.value);
      }
    }
  }

  @override
  void initState() {
    print("initialStatus");
    print(widget.majorId);
    super.initState();
    logic.uMajorName.value = widget.initialMajorName;
    logic.uFirstLevelCategory.value = widget.initialFirstLevelCategory;
    logic.uSecondLevelCategory.value = widget.initialSecondLevelCategory;
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
                          Text('一级类别'),
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
                        hint: "输入一级类别",
                        text: widget.initialFirstLevelCategory.obs,
                        onTextChanged: (value) {
                          logic.uFirstLevelCategory.value = value;
                        },
                        validator:
                        FormBuilderValidators.required(errorText: '一级类别不能为空'),
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
                          Text('二级类别'),
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
                        hint: "输入二级类别",
                        text: widget.initialSecondLevelCategory.obs,
                        onTextChanged: (value) {
                          logic.uSecondLevelCategory.value = value;
                        },
                        validator:
                        FormBuilderValidators.required(errorText: '二级类别不能为空'),
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
                          Text('专业名称'),
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
                        hint: "输入专业名称",
                        text: widget.initialMajorName.obs,
                        onTextChanged: (value) {
                          logic.uMajorName.value = value;
                        },
                        validator:
                        FormBuilderValidators.required(errorText: '专业名称不能为空'),
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

