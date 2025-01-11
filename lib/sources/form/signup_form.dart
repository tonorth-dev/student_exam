import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';

class TopicAddForm extends StatefulWidget {
  const TopicAddForm({super.key});

  @override
  State<TopicAddForm> createState() => _TopicAddFormState();
}

class _TopicAddFormState extends State<TopicAddForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  final quill.QuillController _quillController = quill.QuillController.basic();

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
              const SizedBox(width: 600),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Title:'),
                  ),
                  Expanded(
                    flex: 2,
                    child: FormBuilderTextField(
                      name: 'title',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Category:'),
                  ),
                  Expanded(
                    flex: 2,
                    child: FormBuilderDropdown<int>(
                      name: 'cate',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Category 1')),
                        DropdownMenuItem(value: 2, child: Text('Category 2')),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Answer:'),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        quill.QuillToolbar.simple(controller: _quillController),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: quill.QuillEditor(
                            controller: _quillController,
                            scrollController: ScrollController(),
                            // scrollable: true,
                            focusNode: FocusNode(),
                            // autoFocus: false,
                            // readOnly: false,
                            // expands: true,
                            // padding: const EdgeInsets.all(10.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Author:'),
                  ),
                  Expanded(
                    flex: 2,
                    child: FormBuilderTextField(
                      name: 'author',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Major ID:'),
                  ),
                  Expanded(
                    flex: 2,
                    child: FormBuilderTextField(
                      name: 'major_id',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.integer(),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Major Name:'),
                  ),
                  Expanded(
                    flex: 2,
                    child: FormBuilderTextField(
                      name: 'major_name',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      validator: FormBuilderValidators.required(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    flex: 1,
                    child: Text('Tag:'),
                  ),
                  Expanded(
                    flex: 2,
                    child: FormBuilderTextField(
                      name: 'tag',
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.saveAndValidate() ?? false) {
                        final formData = _formKey.currentState!.value;

                        // Convert Quill document to JSON and HTML
                        final answerJson = jsonEncode(_quillController.document.toDelta().toJson());
                        final answerHtml = "";
                        // encode(delta: _quillController.document.toDelta()).toHtml();

                        formData['answer'] = {
                          'json': answerJson,
                          'html': answerHtml,
                        };

                        debugPrint(formData.toString());
                        Navigator.of(context).pop(formData); // Close dialog with formData
                      }
                    },
                    child: const Text('Submit'),
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
