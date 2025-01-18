import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../common/config_util.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<String> _messageController = StreamController.broadcast();
  Stream<String> get messages => _messageController.stream;
  final RxBool isConnected = false.obs;

  // 连接 WebSocket
  Future<void> connect(String code, String classId) async {
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
        },
        onDone: () {
          isConnected.value = false;
          print('WebSocket Connection Closed');
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      rethrow; // 重新抛出异常以便调用者可以处理
    }
  }

  // 发送消息
  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    } else {
      print('WebSocket is not connected');
    }
  }

  // 关闭连接
  void disconnect() {
    _channel?.sink.close();
  }

  // 销毁资源
  void dispose() {
    _messageController.close();
  }
}
