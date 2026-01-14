import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../common/app_providers.dart';
import '../common/app_bar.dart';
import '../../head/logic.dart';
import 'logic.dart';

/// 用户手册页面
class UserGuidePage extends StatefulWidget {
  const UserGuidePage({super.key});

  @override
  State<UserGuidePage> createState() => _UserGuidePageState();
}

class _UserGuidePageState extends State<UserGuidePage> {
  final RxDouble loadingProgress = 0.0.obs;
  final RxBool isWebViewLoading = true.obs;

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(UserGuideLogic());
    final screenAdapter = AppProviders.instance.screenAdapter;
    // 确保HeadLogic已初始化
    Get.put(HeadLogic());

    return Scaffold(
      appBar: CommonAppBar.buildExamAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16)),
              child: Obx(() {
          if (logic.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (logic.errorMessage.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: screenAdapter.getAdaptiveIconSize(80),
                    color: Colors.red[400],
                  ),
                  SizedBox(height: screenAdapter.getAdaptiveHeight(16)),
                  Text(
                    logic.errorMessage.value,
                    style: TextStyle(
                      fontSize: screenAdapter.getAdaptiveFontSize(16),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
                  ElevatedButton.icon(
                    onPressed: () => logic.refresh(),
                    icon: Icon(Icons.refresh, size: screenAdapter.getAdaptiveIconSize(20)),
                    label: Text('重试', style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(16))),
                  ),
                ],
              ),
            );
          }

          if (logic.guideUrl.value.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: screenAdapter.getAdaptiveIconSize(80),
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: screenAdapter.getAdaptiveHeight(16)),
                  Text(
                    '用户手册链接为空',
                    style: TextStyle(
                      fontSize: screenAdapter.getAdaptiveFontSize(16),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: screenAdapter.getAdaptiveHeight(16)),
                  ElevatedButton.icon(
                    onPressed: () => logic.refresh(),
                    icon: Icon(Icons.refresh, size: screenAdapter.getAdaptiveIconSize(20)),
                    label: Text('重试', style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(16))),
                  ),
                ],
              ),
            );
          }

          debugPrint('准备加载用户手册URL: ${logic.guideUrl.value}');

          // 直接嵌入显示WebView
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: screenAdapter.getAdaptivePadding(10),
                  offset: Offset(0, screenAdapter.getAdaptiveHeight(2)),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(8)),
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(logic.guideUrl.value),
                    ),
                    initialSettings: InAppWebViewSettings(
                      useShouldOverrideUrlLoading: false,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback: true,
                      javaScriptEnabled: true,
                      useOnLoadResource: true,
                      transparentBackground: false,
                      supportZoom: true,
                      builtInZoomControls: true,
                    ),
                    onWebViewCreated: (controller) {
                      debugPrint('WebView created for URL: ${logic.guideUrl.value}');
                    },
                    onLoadStart: (controller, url) {
                      debugPrint('Page started loading: $url');
                      isWebViewLoading.value = true;
                    },
                    onLoadStop: (controller, url) async {
                      debugPrint('Page finished loading: $url');
                      isWebViewLoading.value = false;
                      loadingProgress.value = 100.0;
                    },
                    onReceivedError: (controller, request, error) {
                      debugPrint('WebView error: ${error.description}');
                      isWebViewLoading.value = false;
                    },
                    onProgressChanged: (controller, progress) {
                      loadingProgress.value = progress.toDouble();
                      debugPrint('Loading progress: $progress%');
                    },
                    onReceivedServerTrustAuthRequest: (controller, challenge) async {
                      debugPrint('收到SSL证书验证请求: ${challenge.protectionSpace.host}');
                      // 信任所有证书（仅用于开发环境，生产环境应该验证证书）
                      return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
                    },
                  ),
                  // 加载进度条
                  Obx(() {
                    if (isWebViewLoading.value && loadingProgress.value < 100) {
                      return Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: loadingProgress.value / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  // 加载提示
                  Obx(() {
                    if (isWebViewLoading.value && loadingProgress.value < 30) {
                      return Center(
                        child: Container(
                          padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(24)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(12)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: screenAdapter.getAdaptivePadding(10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.blue[700],
                              ),
                              SizedBox(height: screenAdapter.getAdaptiveHeight(16)),
                              Text(
                                '正在加载用户手册...',
                                style: TextStyle(
                                  fontSize: screenAdapter.getAdaptiveFontSize(14),
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
