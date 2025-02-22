import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

import '../../../../common/encr_util.dart';
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
    _pdfController = PdfViewerController();
    _cleanupUnencryptedCache();
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
    // 清理临时文件
    if (_localFilePath != null) {
      final tempFile = File(_localFilePath!);
      tempFile.delete().catchError((e) => debugPrint('Error deleting temp file: $e'));
    }
    super.dispose();
  }

  Future<void> _cleanupUnencryptedCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final startDate = DateTime(2025, 2, 17);
      final endDate = DateTime(2025, 2, 23);
      
      // 获取目录下所有文件
      final files = await directory.list(recursive: false).toList();
      
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          try {
            final stat = await entity.stat();
            final createTime = stat.changed;
            
            // 检查文件创建时间是否在指定范围内
            if (createTime.isAfter(startDate) && 
                createTime.isBefore(endDate.add(const Duration(days: 1)))) {
              await entity.delete();
              debugPrint('Deleted PDF created on ${createTime.toString()}: ${entity.path}');
            }
          } catch (e) {
            debugPrint('Error checking file ${entity.path}: $e');
            continue;
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning cache: $e');
    }
  }

  Future<String> _getLocalFilePath(String url) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // 使用URL的base64编码作为文件名，保留扩展名信息
      final urlBytes = utf8.encode(url);
      final urlHash = base64Url.encode(urlBytes).replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
      final cachePath = '${directory.path}/pdf_cache';
      
      // 确保缓存目录存在
      final cacheDir = Directory(cachePath);
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      return '$cachePath/$urlHash.encrypted';
    } catch (e) {
      debugPrint('Error generating file path: $e');
      rethrow;
    }
  }

  Future<File?> _getDecryptedTempFile(String encryptedPath) async {
    try {
      final encryptedFile = File(encryptedPath);
      if (!await encryptedFile.exists()) {
        return null;
      }

      final encryptedBytes = await encryptedFile.readAsBytes();
      final decryptedBytes = EncryptionUtil.decryptBytes(encryptedBytes);
      
      // 创建临时文件用于查看
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await tempFile.writeAsBytes(decryptedBytes);
      
      return tempFile;
    } catch (e) {
      debugPrint('Error decrypting file: $e');
      return null;
    }
  }

  Future<void> _initializePdf(String url) async {
    if (url.isEmpty) {
      debugPrint('Empty URL provided');
      return;
    }

    if (_currentUrl == url) {
      debugPrint('Same URL, skipping reinitialization');
      return;
    }

    try {
      final cleanUrl = url.trim();
      final localPath = await _getLocalFilePath(cleanUrl);
      debugPrint('Local path for PDF: $localPath');

      // 尝试从本地加密缓存加载
      if (await _isCacheValid(localPath)) {
        final decryptedFile = await _getDecryptedTempFile(localPath);
        if (decryptedFile != null) {
          debugPrint('Using cached encrypted PDF');
          if (mounted) {
            setState(() {
              _currentUrl = cleanUrl;
              _localFilePath = decryptedFile.path;
            });
          }
          return;
        }
      }

      // 从远程下载
      debugPrint('Downloading PDF from: $cleanUrl');
      final response = await http.get(Uri.parse(cleanUrl));
      
      if (!mounted) return;

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        // 加密文件内容
        final encryptedBytes = EncryptionUtil.encryptBytes(response.bodyBytes);
        
        // 保存加密文件
        final encryptedFile = File(localPath);
        await encryptedFile.writeAsBytes(encryptedBytes);
        
        // 创建解密的临时文件用于查看
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await tempFile.writeAsBytes(response.bodyBytes);

        if (mounted) {
          setState(() {
            _currentUrl = cleanUrl;
            _localFilePath = tempFile.path;
          });
        }
      } else {
        throw Exception('下载PDF失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in _initializePdf: $e');
      if (mounted) {
        _showError('PDF加载失败：${e.toString()}');
      }
    }
  }

  Future<bool> _isCacheValid(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize == 0) {
          debugPrint('Cache file exists but is empty');
          return false;
        }

        final lastModified = await file.lastModified();
        final now = DateTime.now();
        final isValid = now.difference(lastModified).inDays < 7;
        debugPrint('Cache ${isValid ? "valid" : "expired"} for: $filePath');
        return isValid;
      }
    } catch (e) {
      debugPrint('Error checking cache: $e');
    }
    return false;
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
