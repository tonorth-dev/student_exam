import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../../../../theme/theme_util.dart';
import '../../../../common/encr_util.dart';
import '../../../../common/app_providers.dart';
import 'logic.dart';

/// PDF 预览组件
class PdfPreView extends StatefulWidget {
  final String title;

  const PdfPreView({super.key, required this.title});

  @override
  State<PdfPreView> createState() => _PdfPreViewState();
}

class _PdfPreViewState extends State<PdfPreView> {
  // 依赖和控制器
  final LectureLogic _lectureLogic = Get.put(LectureLogic());
  final _screenAdapter = AppProviders.instance.screenAdapter;
  late final PdfViewerController _pdfController;

  // PDF 状态
  String? _currentUrl;
  String? _decryptedFilePath;
  bool _isPdfLoaded = false;
  int _lastPageNumber = 1;
  bool _isChangingPage = false;

  // 缩放状态
  final RxDouble _zoomLevel = 1.0.obs;
  static const double _minZoom = 1.0;  // 最小 100%
  static const double _maxZoom = 2.0;  // 最大 200%

  // 加载状态
  final RxBool _isLoading = false.obs;
  final RxDouble _loadingProgress = 0.0.obs;

  // 全屏状态
  final RxBool _isFullScreen = false.obs;

  // 记录每个PDF的阅读进度（URL -> 页码）
  final Map<String, int> _readingProgress = {};

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();

    // 监听 PDF URL 变化
    _lectureLogic.selectedPdfUrl.listen((url) async {
      if (url != null && mounted) {
        // 切换PDF时，保存当前页码
        if (_currentUrl != null && _isPdfLoaded) {
          _readingProgress[_currentUrl!] = _pdfController.pageNumber;
        }
        // 重置缩放为100%
        _zoomLevel.value = 1.0;
        await _loadPdf(url);
      }
    });
  }

  @override
  void dispose() {
    // 保存当前阅读进度
    if (_currentUrl != null && _isPdfLoaded) {
      _readingProgress[_currentUrl!] = _pdfController.pageNumber;
    }
    _pdfController.dispose();
    _cleanupTempFiles();
    super.dispose();
  }

  /// 清理临时文件
  void _cleanupTempFiles() {
    if (_decryptedFilePath != null) {
      File(_decryptedFilePath!).delete().catchError((e) {
        debugPrint('清理临时文件失败: $e');
        return File(_decryptedFilePath!);
      });
    }
  }

  // ========== PDF 加载相关 ==========

  /// 加载 PDF
  Future<void> _loadPdf(String url) async {
    if (url.isEmpty || _currentUrl == url) return;

    try {
      _isLoading.value = true;
      _loadingProgress.value = 0.0;
      _isPdfLoaded = false;

      final cleanUrl = url.trim();
      final decryptedPath = await _getDecryptedFilePath(cleanUrl);

      // 检查解密文件缓存
      if (await _isFileValid(decryptedPath)) {
        _updatePdfPath(cleanUrl, decryptedPath);
        return;
      }

      // 检查加密文件缓存
      final encryptedPath = await _getEncryptedFilePath(cleanUrl);
      if (await _isFileValid(encryptedPath)) {
        await _decryptFile(encryptedPath, decryptedPath);
        _updatePdfPath(cleanUrl, decryptedPath);
        return;
      }

      // 下载并处理新文件
      await _downloadAndDecryptFile(cleanUrl, encryptedPath, decryptedPath);
      _updatePdfPath(cleanUrl, decryptedPath);
    } catch (e) {
      debugPrint('加载 PDF 失败: $e');
      if (mounted) _showError('PDF 加载失败：$e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// 更新 PDF 路径
  void _updatePdfPath(String url, String path) {
    if (!mounted) return;
    setState(() {
      _currentUrl = url;
      _decryptedFilePath = path;
    });
  }

  /// 获取加密文件路径
  Future<String> _getEncryptedFilePath(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final cachePath = p.join(directory.path, 'pdf_cache');
    await Directory(cachePath).create(recursive: true);
    final urlHash = _generateUrlHash(url);
    return p.join(cachePath, '$urlHash.encrypted');
  }

  /// 获取解密文件路径
  Future<String> _getDecryptedFilePath(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final decryptedPath = p.join(directory.path, 'pdf_decrypted');
    await Directory(decryptedPath).create(recursive: true);
    final urlHash = _generateUrlHash(url);
    return p.join(decryptedPath, '$urlHash.pdf');
  }

  /// 生成 URL 哈希值
  String _generateUrlHash(String url) {
    final urlBytes = utf8.encode(url);
    return base64Url.encode(urlBytes).replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
  }

  /// 检查文件是否有效（存在且未过期）
  Future<bool> _isFileValid(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;
      if (await file.length() == 0) return false;

      final lastModified = await file.lastModified();
      final daysSinceModified = DateTime.now().difference(lastModified).inDays;
      return daysSinceModified < 7;
    } catch (e) {
      debugPrint('检查文件有效性失败: $e');
      return false;
    }
  }

  /// 解密文件
  Future<void> _decryptFile(String encryptedPath, String decryptedPath) async {
    final encryptedBytes = await File(encryptedPath).readAsBytes();
    final decryptedBytes = EncryptionUtil.decryptBytes(encryptedBytes);
    await File(decryptedPath).writeAsBytes(decryptedBytes);
  }

  /// 下载并解密文件
  Future<void> _downloadAndDecryptFile(
    String url,
    String encryptedPath,
    String decryptedPath,
  ) async {
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));

      if (response.statusCode != 200) {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;
      final bytes = <int>[];

      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        _loadingProgress.value = totalBytes > 0 ? receivedBytes / totalBytes : 0;
      }

      if (bytes.isEmpty) throw Exception('下载的文件为空');

      // 保存加密和解密文件
      final originalBytes = Uint8List.fromList(bytes);
      await File(encryptedPath).writeAsBytes(
        EncryptionUtil.encryptBytes(originalBytes),
      );
      await File(decryptedPath).writeAsBytes(originalBytes);
    } finally {
      client.close();
    }
  }

  // ========== PDF 交互相关 ==========

  /// PDF 文档加载完成
  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    if (!mounted) return;
    setState(() {
      _isPdfLoaded = true;
      _isChangingPage = false;
    });

    // 恢复阅读进度
    if (_currentUrl != null && _readingProgress.containsKey(_currentUrl!)) {
      final savedPage = _readingProgress[_currentUrl!]!;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _isPdfLoaded) {
          _pdfController.jumpToPage(savedPage);
          _lastPageNumber = savedPage;
        }
      });
    } else {
      _lastPageNumber = 1;
    }
  }

  /// PDF 页面变化
  void _onPageChanged(PdfPageChangedDetails details) {
    if (!mounted || _isChangingPage || !_isPdfLoaded) return;

    final currentPage = details.newPageNumber;
    final totalPages = _pdfController.pageCount;
    if (totalPages == 0) return;

    final isScrollingDown = currentPage > _lastPageNumber;
    final isScrollingUp = currentPage < _lastPageNumber;

    // 滚动到最后一页时切换到下一章
    if (currentPage == totalPages && isScrollingDown) {
      _tryNavigateToNextChapter();
    }
    // 滚动到第一页时切换到上一章
    else if (currentPage <= 2 && isScrollingUp) {
      _tryNavigateToPreviousChapter();
    }

    _lastPageNumber = currentPage;
  }

  /// 尝试导航到下一章
  void _tryNavigateToNextChapter() {
    final nextNode = _lectureLogic.getNextNode();
    if (_isNodeValid(nextNode)) {
      setState(() => _isChangingPage = true);
      _lectureLogic.moveToNextChapter();
      if (mounted) setState(() => _isChangingPage = false);
    }
  }

  /// 尝试导航到上一章
  void _tryNavigateToPreviousChapter() {
    final previousNode = _lectureLogic.getPreviousNode();
    if (_isNodeValid(previousNode)) {
      setState(() => _isChangingPage = true);
      _lectureLogic.moveToPreviousChapter();
      if (mounted) setState(() => _isChangingPage = false);
    }
  }

  /// 检查节点是否有效
  bool _isNodeValid(dynamic node) {
    return node?.filePath != null &&
        node.filePath!.isNotEmpty &&
        node.children.isEmpty;
  }

  // ========== 缩放控制 ==========

  /// 处理缩放（使用 Transform.scale 自动从中心缩放）
  void _handleZoom(bool zoomIn) {
    if (!mounted || !_isPdfLoaded) return;

    double newZoom = _zoomLevel.value;

    if (zoomIn) {
      newZoom = (newZoom + 0.1).clamp(_minZoom, _maxZoom);
    } else {
      newZoom = (newZoom - 0.1).clamp(_minZoom, _maxZoom);
    }

    _zoomLevel.value = newZoom;
  }

  /// 重置缩放
  void _resetZoom() {
    if (!mounted || !_isPdfLoaded) return;
    _zoomLevel.value = 1.0;
  }

  // ========== 全屏控制 ==========

  /// 切换全屏
  void _toggleFullScreen() {
    if (!mounted || !_isPdfLoaded) return;

    if (_isFullScreen.value) {
      _isFullScreen.value = false;
      Get.back();
    } else {
      _isFullScreen.value = true;

      // 保存当前页码和缩放
      final currentPage = _pdfController.pageNumber;
      final currentZoom = _zoomLevel.value;

      Get.to(
        () => _PdfFullScreenPage(
          filePath: _decryptedFilePath!,
          initialPage: currentPage,
          initialZoom: currentZoom,
          onPageChanged: (page) {
            // 更新主页面的页码（当用户在全屏模式翻页时）
            if (mounted) {
              _lastPageNumber = page;
            }
          },
          onExit: (exitPage, exitZoom) {
            _isFullScreen.value = false;
            // 退出全屏时，跳转到全屏页面的当前页码
            if (mounted && exitPage != currentPage) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _pdfController.jumpToPage(exitPage);
                }
              });
            }
            // 恢复缩放
            _zoomLevel.value = exitZoom;
          },
        ),
        fullscreenDialog: true,
        transition: Transition.fade,
      );
    }
  }

  // ========== UI 构建 ==========

  @override
  Widget build(BuildContext context) {
    return _buildMainContent();
  }

  /// 构建主内容
  Widget _buildMainContent() {
    return Row(
      children: [
        SizedBox(width: _screenAdapter.getAdaptiveWidth(25)),
        Expanded(
          child: Column(
            children: [
              SizedBox(height: _screenAdapter.getAdaptiveHeight(8)),
              ThemeUtil.lineH(),
              ThemeUtil.height(),
              Expanded(child: _buildPdfContent()),
              SizedBox(height: _screenAdapter.getAdaptiveHeight(10)),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建 PDF 内容
  Widget _buildPdfContent() {
    return Obx(() {
      final selectedUrl = _lectureLogic.selectedPdfUrl.value;

      // 未选择文件
      if (selectedUrl == null || selectedUrl.isEmpty) {
        return _buildEmptyState();
      }

      // 加载中
      if (_isLoading.value) {
        return _buildLoadingState();
      }

      // 文件不存在
      if (_decryptedFilePath == null || !File(_decryptedFilePath!).existsSync()) {
        return _buildLoadingState();
      }

      return _buildPdfViewer();
    });
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(_screenAdapter.getAdaptivePadding(16.0)),
      decoration: const BoxDecoration(color: Colors.white),
      child: Center(
        child: Text(
          "请选择一个文件",
          style: TextStyle(
            fontSize: _screenAdapter.getAdaptiveFontSize(16.0),
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 构建加载状态
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: _loadingProgress.value > 0 ? _loadingProgress.value : null,
            strokeWidth: _screenAdapter.getAdaptiveWidth(2.0),
          ),
          SizedBox(height: _screenAdapter.getAdaptiveHeight(16)),
          Text(
            '正在加载 PDF (${(_loadingProgress.value * 100).toInt()}%)',
            style: TextStyle(fontSize: _screenAdapter.getAdaptiveFontSize(14)),
          ),
        ],
      ),
    );
  }

  /// 构建 PDF 查看器
  Widget _buildPdfViewer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 紫色背景图片（底层）
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/note_page_bg.png'),
              fit: BoxFit.fill,
            ),
          ),
        ),

        // 添加内边距，确保紫色背景始终可见
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _screenAdapter.getAdaptivePadding(16),
            vertical: _screenAdapter.getAdaptivePadding(8),
          ),
          child: ClipRect(
            child: Obx(() => Transform.scale(
              scale: _zoomLevel.value,
              alignment: Alignment.center,
              child: SfPdfViewer.file(
                key: ValueKey('pdf_$_currentUrl'),
                File(_decryptedFilePath!),
                controller: _pdfController,
                enableTextSelection: false,
                enableDocumentLinkAnnotation: false,
                pageLayoutMode: PdfPageLayoutMode.single,
                scrollDirection: PdfScrollDirection.vertical,
                pageSpacing: 0,
                enableDoubleTapZooming: false,
                canShowScrollHead: true,
                onDocumentLoadFailed: (details) {
                  debugPrint('PDF 加载失败: ${details.error}');
                  final url = _lectureLogic.selectedPdfUrl.value;
                  if (url != null) _loadPdf(url);
                },
                onPageChanged: _onPageChanged,
                onDocumentLoaded: _onDocumentLoaded,
              ),
            )),
          ),
        ),

        // 控制按钮（最上层）
        _buildControls(),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControls() {
    if (_decryptedFilePath == null || !File(_decryptedFilePath!).existsSync()) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: _screenAdapter.getAdaptivePadding(16),
      bottom: _screenAdapter.getAdaptivePadding(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(_screenAdapter.getAdaptivePadding(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: _screenAdapter.getAdaptivePadding(8),
              offset: Offset(0, _screenAdapter.getAdaptiveHeight(2)),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 全屏按钮
            _buildControlButton(
              icon: Obx(() => Icon(
                _isFullScreen.value ? Icons.fullscreen_exit : Icons.fullscreen,
                size: _screenAdapter.getAdaptiveIconSize(24),
              )),
              onPressed: _toggleFullScreen,
              tooltip: _isFullScreen.value ? '退出全屏' : '全屏',
            ),

            _buildDivider(),

            // 放大按钮
            Obx(() => _buildControlButton(
              icon: Icon(Icons.add, size: _screenAdapter.getAdaptiveIconSize(24)),
              onPressed: _zoomLevel.value < _maxZoom ? () => _handleZoom(true) : null,
              tooltip: '放大 (最大 200%)',
            )),

            // 缩放比例显示
            Obx(() => Padding(
              padding: EdgeInsets.symmetric(
                vertical: _screenAdapter.getAdaptivePadding(4),
              ),
              child: Text(
                '${(_zoomLevel.value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: _screenAdapter.getAdaptiveFontSize(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),

            // 缩小按钮
            Obx(() => _buildControlButton(
              icon: Icon(Icons.remove, size: _screenAdapter.getAdaptiveIconSize(24)),
              onPressed: _zoomLevel.value > _minZoom ? () => _handleZoom(false) : null,
              tooltip: '缩小 (最小 100%)',
            )),

            _buildDivider(),

            // 重置按钮
            _buildControlButton(
              icon: Icon(Icons.refresh, size: _screenAdapter.getAdaptiveIconSize(24)),
              onPressed: _resetZoom,
              tooltip: '重置缩放',
            ),
          ],
        ),
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required Widget icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: _screenAdapter.getAdaptiveIconSize(24),
      padding: EdgeInsets.all(_screenAdapter.getAdaptivePadding(8)),
    );
  }

  /// 构建分割线
  Widget _buildDivider() {
    return Divider(
      height: _screenAdapter.getAdaptiveHeight(1),
      thickness: 1,
    );
  }

  /// 显示错误提示
  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '错误',
          style: TextStyle(
            fontSize: _screenAdapter.getAdaptiveFontSize(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SelectableText(
          message,
          style: TextStyle(
            color: Colors.red,
            fontSize: _screenAdapter.getAdaptiveFontSize(14),
          ),
        ),
        contentPadding: EdgeInsets.all(_screenAdapter.getAdaptivePadding(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: _screenAdapter.getAdaptivePadding(16),
                vertical: _screenAdapter.getAdaptivePadding(8),
              ),
            ),
            child: Text(
              '确定',
              style: TextStyle(fontSize: _screenAdapter.getAdaptiveFontSize(14)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 全屏 PDF 查看页面
class _PdfFullScreenPage extends StatefulWidget {
  final String filePath;
  final int initialPage;
  final double initialZoom;
  final Function(int page) onPageChanged;
  final Function(int exitPage, double exitZoom) onExit;

  const _PdfFullScreenPage({
    required this.filePath,
    required this.initialPage,
    required this.initialZoom,
    required this.onPageChanged,
    required this.onExit,
  });

  @override
  State<_PdfFullScreenPage> createState() => _PdfFullScreenPageState();
}

class _PdfFullScreenPageState extends State<_PdfFullScreenPage> {
  final _screenAdapter = AppProviders.instance.screenAdapter;
  late final PdfViewerController _controller;
  final RxDouble _zoomLevel = 1.0.obs;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _zoomLevel.value = widget.initialZoom;
    _currentPage = widget.initialPage;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    // 跳转到初始页码
    if (widget.initialPage > 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _controller.jumpToPage(widget.initialPage);
        }
      });
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    _currentPage = details.newPageNumber;
    widget.onPageChanged(_currentPage);
  }

  void _exitFullScreen() {
    widget.onExit(_currentPage, _zoomLevel.value);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _exitFullScreen();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // PDF 查看器
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.98,
                  maxHeight: MediaQuery.of(context).size.height * 0.98,
                ),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/note_page_bg.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(_screenAdapter.getAdaptivePadding(16)),
                  child: ClipRect(
                    child: Obx(() => Transform.scale(
                      scale: _zoomLevel.value,
                      alignment: Alignment.center,
                      child: SfPdfViewer.file(
                        File(widget.filePath),
                        controller: _controller,
                        enableTextSelection: false,
                        enableDocumentLinkAnnotation: false,
                        pageLayoutMode: PdfPageLayoutMode.single,
                        scrollDirection: PdfScrollDirection.vertical,
                        pageSpacing: 0,
                        enableDoubleTapZooming: false,
                        canShowScrollHead: true,
                        onPageChanged: _onPageChanged,
                        onDocumentLoaded: _onDocumentLoaded,
                      ),
                    )),
                  ),
                ),
              ),
            ),

            // 控制按钮
            Positioned(
              top: 40,
              right: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 退出全屏按钮
                    IconButton(
                      icon: Icon(Icons.fullscreen_exit, size: 28),
                      onPressed: _exitFullScreen,
                      tooltip: '退出全屏',
                    ),

                    Divider(height: 1),

                    // 放大按钮
                    Obx(() => IconButton(
                      icon: Icon(Icons.add, size: 28),
                      onPressed: _zoomLevel.value < 2.0
                          ? () => _zoomLevel.value = (_zoomLevel.value + 0.1).clamp(1.0, 2.0)
                          : null,
                      tooltip: '放大',
                    )),

                    // 缩放显示
                    Obx(() => Text(
                      '${(_zoomLevel.value * 100).toInt()}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    )),

                    // 缩小按钮
                    Obx(() => IconButton(
                      icon: Icon(Icons.remove, size: 28),
                      onPressed: _zoomLevel.value > 1.0
                          ? () => _zoomLevel.value = (_zoomLevel.value - 0.1).clamp(1.0, 2.0)
                          : null,
                      tooltip: '缩小',
                    )),

                    Divider(height: 1),

                    // 重置缩放
                    IconButton(
                      icon: Icon(Icons.refresh, size: 28),
                      onPressed: () => _zoomLevel.value = 1.0,
                      tooltip: '重置缩放',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
