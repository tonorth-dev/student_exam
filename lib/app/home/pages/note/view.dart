import 'package:student_exam/app/home/pages/note/pdf_pre_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:student_exam/app/home/pages/note/logic.dart';
import 'package:student_exam/common/app_providers.dart';
import '../../../../component/widget.dart';
import '../../../../theme/theme_util.dart';
import '../common/app_bar.dart';

import '../../sidebar/logic.dart';
import 'note_view.dart';
import '../../head/logic.dart';

class NotePage extends StatefulWidget {
  const NotePage({Key? key}) : super(key: key);

  @override
  _NotePageState createState() => _NotePageState();

  static SidebarTree newThis() {
    return SidebarTree(
      name: "查看题本",
      icon: Icons.app_registration_outlined,
      page: NotePage(),
    );
  }
}

class _NotePageState extends State<NotePage> {
  final logic = Get.put(NoteLogic());
  final headerLogic = Get.put(HeadLogic());

  @override
  Widget build(BuildContext context) {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Scaffold(
      appBar: CommonAppBar.buildExamAppBar(),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/note_page_bg.png'),
            fit: BoxFit.fill, // Set the image fill method
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: screenAdapter.getAdaptiveWidth(8)),
            Expanded(
              flex: 9,
              child: Container(
                padding: EdgeInsets.only(left: 10, right: 0, top: 32,bottom: 16),
                child: NoteView(),
              ),
            ),
            Expanded(
              flex: 17,
              child: Container(
                padding: EdgeInsets.only(left: 20, right: 16, top: 16,bottom: 16),
                child: PdfPreView(key: const Key("pdf_review"), title: "文件预览"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Get.delete<HeadLogic>();
    super.dispose();
  }
}

class NoteView extends StatelessWidget {
  final logic = Get.put(NoteLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildSearchBar(),
          ThemeUtil.lineH(),
          ThemeUtil.height(),
          Expanded(
            child: _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenAdapter.getAdaptivePadding(8),
        vertical: screenAdapter.getAdaptivePadding(8),
      ),
      child: Row(
        children: [
          SearchBoxWidget(
            key: Key('keywords'),
            hint: '输入题本名称',
            width: screenAdapter.getAdaptiveWidth(170),
            onTextChanged: (String value) {
              logic.searchText.value = value;
            },
            searchText: logic.searchText,
          ),
          SizedBox(width: screenAdapter.getAdaptiveWidth(10)),
          SearchButtonWidget(
            width: screenAdapter.getAdaptiveWidth(55),
            height: screenAdapter.getAdaptiveHeight(30),
            key: Key('search'),
            onPressed: () {
              logic.selectedBookIds.clear();
              logic.fetchData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Obx(() {
      final books = logic.list;

      return Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Table(
                columnWidths: {
                  0: FixedColumnWidth(screenAdapter.getAdaptiveWidth(260)),
                  1: FixedColumnWidth(screenAdapter.getAdaptiveWidth(130)),
                  2: FixedColumnWidth(screenAdapter.getAdaptiveWidth(90)),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    children: [
                      _buildHeaderCell('题本名称'),
                      _buildHeaderCell('专业'),
                      _buildHeaderCell('题目数量'),
                    ],
                  ),
                ],
              ),
              ...books.expand((book) {
                final rows = [
                  _buildBookRowWidget(book, false),
                ];

                if (book['Children'] != null &&
                    logic.expandedBookIds.contains(book['id'].toString())) {
                  final children = List<Map<String, dynamic>>.from(book['Children']);
                  rows.addAll(
                    children.map((childBook) => _buildBookRowWidget(childBook, true)),
                  );
                }

                return rows;
              }).toList(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBookRowWidget(Map<String, dynamic> book, bool isChild) {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Container(
      decoration: BoxDecoration(
        color: logic.selectedBookIds.contains(book['id'].toString())
            ? const Color(0xFFE3F2FD)
            : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            logic.selectBook(book);
            logic.updatePdfUrl(book['teacher_file_path'] ?? '');
          },
          hoverColor: Color(0x1C26395f),
          child: Row(
            children: [
              SizedBox(
                width: screenAdapter.getAdaptiveWidth(260),
                child: _buildNameCell(book, isChild),
              ),
              SizedBox(
                width: screenAdapter.getAdaptiveWidth(130),
                child: _buildClickableCell(book['major_name'] ?? '', book),
              ),
              SizedBox(
                width: screenAdapter.getAdaptiveWidth(90),
                child: _buildClickableCell(book['questions_number']?.toString() ?? '0', book),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenAdapter.getAdaptivePadding(12),
        horizontal: screenAdapter.getAdaptivePadding(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: screenAdapter.getAdaptiveFontSize(14),
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNameCell(Map<String, dynamic> book, bool isChild) {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenAdapter.getAdaptivePadding(8),
        horizontal: screenAdapter.getAdaptivePadding(16),
      ),
      child: Row(
        children: [
          if (!isChild && book['Children'] != null && (book['Children'] as List).isNotEmpty)
            InkWell(
              onTap: () => logic.toggleExpand(book['id']),
              child: Container(
                width: screenAdapter.getAdaptiveWidth(24),
                height: screenAdapter.getAdaptiveHeight(24),
                margin: EdgeInsets.only(right: screenAdapter.getAdaptivePadding(8)),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(screenAdapter.getAdaptiveWidth(4)),
                ),
                child: Center(
                  child: Text(
                    logic.expandedBookIds.contains(book['id'].toString()) ? '-' : '+',
                    style: TextStyle(
                      fontSize: screenAdapter.getAdaptiveFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (isChild) SizedBox(width: screenAdapter.getAdaptiveWidth(32)),
          Expanded(
            child: Text(
              book['name'] ?? '',
              style: TextStyle(
                fontSize: screenAdapter.getAdaptiveFontSize(14),
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableCell(String text, Map<String, dynamic> book) {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenAdapter.getAdaptivePadding(8),
        horizontal: screenAdapter.getAdaptivePadding(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: screenAdapter.getAdaptiveFontSize(14),
          color: Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
