import 'package:student_exam/app/home/pages/note/pdf_pre_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:student_exam/app/home/pages/note/logic.dart';
import 'package:student_exam/common/app_providers.dart';
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
              flex: 4,
              child: Container(
                padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16.0)),
                child: NoteView(),
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16.0)),
                child: PdfPreView(
                    key: const Key("pdf_review"), title: "文件预览"),
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
      body: Column(
        children: [
          _buildSearchBar(),
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
      padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: logic.searchController,
              style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
              decoration: InputDecoration(
                hintText: '搜索题本',
                prefixIcon: Icon(Icons.search, size: screenAdapter.getAdaptiveIconSize(24)),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenAdapter.getAdaptivePadding(8),
                  horizontal: screenAdapter.getAdaptivePadding(12),
                ),
              ),
              onChanged: logic.onSearchChanged,
            ),
          ),
          SizedBox(width: screenAdapter.getAdaptiveWidth(16)),
          ElevatedButton(
            onPressed: logic.onSearch,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: screenAdapter.getAdaptivePadding(10),
                horizontal: screenAdapter.getAdaptivePadding(16),
              ),
            ),
            child: Text(
              '搜索', 
              style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    return Obx(() {
      final books = logic.list;
      
      return SingleChildScrollView(
        child: DataTable(
          columnSpacing: 0,
          showCheckboxColumn: false,
          dataRowHeight: screenAdapter.getAdaptiveHeight(48),
          headingRowHeight: screenAdapter.getAdaptiveHeight(56),
          columns: [
            DataColumn(
              label: SizedBox(
                width: screenAdapter.getAdaptiveWidth(300),
                child: Text(
                  '题本名称',
                  style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: screenAdapter.getAdaptiveWidth(200),
                child: Text(
                  '专业',
                  style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
                ),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: screenAdapter.getAdaptiveWidth(100),
                child: Text(
                  '题目数量',
                  style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
                ),
              ),
            ),
          ],
          rows: _buildTableRows(books),
        ),
      );
    });
  }

  List<DataRow> _buildTableRows(List<Map<String, dynamic>> books) {
    final List<DataRow> rows = [];
    
    for (var book in books) {
      rows.add(_buildBookRow(book, isChild: false));
      
      if (book['Children'] != null && 
          logic.expandedBookIds.contains(book['id'].toString())) {
        final children = List<Map<String, dynamic>>.from(book['Children']);
        for (var childBook in children) {
          rows.add(_buildBookRow(childBook, isChild: true));
        }
      }
    }
    
    return rows;
  }

  DataRow _buildBookRow(Map<String, dynamic> book, {required bool isChild}) {
    final screenAdapter = AppProviders.instance.screenAdapter;
    final isSelected = logic.selectedBookIds.contains(book['id'].toString());
    
    return DataRow(
      color: isSelected ? MaterialStateProperty.all(const Color(0xFFE0F7FA)) : null,
      cells: [
        DataCell(
          SizedBox(
            width: screenAdapter.getAdaptiveWidth(300),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isChild && book['Children'] != null && (book['Children'] as List).isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => logic.toggleExpand(book['id']),
                      child: Container(
                        width: screenAdapter.getAdaptiveWidth(40),
                        height: screenAdapter.getAdaptiveHeight(40),
                        alignment: Alignment.center,
                        child: Text(
                          logic.expandedBookIds.contains(book['id'].toString()) ? '-' : '+',
                          style: TextStyle(
                            fontSize: screenAdapter.getAdaptiveFontSize(24),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isChild) SizedBox(width: screenAdapter.getAdaptiveWidth(40)),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        logic.selectBook(book);
                        logic.updatePdfUrl(book['teacher_file_path'] ?? '');
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: screenAdapter.getAdaptivePadding(8)),
                        child: Text(
                          book['name'] ?? '',
                          style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                logic.selectBook(book);
                logic.updatePdfUrl(book['teacher_file_path'] ?? '');
              },
              child: SizedBox(
                width: screenAdapter.getAdaptiveWidth(200),
                child: Text(
                  book['major_name'] ?? '',
                  style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                logic.selectBook(book);
                logic.updatePdfUrl(book['teacher_file_path'] ?? '');
              },
              child: SizedBox(
                width: screenAdapter.getAdaptiveWidth(100),
                child: Text(
                  book['questions_number']?.toString() ?? '0',
                  style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}