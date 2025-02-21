import 'dart:io';
import 'dart:async';
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
  StreamSubscription? _pdfUrlSubscription;
  
  // 修改缩放相关变量
  double _currentZoom = 1.0;
  static const double _zoomStep = 0.1;
  static const int _maxZoomClicks = 8;
  static const double _minZoom = 0.5; // 添加最小缩放限制

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController(); // 初始化控制器
    _pdfUrlSubscription = pdfLogic.selectedPdfUrl.listen((url) {
      if (url != null && mounted) {
        _initializePdf(url);
      }
    });
  }

  @override
  void dispose() {
    _pdfUrlSubscription?.cancel();
    _pdfController?.dispose();
    super.dispose();
  }

  Future<bool> _isCacheValid(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        // 检查文件大小是否为0
        if (fileSize == 0) {
          debugPrint('Cache file exists but is empty');
          return false;
        }
        // 检查文件最后修改时间
        final lastModified = await file.lastModified();
        final now = DateTime.now();
        // 缓存保留7天
        final isValid = now.difference(lastModified).inDays < 7;
        debugPrint('Cache ${isValid ? "valid" : "expired"} for: $filePath');
        return isValid;
      }
    } catch (e) {
      debugPrint('Error checking cache: $e');
    }
    return false;
  }

  Future<String> _getLocalFilePath(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    // 使用URL的哈希值作为文件名，避免中文路径问题
    final fileName = Uri.parse(url).pathSegments.last;
    final fileNameHash = '${fileName.hashCode}_${url.hashCode}';
    return '${directory.path}/pdf_cache/$fileNameHash.pdf';
  }

  Future<void> _initializePdf(String url) async {
    if (_currentUrl == url || url.isEmpty) {
      debugPrint("Same URL, skipping reinitialization.");
      return;
    }

    debugPrint('Initializing PDF with URL: $url');
    try {
      final localPath = await _getLocalFilePath(url);
      final file = File(localPath);

      if (await _isCacheValid(localPath)) {
        debugPrint('Using cached PDF at: $localPath');
        if (mounted) {
          setState(() {
            _currentUrl = url;
            _localFilePath = localPath;
          });
        }
        return; // 如果缓存有效，直接返回
      }

      debugPrint('Downloading PDF from remote URL: $url');
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // 确保目录存在
        final directory = file.parent;
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        // 先写入临时文件
        final tempFile = File('${localPath}_temp');
        await tempFile.writeAsBytes(response.bodyBytes);
        
        // 验证文件写入成功
        if (await tempFile.exists() && await tempFile.length() > 0) {
          // 重命名为正式文件
          await tempFile.rename(localPath);
          debugPrint('PDF cached successfully at: $localPath');

          if (mounted) {
            setState(() {
              _currentUrl = url;
              _localFilePath = localPath;
            });
          }
        } else {
          throw Exception('Failed to write PDF file');
        }
      } else {
        throw Exception('下载PDF失败：状态码 ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error initializing PDF: $e');
      if (mounted) {
        _showError('PDF加载失败：${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: SelectableText.rich(
          TextSpan(
            text: message,
            style: const TextStyle(color: Colors.red),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _currentZoom < (1 + _zoomStep * _maxZoomClicks)
                      ? () {
                          setState(() {
                            _currentZoom = (_currentZoom + _zoomStep)
                                .clamp(1.0, 1 + _zoomStep * _maxZoomClicks);
                            _pdfController?.zoomLevel = _currentZoom;
                          });
                        }
                      : null,
                  tooltip: '放大',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${(_currentZoom * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _currentZoom > 1.0
                      ? () {
                          setState(() {
                            _currentZoom = (_currentZoom - _zoomStep)
                                .clamp(1.0, 1 + _zoomStep * _maxZoomClicks);
                            _pdfController?.zoomLevel = _currentZoom;
                          });
                        }
                      : null,
                  tooltip: '还原',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 25),
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 8),
              ThemeUtil.lineH(),
              ThemeUtil.height(),
              Expanded(
                child: Obx(() {
                  final selectedPdfUrl = pdfLogic.selectedPdfUrl.value;
                  
                  if (selectedPdfUrl == null || selectedPdfUrl.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16.0),
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

                  if (_localFilePath == null || _currentUrl != selectedPdfUrl) {
                    _initializePdf(selectedPdfUrl);
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final file = File(_localFilePath!);
                  if (!file.existsSync()) {
                    _initializePdf(selectedPdfUrl);
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return Stack(
                    children: [
                      SfPdfViewer.file(
                        file,
                        key: ValueKey(_localFilePath),
                        controller: _pdfController,
                        enableTextSelection: false,
                        enableDocumentLinkAnnotation: false,
                        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                          debugPrint('PDF load failed: ${details.error}');
                          _initializePdf(selectedPdfUrl);
                        },
                      ),
                      _buildZoomControls(),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
