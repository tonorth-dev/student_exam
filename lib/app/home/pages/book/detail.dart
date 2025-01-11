import 'package:hongshi_admin/ex/ex_hint.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:get/get.dart';
import '../../../../api/book_api.dart';
import '../../../../api/topic_api.dart';
import '../../../../common/config_util.dart';
import '../../../../component/widget.dart';
import 'logic.dart';

class QuestionDetailPage extends StatefulWidget {
  final int id;

  const QuestionDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  _QuestionDetailPageState createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;
  late Map<int, int?> _selectedQuestions;
  final logic = Get.put(BookLogic());

  @override
  void initState() {
    super.initState();
    _selectedQuestions = {};
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _fetchQuestionDetail(widget.id);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "加载失败：$e";
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchQuestionDetail(int id) async {
    final response = await BookApi.bookDetail(id);
    if (response != 0) {
      return response;
    } else {
      throw Exception('Failed to fetch question detail: ${response['msg']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _data != null
            ? Text(_data!['name'],
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'OPPOSans',
                    color: Color(0xFF003F91)))
            : Text("题本详情",
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'OPPOSans',
                    color: Color(0xFF051923))),
        actions: [
          OutlinedButton.icon(
            icon: Icon(Icons.save_alt),
            label: Text('导出教师版'),
            onPressed: () => _exportPdf(isTeacherVersion: true),
            style: ButtonStyle(
              side: MaterialStateProperty.all<BorderSide>(
                BorderSide(color: Colors.redAccent, width: 2.0),
              ),
              foregroundColor:
                  MaterialStateProperty.all<Color>(Colors.redAccent),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
            ),
          ),
          SizedBox(width: 16),
          OutlinedButton.icon(
            icon: Icon(Icons.save),
            label: Text('导出考生版'),
            onPressed: () => _exportPdf(isTeacherVersion: false),
            style: ButtonStyle(
              side: MaterialStateProperty.all<BorderSide>(
                BorderSide(color: Colors.blueAccent, width: 2.0),
              ),
              foregroundColor:
                  MaterialStateProperty.all<Color>(Colors.blueAccent),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
            ),
          ),
          SizedBox(
            width: 300,
          )
        ],
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1660),
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_data == null) return SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (previous content)
          ...(_buildTables()),
        ],
      ),
    );
  }

  List<Widget> _buildTables() {
    key: ValueKey(_data.hashCode);
    final questionsDesc = _data?['questions_desc'] as List?;
    if (questionsDesc == null || questionsDesc.isEmpty) return [];

    return questionsDesc.map((section) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            '章节：${section['title']}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              fontFamily: 'OPPOSans',
              color: Color(0xFFf3722c),
            ),
          ),
          SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.grey, width: 1),
            columnWidths: {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(120),
              2: FixedColumnWidth(290),
              3: FixedColumnWidth(840),
              4: FixedColumnWidth(120),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Color(0xFF68b0ab)),
                children: [
                  _buildTableHeader('序号'),
                  _buildTableHeader('试题ID'),
                  _buildTableHeader('试题标题'),
                  _buildTableHeader('试题答案'),
                  _buildTableHeader('操作'),
                ],
              ),
              for (var detail in (section['questions_detail'] as List? ?? []))
                for (var i = 0; i < (detail['list'] as List? ?? []).length; i++)
                  TableRow(
                    children: [
                      _buildTableCell(Text((i + 1).toString())),
                      _buildTableCell(Text(detail['list'][i]['id'].toString())),
                      _buildTableCell(Text(detail['list'][i]['title'] ?? "")),
                      _buildTableCell(Text(detail['list'][i]['answer'] ?? "")),
                      _buildTableCell(
                        Container(
                          alignment: Alignment.center,
                          height: 100, // 确保固定高度，便于居中
                          child: _buildChangeOrSaveButton(detail['list'][i]),
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ],
      );
    }).toList();
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFf5f5f5)),
      ),
    );
  }

  Widget _buildTableCell(Widget child) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: child,
    );
  }

  Future<void> _onChangeButtonPressed(dynamic question) async {
    _selectedQuestions = {};
    logic.newTopicId.value = 0;
    setState(() {
      _selectedQuestions[question['id']] = null;
    });

    await Get.defaultDialog(
      title: "更换试题",
      titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFf3722c)),
      titlePadding: EdgeInsets.all(20),
      // 移除默认的标题内边距
      content: Container(
        width: 500, // 调整宽度以适应不同屏幕尺寸
        height: 300, // 减小高度，使对话框更紧凑
        padding: EdgeInsets.all(0), // 增加内边距以提供更好的视觉效果
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10), // 添加一些间距
            SuggestionTextField(
              width: double.infinity,
              // 让输入框占据整个宽度
              height: 40,
              // 增加输入框的高度
              labelText: '筛选题目',
              hintText: '输入题目标题或ID',
              key: logic.topicTextFieldKey,
              fetchSuggestions: logic.fetchTopics,
              initialValue: ValueNotifier<Map<dynamic, dynamic>?>({
                'name': question["title"],
                'id': question["id"],
              }),
              onSelected: (value) {
                if (value.isEmpty) {
                  logic.newTopicId.value = 0;
                  return;
                }
                logic.newTopicId.value = int.parse(value['id']);
              },
              onChanged: (value) {
                if (value == null || value.isEmpty) {
                  logic.newTopicId.value = 0;
                }
              },
            ),
          ],
        ),
      ),
      textCancel: "取消",
      // 将取消按钮文本改为中文
      textConfirm: "确定",
      // 将确认按钮文本改为中文
      // buttonColor: Colors.red,
      // 设置按钮背景颜色
      confirmTextColor: Colors.white,
      // 设置确认按钮文本颜色
      cancelTextColor: Colors.black,
      // 设置取消按钮文本颜色
      radius: 2,
      // 设置对话框圆角半径
      barrierDismissible: false,
      // 点击外部不可关闭对话框
      onConfirm: () async {
        final newQuestionId = logic.newTopicId.value;
        await _onPopSaveButtonPressed(question, newQuestionId);
      },
      onCancel: () => _onPopCancelButtonPressed(question),
    );
  }

    Future<void> _onPopSaveButtonPressed(dynamic question, int newId) async {
    if (newId <= 0 || newId == question['id']) {
      setState(() {
        _selectedQuestions.remove(question['id']);
      });
      logic.newTopicId.value = 0;
      Get.back();
      return;
    }
    var response = await TopicApi.topicDetail(newId.toString());
    setState(() {
      // 更新数据源中的题目信息（假设 _data 中 questions_desc 是可变的）
      final questionsDesc = _data?['questions_desc'] as List?;
      if (questionsDesc != null) {
        for (var section in questionsDesc) {
          for (var detail in (section['questions_detail'] as List? ?? [])) {
            final list = detail['list'] as List?;
            if (list != null) {
              for (var item in list) {
                if (item['id'] == question['id']) {
                  item['title'] = response["title"];
                  item['answer'] = response["answer"];
                }
              }
            }
          }
        }
      }
    });
    _selectedQuestions[question['id']] = newId;
    Get.back();
  }

  Future<void> _onPopCancelButtonPressed(dynamic question) async {
    setState(() {
      _selectedQuestions = {};
    });
    logic.newTopicId.value = 0;
  }

  Future<void> _onSaveButtonPressed(int bookID, dynamic question, int newId) async {
    try {
      await logic.changeTopic(bookID, question['id'], newId);
      "换题成功".toHint();
    } catch (e) {
      "换题失败：$e".toHint();
    }
    await _refreshTable();
    setState(() {
      _selectedQuestions = {};
    });
  }

  Future<void> _refreshTable() async {
    try {
      final data = await _fetchQuestionDetail(widget.id);

      setState(() {
        _data = data; // 更新为新数据
      });
    } catch (e) {
      setState(() {
        _errorMessage = "加载失败：$e";
      });
    }
  }

  Future<void> _onCancelButtonPressed(dynamic question) async {
    _selectedQuestions = {};
    logic.newTopicId.value = 0;
    setState(() {
      _selectedQuestions = {};
      _data = null; // 清空当前数据
    });
    await _refreshTable();
  }

  Widget _buildChangeOrSaveButton(Map<String, dynamic> question) {
    final isEditing = _selectedQuestions.containsKey(question['id']);

    if (isEditing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () =>
                _onSaveButtonPressed(
                    widget.id, question, logic.newTopicId.value),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red, // 设置文本颜色为白色
              minimumSize: Size(80, 40), // 设置最小宽度和高度，使按钮更方
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // 边缘圆角半径，值越小越接近方形
              ),
            ),
            child: Text('保存'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _onCancelButtonPressed(question),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, // 设置背景颜色为红色
              backgroundColor: Colors.grey, // 设置文本颜色为白色
              minimumSize: Size(80, 40), // 设置最小宽度和高度，使按钮更方
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // 边缘圆角半径，值越小越接近方形
              ),
            ),
            child: Text('取消'),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        onPressed: () => _onChangeButtonPressed(question),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, // 设置背景颜色为蓝色
          backgroundColor: Colors.blue, // 设置文本颜色为白色
          minimumSize: Size(80, 40), // 设置最小宽度和高度，使按钮更方
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // 边缘圆角半径，值越小越接近方形
          ),
        ),
        child: Text('换题'),
      );
    }
  }

  Future<void> _exportPdf({required bool isTeacherVersion}) async {
    try {
      // 调用 generateBookData 方法
      final response = await BookApi.generateBook(widget.id, isTeacher: isTeacherVersion);

      // 检查响应状态码
      if (!response['url'].isEmpty) {
        // 获取 PDF 文件的 URL
        final pdfUrl = "${ConfigUtil.ossUrl}:${ConfigUtil.ossPort}${ConfigUtil.ossPrefix}${response['url']}";

        // 下载 PDF 文件
        await _downloadAndOpenPdf(pdfUrl);
      } else {
        throw Exception('Failed to generate PDF: ${response['msg']}');
      }
    } catch (e) {
      print('Error in _exportPdf: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败：$e')),
      );
    }
  }

  Future<void> _downloadAndOpenPdf(String pdfUrl) async {
    try {
      // 获取应用的临时目录
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/output.pdf';

      // 使用 Dio 下载文件
      final dio = Dio();
      await dio.download(pdfUrl, filePath);

      // 打开下载的 PDF 文件
      await OpenFile.open(filePath);
    } catch (e) {
      print('Error in _downloadAndOpenPdf: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载或打开文件失败：$e')),
      );
    }
  }
}
