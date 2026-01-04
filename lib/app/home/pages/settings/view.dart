import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_exam/api/student_api.dart';
import 'package:student_exam/common/app_data.dart';
import 'package:student_exam/theme/ui_theme.dart';
import 'package:student_exam/ex/ex_hint.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _workContentController = TextEditingController();
  var _isLoading = true;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWorkContent();
  }

  Future<void> _loadWorkContent() async {
    try {
      setState(() => _isLoading = true);
      
      // 调用API获取学生信息
      var studentInfo = await StudentApi.getStudentInfo();
      
      // 从API返回的数据中获取工作内容（注意：后端返回的是下划线命名 work_content）
      if (studentInfo != null && studentInfo['work_content'] != null) {
        _workContentController.text = studentInfo['work_content'];
        
        // 同步保存到本地
        await LoginData.easySave((data) {
          data.workContent = studentInfo['work_content'];
        });
      }
    } catch (e) {
      print('加载工作内容失败: $e');
      '加载工作内容失败'.toHint();
      
      // 如果API调用失败，尝试从本地获取
      try {
        var data = await LoginData.read();
        if (data.workContent != null) {
          _workContentController.text = data.workContent!;
        }
      } catch (localError) {
        print('从本地加载工作内容也失败: $localError');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveWorkContent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);
      
      // 调用API保存到服务器
      await StudentApi.updateWorkContent(_workContentController.text);
      
      // 保存到本地
      await LoginData.easySave((data) {
        data.workContent = _workContentController.text;
      });
      
      '保存成功'.toHint();
    } catch (e) {
      print('保存工作内容失败: $e');
      '保存工作内容失败: $e'.toHint();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '工作内容设置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: UiTheme.primary(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _workContentController,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: '工作内容',
                        hintText: '请输入您的工作内容（不超过20字）',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入工作内容';
                        }
                        if (value.length > 20) {
                          return '工作内容不能超过20字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveWorkContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UiTheme.primary(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('保存', style: TextStyle(fontSize: 16,color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _workContentController.dispose();
    super.dispose();
  }
}
