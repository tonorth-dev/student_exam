import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import '../../../../theme/theme_util.dart';
import '../../../../common/encr_util.dart';
import '../../../../component/watermark.dart';
import '../../../../common/app_providers.dart';
import 'logic.dart';
import 'package:path/path.dart' as p;

class PdfPreView extends StatefulWidget {
  final String title;

  const PdfPreView({Key? key, required this.title}) : super(key: key);

  @override
  _PdfPreViewState createState() => _PdfPreViewState();
}

class _PdfPreViewState extends State<PdfPreView> {
  final LectureLogic pdfLogic = Get.put(LectureLogic());
  late PdfViewerController _pdfController;
  final screenAdapter = AppProviders.instance.screenAdapter;
  String? _currentUrl;
  String? _localFilePath;
  String? _decryptedFilePath;
  int _lastPageNumber = 1;
  bool _isChangingPage = false;
  bool _isPdfLoaded = false;
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
      if (url != null) {
        await _initializePdf(url);
      }
    });
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

  void _handlePdfPageChanged(PdfPageChangedDetails details) {
    if (!mounted || _isChangingPage || !_isPdfLoaded) return;

    try {
      final currentPage = details.newPageNumber;
      final totalPages = _pdfController.pageCount;

      if (totalPages == 0) return;

      // 检测滚动方向
      final isScrollingDown = currentPage > _lastPageNumber;
      final isScrollingUp = currentPage < _lastPageNumber;

      // 检测是否在最后一页并且是向下滚动
      if (currentPage == totalPages && isScrollingDown) {
        // 获取下一个章节的节点信息
        final nextNode = pdfLogic.getNextNode();
        final isNextNodeValid = nextNode?.filePath != null &&
            nextNode!.filePath!.isNotEmpty &&
            nextNode.children.isEmpty;

        if (isNextNodeValid) {
          setState(() {
            _isChangingPage = true;
          });
          pdfLogic.moveToNextChapter();
          if (mounted) {
            setState(() {
              _isChangingPage = false;
            });
          }
        }
      }
      // 检测是否在第一页并且是向上滚动
      else if (currentPage <= 2 && isScrollingUp) {
        // 获取上一个章节的节点信息
        final previousNode = pdfLogic.getPreviousNode();
        final isPreviousNodeValid = previousNode?.filePath != null &&
            previousNode!.filePath!.isNotEmpty &&
            previousNode.children.isEmpty;

        if (isPreviousNodeValid) {
          setState(() {
            _isChangingPage = true;
          });
          pdfLogic.moveToPreviousChapter();
          if (mounted) {
            setState(() {
              _isChangingPage = false;
            });
          }
        }
      }

      _lastPageNumber = currentPage;
    } catch (e) {
      debugPrint('Error handling page change: $e');
    }
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    if (!mounted) return;
    setState(() {
      _isPdfLoaded = true;
      _lastPageNumber = 1;
      _isChangingPage = false;
    });
  }

  @override
  void dispose() {
    _isPdfLoaded = false;
    _isChangingPage = false;
    _pdfController.dispose();
    // 清理临时文件
    if (_localFilePath != null) {
      final tempFile = File(_localFilePath!);
      tempFile.delete().catchError((e) => debugPrint('Error deleting temp file: $e'));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 无需重复计算屏幕尺寸，直接使用全局的 screenAdapter
    return Column(
      children: [
        ThemeUtil.height(),
        Expanded(
          child: Obx(() {
            final selectedPdfUrl = pdfLogic.selectedPdfUrl.value;
            if (selectedPdfUrl == null || selectedPdfUrl.isEmpty) {
              return Container(
                padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16.0)),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                ),
                child: Center(
                  child: Text(
                    "请点击要学习的章节",
                    style: TextStyle(
                      fontSize: screenAdapter.getAdaptiveFontSize(16.0),
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            if (_localFilePath == null || !_localFilePath!.isNotEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return FutureBuilder<bool>(
              future: Future.wait([
                File(_localFilePath!).exists(),
                Future.delayed(const Duration(milliseconds: 100)),
              ]).then((results) => results[0]),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildPdfContent(),
                    ),
                  ],
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPdfContent() {
    return Obx(() {
      final selectedPdfUrl = pdfLogic.selectedPdfUrl.value;

      if (selectedPdfUrl == null || selectedPdfUrl.isEmpty) {
        return Container(
          padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16.0)),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
          ),
          child: Center(
            child: Text(
              "请点击要学习的章节",
              style: TextStyle(
                fontSize: screenAdapter.getAdaptiveFontSize(16.0),
                color: Colors.red.shade700,
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
              SizedBox(height: screenAdapter.getAdaptiveHeight(16.0)),
              Text(
                '正在加载 PDF (${(_loadingProgress.value * 100).toInt()}%)',
                style: TextStyle(
                  fontSize: screenAdapter.getAdaptiveFontSize(14.0),
                ),
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
            onPageChanged: _handlePdfPageChanged,
            onDocumentLoaded: _onDocumentLoaded,
            scrollDirection: PdfScrollDirection.vertical,
            pageSpacing: 0,
            enableDoubleTapZooming: true,
            canShowScrollHead: true,
          ),
          const IgnorePointer(
            child: WatermarkWidget(),
          ),
          _buildZoomControls(),
        ],
      );
    });
  }

  Widget _buildZoomControls() {
    if (_localFilePath == null || !File(_localFilePath!).existsSync()) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: screenAdapter.getAdaptivePadding(16.0),
      bottom: screenAdapter.getAdaptivePadding(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(screenAdapter.getAdaptiveWidth(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: screenAdapter.getAdaptiveWidth(4),
                  offset: Offset(0, screenAdapter.getAdaptiveHeight(2)),
                ),
              ],
            ),
            child: Column(
              children: [
                IconButton(
                  icon: Obx(() => Icon(
                    isFullScreen.value ? Icons.fullscreen_exit : Icons.fullscreen,
                    size: screenAdapter.getAdaptiveIconSize(24),
                  )),
                  onPressed: () {
                    if (isFullScreen.value) {
                      isFullScreen.value = false;
                      Get.back();
                    } else {
                      isFullScreen.value = true;
                      Get.to(
                        () => Scaffold(
                          body: SafeArea(
                            child: _buildPdfContent(),
                          ),
                        ),
                        fullscreenDialog: true,
                        transition: Transition.fade,
                      );
                    }
                  },
                  tooltip: isFullScreen.value ? '退出全屏' : '全屏',
                  iconSize: screenAdapter.getAdaptiveIconSize(24),
                  padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(8)),
                ),
                Divider(height: screenAdapter.getAdaptiveHeight(1), thickness: 1),
                IconButton(
                  icon: Icon(Icons.add, size: screenAdapter.getAdaptiveIconSize(24)),
                  onPressed: _currentZoom.value < (1 + _zoomStep * _maxZoomClicks)
                      ? () => _handleZoom(true)
                      : null,
                  tooltip: '放大',
                  iconSize: screenAdapter.getAdaptiveIconSize(24),
                  padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(8)),
                ),
                Obx(() => Container(
                  padding: EdgeInsets.symmetric(
                    vertical: screenAdapter.getAdaptivePadding(4),
                  ),
                  child: Text(
                    '${(_currentZoom.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: screenAdapter.getAdaptiveFontSize(12),
                    ),
                  ),
                )),
                IconButton(
                  icon: Icon(Icons.remove, size: screenAdapter.getAdaptiveIconSize(24)),
                  onPressed: _currentZoom.value > 1.0
                      ? () => _handleZoom(false)
                      : null,
                  tooltip: '缩小',
                  iconSize: screenAdapter.getAdaptiveIconSize(24),
                  padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(8)),
                ),
              ],
            ),
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

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '错误',
          style: TextStyle(
            fontSize: screenAdapter.getAdaptiveFontSize(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SelectableText.rich(
          TextSpan(
            text: message,
            style: TextStyle(
              color: Colors.red,
              fontSize: screenAdapter.getAdaptiveFontSize(14),
            ),
          ),
        ),
        contentPadding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '确定',
              style: TextStyle(
                fontSize: screenAdapter.getAdaptiveFontSize(14),
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: screenAdapter.getAdaptivePadding(16),
                vertical: screenAdapter.getAdaptivePadding(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
