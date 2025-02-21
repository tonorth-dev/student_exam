import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import '../../../../theme/theme_util.dart';
import 'logic.dart';

class PdfPreView extends StatefulWidget {
  final String title;

  const PdfPreView({Key? key, required this.title}) : super(key: key);

  @override
  _PdfPreViewState createState() => _PdfPreViewState();
}

class _PdfPreViewState extends State<PdfPreView> {
  final LectureLogic pdfLogic = Get.put(LectureLogic());
  late PdfViewerController _pdfController;
  String? _currentUrl;
  String? _localFilePath;
  int _lastPageNumber = 1;
  bool _isChangingPage = false;
  bool _isPdfLoaded = false;
  double _currentZoom = 1.0;
  static const double _zoomStep = 0.1;
  static const int _maxZoomClicks = 8;
  static const double _minZoom = 0.5;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    pdfLogic.selectedPdfUrl.listen((url) async {
      if (url != null) {
        setState(() {
          _isPdfLoaded = false;
          _isChangingPage = false;
          _localFilePath = null; // 重置文件路径
        });
        await _initializePdf(url);
      }
    });
  }

  @override
  void dispose() {
    _isPdfLoaded = false;
    _isChangingPage = false;
    _pdfController.dispose();
    super.dispose();
  }

  Future<String> _getLocalFilePath(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = Uri.parse(url).pathSegments.last;
    final fileNameHash = fileName.hashCode.toString();
    return '${directory.path}/$fileNameHash.pdf';
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

    setState(() {
      _isPdfLoaded = false;
      _isChangingPage = false;
      _localFilePath = null;
    });

    debugPrint('Initializing PDF with URL: $url');
    try {
      final localPath = await _getLocalFilePath(url);
      final file = File(localPath);

      if (await _isCacheValid(localPath)) {
        debugPrint('Using cached PDF at: $localPath');
        if (!mounted) return;

        setState(() {
          _currentUrl = url;
          _localFilePath = localPath;
          _lastPageNumber = 1;
        });
      } else {
        debugPrint('Downloading PDF from remote URL.');
        final response = await http.get(Uri.parse(url));
        if (!mounted) return;

        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('PDF cached at: $localPath');

          setState(() {
            _currentUrl = url;
            _localFilePath = localPath;
            _lastPageNumber = 1;
          });
        } else {
          throw Exception('下载PDF失败：状态码 ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error initializing PDF: $e');
      if (mounted) {
        _showError('PDF加载失败：${e.toString()}');
      }
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

  Widget _buildPdfViewer(String filePath) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: SfPdfViewer.file(
            File(filePath),
            key: ValueKey(filePath),
            controller: _pdfController,
            onPageChanged: _handlePdfPageChanged,
            onDocumentLoaded: _onDocumentLoaded,
            scrollDirection: PdfScrollDirection.vertical,
            pageSpacing: 0,
            enableDoubleTapZooming: true,
            canShowScrollHead: true,
            enableTextSelection: false,
            enableDocumentLinkAnnotation: false,
            initialZoomLevel: 1.0,
          ),
        );
      },
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
                  onPressed: _currentZoom > 1.0
                      ? () {
                          setState(() {
                            _currentZoom = (_currentZoom - _zoomStep)
                                .clamp(1.0, 1 + _zoomStep * _maxZoomClicks);
                            _pdfController.zoomLevel = _currentZoom;
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
    return Column(
      children: [
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
                    "请点击要学习的章节",
                    style: TextStyle(
                      fontSize: 16.0,
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
                      child: _buildPdfViewer(_localFilePath!),
                    ),
                    _buildZoomControls(),
                  ],
                );
              },
            );
          }),
        ),
      ],
    );
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
}
