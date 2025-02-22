import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;  // 引入 path 包

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
  late PdfViewerController _pdfController;
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
    _pdfController.dispose();
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
            final modifiedTime = stat.modified;

            // 检查文件创建时间或修改时间是否在指定范围内
            final isInRange = (time) => time.isAfter(startDate) &&
                time.isBefore(endDate.add(const Duration(days: 1)));

            if (isInRange(createTime) || isInRange(modifiedTime)) {
              try {
                await entity.delete();
                debugPrint('Deleted PDF: ${entity.path}');  // 删除文件成功日志
              } catch (deleteError) {
                debugPrint('Error deleting file ${entity.path}: $deleteError');  // 删除文件失败日志
              }
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
      // 获取应用文档目录，适用于 Windows 和 macOS
      final directory = await getApplicationDocumentsDirectory();
      // 使用 path.join 拼接路径，确保跨平台兼容
      final cachePath = p.join(directory.path, 'pdf_cache');
      final cacheDir = Directory(cachePath);

      // 检查目录是否存在，如果不存在则尝试创建
      if (!await cacheDir.exists()) {
        try {
          await cacheDir.create(recursive: true);
          debugPrint('缓存目录已创建: $cachePath');
        } catch (e) {
          debugPrint('创建缓存目录失败: $e');
          // 如果创建失败，继续执行，避免程序崩溃
        }
      }

      // 生成唯一的文件名，避免路径中的非法字符
      final urlBytes = utf8.encode(url);
      final urlHash = base64Url.encode(urlBytes).replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
      return p.join(cachePath, '$urlHash.encrypted');
    } catch (e) {
      debugPrint('生成文件路径时出错: $e');
      rethrow; // 让调用者处理异常
    }
  }

  Future<File?> _getDecryptedTempFile(String encryptedPath) async {
    try {
      final encryptedFile = File(encryptedPath);
      if (!await encryptedFile.exists()) {
        debugPrint('Encrypted file does not exist: $encryptedPath');
        return null;
      }

      final encryptedBytes = await encryptedFile.readAsBytes();
      final decryptedBytes = EncryptionUtil.decryptBytes(encryptedBytes);

      // 创建临时文件用于查看
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.pdf'));
      await tempFile.writeAsBytes(decryptedBytes);

      return tempFile;
    } catch (e) {
      debugPrint('解密文件时出错: $e');
      return null;
    }
  }

  Future<void> _initializePdf(String url) async {
    if (url.isEmpty || _currentUrl == url) return;

    try {
      // 重置缩放状态
      setState(() {
        _currentZoom = 1.0;
        _pdfController.zoomLevel = 1.0;
      });

      final cleanUrl = url.trim();
      String? localPath;
      try {
        localPath = await _getLocalFilePath(cleanUrl);
      } catch (e) {
        debugPrint('获取本地文件路径失败: $e');
      }

      File? decryptedFile;
      if (localPath != null) {
        try {
          // 检查缓存是否有效
          if (await _isCacheValid(localPath)) {
            decryptedFile = await _getDecryptedTempFile(localPath);
          }
        } catch (e) {
          debugPrint('检查或解密本地文件时出错: $e');
        }
      }

      // 如果本地文件有效，则使用本地文件
      if (decryptedFile != null && await decryptedFile.exists()) {
        if (mounted) {
          setState(() {
            _currentUrl = cleanUrl;
            _localFilePath = decryptedFile?.path;
          });
        }
      } else {
        // 本地文件不可用或无效，下载远程文件
        await _downloadAndSetPdf(cleanUrl, localPath);
      }
    } catch (e) {
      debugPrint('初始化 PDF 时出错: $e');
      if (mounted) _showError('PDF 加载失败：${e.toString()}');
    }
  }

  Future<void> _downloadAndSetPdf(String url, String? localPath) async {
    debugPrint('从远程下载 PDF: $url');
    final response = await http.get(Uri.parse(url));
    if (!mounted) return;

    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      // 如果提供了 localPath，尝试保存加密文件
      if (localPath != null) {
        try {
          final encryptedBytes = EncryptionUtil.encryptBytes(response.bodyBytes);
          final encryptedFile = File(localPath);
          // 确保目录存在
          await encryptedFile.parent.create(recursive: true);
          await encryptedFile.writeAsBytes(encryptedBytes);
        } catch (e) {
          debugPrint('保存加密文件失败: $e');
        }
      }

      // 创建临时文件用于显示
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'temp_${DateTime.now().millisecondsSinceEpoch}.pdf'));
      await tempFile.writeAsBytes(response.bodyBytes);

      if (mounted) {
        setState(() {
          _currentUrl = url;
          _localFilePath = tempFile.path;
        });
      }
    } else {
      throw Exception('下载 PDF 失败: HTTP ${response.statusCode}');
    }
  }

  Future<bool> _isCacheValid(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        if (fileSize == 0) return false;
        final lastModified = await file.lastModified();
        final now = DateTime.now();
        final isValid = now.difference(lastModified).inDays < 7;
        return isValid;
      }
    } catch (e) {
      debugPrint('检查缓存时出错: $e');
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
    // 确保在PDF加载完成后才显示缩放控制
    if (_localFilePath == null || !File(_localFilePath!).existsSync()) {
      return const SizedBox.shrink();
    }

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
                          .clamp(_minZoom, 1 + _zoomStep * _maxZoomClicks);
                      _pdfController.zoomLevel = _currentZoom;
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
                  onPressed: _currentZoom > _minZoom
                      ? () {
                    setState(() {
                      _currentZoom = (_currentZoom - _zoomStep)
                          .clamp(_minZoom, 1 + _zoomStep * _maxZoomClicks);
                      _pdfController.zoomLevel = _currentZoom;
                    });
                  }
                      : null,
                  tooltip: '缩小',
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

                  if (_localFilePath == null || !File(_localFilePath!).existsSync()) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return Stack(
                    children: [
                      SfPdfViewer.file(
                        File(_localFilePath!),
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