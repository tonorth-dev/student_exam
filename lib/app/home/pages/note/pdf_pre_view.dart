import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

import '../../../../component/table/ex.dart';
import '../../../../theme/theme_util.dart';
import 'logic.dart';

class PdfPreView extends StatefulWidget {
  final String title;

  const PdfPreView({Key? key, required this.title}) : super(key: key);

  @override
  _PdfPreViewState createState() => _PdfPreViewState();
}

class _PdfPreViewState extends State<PdfPreView> {
  final NoteLogic pdfLogic = Get.put(NoteLogic());
  PdfViewerController? _pdfController;
  String? _currentUrl;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    pdfLogic.selectedPdfUrl.listen((url) async {
      if (url != null) {
        await _initializePdf(url);
      }
    });
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<String> _getLocalFilePath(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = Uri.parse(url).pathSegments.last;
    return '${directory.path}/$fileName';
  }

  Future<bool> _isCacheValid(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final lastModified = await file.lastModified();
      final now = DateTime.now();
      return now.difference(lastModified).inDays < 3;
    }
    return false;
  }

  Future<void> _initializePdf(String url) async {
    if (_currentUrl == url || url.isEmpty) {
      debugPrint("Same URL, skipping reinitialization.");
      return;
    }

    debugPrint('Initializing PDF with URL: $url');
    try {
      final localPath = await _getLocalFilePath(url);
      if (await _isCacheValid(localPath)) {
        debugPrint('Using cached PDF at: $localPath');
        setState(() {
          _currentUrl = url;
          _localFilePath = localPath;
        });
      } else {
        debugPrint('Downloading PDF from remote URL.');
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final file = File(localPath);
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('PDF cached at: $localPath');
          setState(() {
            _currentUrl = url;
            _localFilePath = localPath;
          });
        } else {
          debugPrint('Failed to download PDF. Status code: ${response.statusCode}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load PDF: ${response.statusCode}')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 在这里放置你想要在左边显示的内容
        SizedBox(width:25),
        Expanded(
          child: Column(
            children: [
              SizedBox(height: 8),
              ThemeUtil.lineH(),
              ThemeUtil.height(),
              Expanded(
                child: Obx(() {
                  final selectedPdfUrl = pdfLogic.selectedPdfUrl.value;
                  if (selectedPdfUrl == null || selectedPdfUrl.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      child: Center(
                        child: Text(
                          "请选择一个文件",
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return _localFilePath != null
                      ? SfPdfViewer.file(File(_localFilePath!))
                      : Center(child: CircularProgressIndicator());
                }),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
