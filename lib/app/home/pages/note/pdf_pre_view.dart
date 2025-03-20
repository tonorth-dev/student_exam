import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;  // 引入 path 包

import '../../../../common/encr_util.dart';
import '../../../../component/table/ex.dart';
import '../../../../theme/theme_util.dart';
import '../../../../component/watermark.dart';
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
  String? _decryptedFilePath;
  final RxDouble _currentZoom = 1.0.obs;
  static const double _zoomStep = 0.1;
  static const int _maxZoomClicks = 8;
  static const double _minZoom = 0.5;
  final RxBool isFullScreen = false.obs;
  final RxBool _isLoading = false.obs;
  final RxDouble _loadingProgress = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    pdfLogic.selectedPdfUrl.listen((url) async {
      if (url != null && mounted) {
        await _initializePdf(url);
      }
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  Future<String> _getLocalFilePath(String url) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cachePath = p.join(directory.path, 'pdf_cache');
      final cacheDir = Directory(cachePath);

      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final urlBytes = utf8.encode(url);
      final urlHash = base64Url.encode(urlBytes).replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
      return p.join(cachePath, '$urlHash.encrypted');
    } catch (e) {
      debugPrint('生成文件路径时出错: $e');
      rethrow;
    }
  }

  Future<String> _getDecryptedFilePath(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final decryptedPath = p.join(directory.path, 'pdf_decrypted');
    final decryptedDir = Directory(decryptedPath);

    if (!await decryptedDir.exists()) {
      await decryptedDir.create(recursive: true);
    }

    final urlBytes = utf8.encode(url);
    final urlHash = base64Url.encode(urlBytes).replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
    return p.join(decryptedPath, '$urlHash.pdf');
  }

  Future<void> _initializePdf(String url) async {
    if (url.isEmpty || _currentUrl == url) return;

    try {
      _isLoading.value = true;
      _loadingProgress.value = 0.0;

      final cleanUrl = url.trim();
      String? localPath = await _getLocalFilePath(cleanUrl);
      String decryptedPath = await _getDecryptedFilePath(cleanUrl);

      // 检查解密后的文件是否存在且有效
      if (await _isDecryptedFileValid(decryptedPath)) {
        setState(() {
          _currentUrl = cleanUrl;
          _decryptedFilePath = decryptedPath;
          _localFilePath = decryptedPath;
        });
        _isLoading.value = false;
        return;
      }

      // 检查加密文件是否存在且有效
      if (await _isCacheValid(localPath)) {
        await _decryptFile(localPath, decryptedPath);
        setState(() {
          _currentUrl = cleanUrl;
          _decryptedFilePath = decryptedPath;
          _localFilePath = decryptedPath;
        });
        _isLoading.value = false;
        return;
      }

      // 下载并处理文件
      await _downloadAndProcessFile(cleanUrl, localPath, decryptedPath);
      
    } catch (e) {
      debugPrint('初始化 PDF 时出错: $e');
      _isLoading.value = false;
      if (mounted) _showError('PDF 加载失败：${e.toString()}');
    }
  }

  Future<bool> _isDecryptedFileValid(String filePath) async {
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
      debugPrint('检查解密文件时出错: $e');
    }
    return false;
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
      debugPrint('检查缓存文件时出错: $e');
    }
    return false;
  }

  Future<void> _decryptFile(String encryptedPath, String decryptedPath) async {
    try {
      final encryptedFile = File(encryptedPath);
      final encryptedBytes = await encryptedFile.readAsBytes();
      final decryptedBytes = EncryptionUtil.decryptBytes(encryptedBytes);
      
      final decryptedFile = File(decryptedPath);
      await decryptedFile.writeAsBytes(decryptedBytes);
    } catch (e) {
      debugPrint('解密文件时出错: $e');
      rethrow;
    }
  }

  Future<void> _downloadAndProcessFile(String url, String localPath, String decryptedPath) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      
      if (response.statusCode != 200) {
        throw Exception('下载 PDF 失败: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;
      final List<int> bytes = [];

      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        _loadingProgress.value = totalBytes > 0 ? receivedBytes / totalBytes : 0;
      }

      if (bytes.isEmpty) {
        throw Exception('下载的文件为空');
      }

      // 保存加密文件
      final encryptedBytes = EncryptionUtil.encryptBytes(Uint8List.fromList(bytes));
      await File(localPath).writeAsBytes(encryptedBytes);

      // 保存解密文件
      await File(decryptedPath).writeAsBytes(Uint8List.fromList(bytes));

      setState(() {
        _currentUrl = url;
        _decryptedFilePath = decryptedPath;
        _localFilePath = decryptedPath;
      });

    } finally {
      client.close();
      _isLoading.value = false;
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

  void _handleZoom(bool zoomIn) {
    if (!mounted) return;
    
    double newZoom = _currentZoom.value;
    if (zoomIn) {
      if (newZoom < (1 + _zoomStep * _maxZoomClicks)) {
        newZoom += _zoomStep;
      }
    } else {
      if (newZoom > 1.0) {  // 修改这里，限制最小缩放为 1.0
        newZoom -= _zoomStep;
      }
    }
    
    // 直接更新缩放值和控制器
    _currentZoom.value = newZoom;
    _pdfController.zoomLevel = newZoom;
  }

  Widget _buildZoomControls() {
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
                // 全屏按钮
                IconButton(
                  icon: Obx(() => Icon(isFullScreen.value ? Icons.fullscreen_exit : Icons.fullscreen)),
                  onPressed: () {
                    if (isFullScreen.value) {
                      isFullScreen.value = false;
                      Get.back();
                    } else {
                      isFullScreen.value = true;
                      Get.to(
                        () => Stack(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 25),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 8),
                                      ThemeUtil.lineH(),
                                      ThemeUtil.height(),
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: const BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage('assets/images/note_page_bg.png'),
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                            ),
                                            _buildPdfContent(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const IgnorePointer(
                              child: WatermarkWidget(),
                            ),
                          ],
                        ),
                        fullscreenDialog: true,
                        transition: Transition.fade,
                      );
                    }
                  },
                  tooltip: isFullScreen.value ? '退出全屏' : '全屏',
                ),
                const Divider(height: 1),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _currentZoom.value < (1 + _zoomStep * _maxZoomClicks)
                      ? () => _handleZoom(true)
                      : null,
                  tooltip: '放大',
                ),
                Obx(() => Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${(_currentZoom.value * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _currentZoom.value > 1.0
                      ? () => _handleZoom(false)
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
                child: _buildPdfContent(),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPdfContent() {
    return Obx(() {
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

      if (_isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: _loadingProgress.value > 0 ? _loadingProgress.value : null,
              ),
              const SizedBox(height: 16),
              Text(
                '正在加载 PDF (${(_loadingProgress.value * 100).toInt()}%)',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      }

      if (_localFilePath == null || !File(_localFilePath!).existsSync()) {
        return const Center(child: CircularProgressIndicator());
      }

      return Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/note_page_bg.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          SfPdfViewer.file(
            File(_localFilePath!),
            controller: _pdfController,
            enableTextSelection: false,
            enableDocumentLinkAnnotation: false,
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              debugPrint('PDF load failed: ${details.error}');
              _initializePdf(selectedPdfUrl);
            },
          ),
          // const IgnorePointer(
          //   child: WatermarkWidget(),
          // ),
          _buildZoomControls(),
        ],
      );
    });
  }
}