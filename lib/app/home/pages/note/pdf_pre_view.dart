import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../component/pdf_viewer/common_pdf_viewer.dart';
import 'logic.dart';

/// PDF 预览页面（笔记模块）
class PdfPreView extends StatefulWidget {
  final String title;

  const PdfPreView({super.key, required this.title});

  @override
  State<PdfPreView> createState() => _PdfPreViewState();
}

class _PdfPreViewState extends State<PdfPreView> {
  final NoteLogic pdfLogic = Get.put(NoteLogic());

  @override
  Widget build(BuildContext context) {
    return CommonPdfViewer(
      config: PdfViewerConfig(
        pdfUrlStream: pdfLogic.selectedPdfUrl,
        backgroundImage: 'assets/images/note_page_bg.png',
        enableChapterNavigation: false,
      ),
    );
  }
}
