import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:bot_toast/bot_toast.dart';
import '../../models/version_info.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatefulWidget {
  final VersionInfo versionInfo;

  const UpdateDialog({
    Key? key,
    required this.versionInfo,
  }) : super(key: key);

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _downloadFailed = false;
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  Future<void> _downloadAndInstall() async {
    if (Platform.isMacOS) {
      // 在 macOS 上，直接使用浏览器下载
      final url = Uri.parse(widget.versionInfo.downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        if (mounted) {
          BotToast.showText(text: '已在浏览器中打开下载链接，请完成下载后安装');
          await Future.delayed(const Duration(seconds: 2));
          exit(0);
        }
      } else {
        BotToast.showText(text: '无法打开下载链接');
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadFailed = false;
      _downloadProgress = 0.0;
    });

    _cancelToken = CancelToken();
    String? savePath;

    try {
      // 验证下载URL
      final uri = Uri.tryParse(widget.versionInfo.downloadUrl);
      if (uri == null || !uri.isAbsolute) {
        throw Exception('无效的下载链接');
      }

      // 获取临时目录用于 Windows
      final tempDir = await getTemporaryDirectory();
      final fileName = path.basename(Uri.decodeFull(uri.path));
      savePath = path.join(tempDir.path, fileName);

      // 开始下载
      final response = await _dio.download(
        widget.versionInfo.downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
          followRedirects: true,
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 30),
          headers: {
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br',
          },
        ),
      );

      // 检查响应状态码
      if (response.statusCode != 200) {
        throw Exception('服务器返回错误: ${response.statusCode}');
      }

      // 验证下载的文件
      final file = File(savePath);
      if (!await file.exists()) {
        throw Exception('下载文件不存在');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('下载文件大小为0');
      }

      // Windows 平台直接运行安装程序
      if (Platform.isWindows) {
        await Process.run(savePath, []);
      }

      if (mounted) {
        BotToast.showText(text: '下载完成，请按照提示完成安装');
        await Future.delayed(const Duration(seconds: 2));
        exit(0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadFailed = true;
        _isDownloading = false;
      });
      
      String errorMessage;
      if (e.toString().contains('Cannot create file')) {
        errorMessage = '下载失败：无法创建文件';
      } else if (e.toString().contains('404')) {
        errorMessage = '下载失败：文件不存在';
      } else if (e.toString().contains('403')) {
        errorMessage = '下载失败：没有访问权限';
      } else if (e.toString().contains('timeout')) {
        errorMessage = '下载失败：连接超时';
      } else {
        errorMessage = '下载失败：${e.toString()}';
      }
      
      BotToast.showText(text: errorMessage);
      debugPrint('下载失败: $e');

      // 清理失败的下载文件
      if (savePath != null) {
        try {
          final file = File(savePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('清理失败的下载文件失败: $e');
        }
      }
    }
  }

  void _exitApp() {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.system_update,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                '发现新版本 ${widget.versionInfo.version}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '为了确保软件的稳定性和功能完整性，请更新到最新版本。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (_isDownloading) ...[
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 16),
                Text('正在下载 ${(_downloadProgress * 100).toInt()}%'),
              ],
              if (_downloadFailed)
                const Text(
                  '下载失败，请检查网络连接后重试',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!_isDownloading) ...[
                    TextButton(
                      onPressed: _exitApp,
                      child: Text(_downloadFailed ? '暂不更新' : '退出'),
                    ),
                    ElevatedButton(
                      onPressed: _downloadAndInstall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(_downloadFailed ? '重试' : '立即更新'),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () {
                        _cancelToken?.cancel('用户取消下载');
                        setState(() {
                          _isDownloading = false;
                          _downloadProgress = 0.0;
                        });
                      },
                      child: const Text('取消下载'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Dialog disposed');
    _dio.close();
    super.dispose();
  }
}
