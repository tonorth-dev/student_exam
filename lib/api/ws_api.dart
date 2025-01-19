import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../common/config_util.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<String> _messageController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast(); // 新增：用于错误信息
  Stream<String> get messages => _messageController.stream;
  Stream<String> get errors => _errorController.stream; // 新增：提供错误信息流
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
          _errorController.add('WebSocket Error: $error'); // 将错误信息添加到错误流
          print('WebSocket Error: $error');
        },
        onDone: () {
          isConnected.value = false;
          print('WebSocket Connection Closed');
          _errorController.add('WebSocket Connection Closed'); // 将连接关闭信息添加到错误流
        },
      );
    } catch (e) {
      isConnected.value = false;
      _errorController.add('Failed to connect to WebSocket: $e'); // 将连接失败信息添加到错误流
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
      _errorController.add('WebSocket is not connected'); // 将未连接信息添加到错误流
    }
  }

  // 关闭连接
  void disconnect() {
    _channel?.sink.close();
  }

  // 销毁资源
  void dispose() {
    _messageController.close();
    _errorController.close(); // 关闭错误控制器
  }
}