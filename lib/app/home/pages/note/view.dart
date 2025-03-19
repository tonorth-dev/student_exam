import 'package:student_exam/app/home/pages/note/pdf_pre_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:student_exam/app/data/book_model.dart';
import 'package:student_exam/app/home/pages/note/logic.dart';

import '../../sidebar/logic.dart';
import 'note_view.dart';

class NotePage extends StatelessWidget {
  final logic = Get.put(NoteLogic());

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/note_page_bg.png'),
            fit: BoxFit.fill, // Set the image fill method
          ),
        ),
    child: Row(
      children: [
        SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: NoteView(),
          ),
        ),
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: PdfPreView(
                key: const Key("pdf_review"), title: "文件预览"),
          ),
        ),
      ],
    ));
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "查看题本",
      icon: Icons.app_registration_outlined,
      page: NotePage(),
    );
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: logic.searchController,
              decoration: const InputDecoration(
                hintText: '搜索题本',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: logic.onSearchChanged,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: logic.onSearch,
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Obx(() {
      final books = logic.bookList;
      
      return SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('题本名称')),
            DataColumn(label: Text('专业')),
            DataColumn(label: Text('题型')),
            DataColumn(label: Text('题目数量')),
            DataColumn(label: Text('操作')),
          ],
          rows: _buildTableRows(books),
        ),
      );
    });
  }

  List<DataRow> _buildTableRows(List<BookModel> books) {
    final List<DataRow> rows = [];
    
    for (var book in books) {
      // 添加父行
      rows.add(_buildBookRow(book, isChild: false));
      
      // 如果有子题本且当前题本是展开状态，添加子行
      if (book.Children != null && 
          book.Children!.isNotEmpty && 
          logic.expandedRows.contains(book.id)) {
        for (var childBook in book.Children!) {
          rows.add(_buildBookRow(childBook, isChild: true));
        }
      }
    }
    
    return rows;
  }

  DataRow _buildBookRow(BookModel book, {required bool isChild}) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isChild && book.Children != null && book.Children!.isNotEmpty)
                IconButton(
                  icon: Icon(
                    logic.expandedRows.contains(book.id)
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  onPressed: () => logic.toggleExpand(book.id),
                ),
              if (isChild) const SizedBox(width: 32),
              Flexible(child: Text(book.name)),
            ],
          ),
        ),
        DataCell(Text(book.majorName)),
        DataCell(Text(book.levelName)),
        DataCell(Text(book.questionsNumber.toString())),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => logic.downloadBook(book),
                tooltip: '下载题本',
              ),
              IconButton(
                icon: const Icon(Icons.preview),
                onPressed: () => logic.previewBook(book),
                tooltip: '预览题本',
              ),
            ],
          ),
        ),
      ],
    );
  }
}