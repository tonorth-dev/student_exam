import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../common/config_util.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<String> _messageController = StreamController<String>.broadcast();
  Stream<String> get messages => _messageController.stream;
  final RxBool isConnected = false.obs;

  // 私有构造函数，防止外部直接创建实例
  WebSocketService._internal();

  // 静态实例变量
  static final WebSocketService _instance = WebSocketService._internal();

  // 工厂构造函数，返回单例实例
  factory WebSocketService() => _instance;

  // 连接 WebSocket
  Future<void> connect(String code, String classId) async {
    if (isConnected.value) {
      print("WebSocket already connected.");
      return; // 如果已连接，则直接返回
    }

    final url = "${ConfigUtil.wsUrl}:${ConfigUtil.httpPort}/ws/dialogue?type=student&code=$code&class_id=$classId";
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      isConnected.value = true;

      _channel!.stream.listen(
            (message) {
          _messageController.add(message);
        },
        onError: (error) {
          isConnected.value = false;
          print('WebSocket Error: $error');
          // 可选：尝试重连
          // connect(code, classId);
        },
        onDone: () {
          isConnected.value = false;
          print('WebSocket Connection Closed');
          // 可选：尝试重连
          // connect(code, classId);
        },
      );
    } catch (e) {
      isConnected.value = false;
      print('Failed to connect to WebSocket: $e');
      // 可选：根据需要处理异常，例如重试连接
      // rethrow;
    }
  }

  // 发送消息
  void sendMessage(Map<String, dynamic> message) {
    if (isConnected.value && _channel != null) {
      print("send message: ${jsonEncode(message)}");
      _channel!.sink.add(jsonEncode(message));
    } else {
      print('WebSocket is not connected');
      // 可选：将消息放入队列，待连接建立后发送
    }
  }

  // 关闭连接
  void disconnect() {
    _channel?.sink.close();
    isConnected.value = false;
    _channel = null; // 清空channel
  }

  // 销毁资源
  void dispose() {
    _messageController.close();
  }
}