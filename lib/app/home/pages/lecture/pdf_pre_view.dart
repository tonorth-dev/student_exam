import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../component/pdf_viewer/common_pdf_viewer.dart';
import 'logic.dart';

/// PDF 预览页面（讲义模块）
class PdfPreView extends StatefulWidget {
  final String title;

  const PdfPreView({super.key, required this.title});

  @override
  State<PdfPreView> createState() => _PdfPreViewState();
}

class _PdfPreViewState extends State<PdfPreView> {
  final LectureLogic _lectureLogic = Get.put(LectureLogic());

  @override
  Widget build(BuildContext context) {
    return CommonPdfViewer(
      config: PdfViewerConfig(
        pdfUrlStream: _lectureLogic.selectedPdfUrl,
        backgroundImage: 'assets/images/note_page_bg.png',
        enableChapterNavigation: true,
        getNextNode: () => _lectureLogic.getNextNode(),
        getPreviousNode: () => _lectureLogic.getPreviousNode(),
        moveToNextChapter: () => _lectureLogic.moveToNextChapter(),
        moveToPreviousChapter: () => _lectureLogic.moveToPreviousChapter(),
        isNodeValid: (node) =>
            node?.filePath != null &&
            node.filePath!.isNotEmpty &&
            node.children.isEmpty,
      ),
    );
  }
}
