import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/request/request.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PDFScreen(),
    );
  }
}

class PDFScreen extends StatefulWidget {
  @override
  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfViewerController? _pdfViewerController;
  bool isReady = false;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/aaa.pdf');

    if (!await file.exists()) {
      // 如果文件不存在，可以从网络下载PDF文件
      try {
        final pdfContent = await _downloadPDF();
        await file.writeAsBytes(pdfContent);
      } catch (e) {
        print('Error downloading PDF: $e');
        return;
      }
    }

    setState(() {
      isReady = true;
      _pdfPath = file.path;
    });
  }

  Future<List<int>> _downloadPDF() async {
    // 示例PDF文件URL
    final url = 'https://example.com/aaa.pdf';
    final response = await HttpClient().getUrl(Uri.parse(url));
    final bytes = await response.close();
    return await bytes.toBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Syncfusion PDF Viewer with Watermark'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.bookmark),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
        ],
      ),
      body: isReady && _pdfPath != null
          ? Stack(
        children: [
          SfPdfViewer.file(
            File(_pdfPath!),
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            enableTextSelection: false,
            interactionMode: PdfInteractionMode.pan,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: SingleChildScrollView(
                child: WatermarkLayer(),
              ),
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

class WatermarkLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(50),
      child: Wrap(
        spacing: 50,
        runSpacing: 50,
        children: List.generate(9, (index) { // Adjust this number to control density
          return Transform.rotate(
            angle: -0.4, // Controls the watermark's rotation angle
            child: Opacity(
              opacity: 0.1, // Controls the watermark's transparency
              child: Text(
                'Confidential',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
