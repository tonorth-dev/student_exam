import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:student_exam/api/exam_api.dart';
import 'package:student_exam/ex/ex_hint.dart';

import '../../../../api/ws_api.dart';
import '../../../../common/app_data.dart';
import '../../../login/view.dart';
import 'countdown_logic.dart';
import 'exam_logic.dart';

class WSLogic extends GetxController {
  final RxList students = [].obs; // 动态绑定学生数据
  final RxMap exam = {}.obs; // 动态绑定学生数据
  var examId = 0; // 考试ID
  RxString connStatusName = "未连接".obs;
  final WebSocketService webSocketService = WebSocketService();
  final ExamLogic examLogic = Get.put(ExamLogic()); // 初始化 examLogic 实例
  bool isConnecting = false;

  // 用来记录上次心跳发送的时间
  Timer? _heartbeatTimer; // 定时器
  DateTime? lastHeartbeatTime;
  final int heartbeatTimeoutSeconds = 10; // 假设超时时间是5秒
  RxString examCode = "".obs;
  bool isConnectionFailed = false;
  Rx<List<Map<String, dynamic>>> unitsList = Rx([]);
  var questions = <Question>[].obs;
  late Countdown countdownLogic;

  @override
  void onInit() {
    countdownLogic = Countdown(
        totalDuration: 900); // Default total duration in seconds (15 minutes)
    super.onInit();
  }

  void connectStudent(String code) async {
    if (code == "") {
      "请输入登录码".toHint();
      return;
    }
    try {
      isConnecting = true;
      connStatusName.value = "正在连接..."; // 连接中状态
      await webSocketService.connect(code, "").catchError((error) {
        print('WebSocket 连接错误: $error');
        if (!isConnectionFailed) {
          showErrorDialog('错误', 'WebSocket 连接失败，请重试。');
          isConnectionFailed = true; // Mark failure
        }
        isConnecting = false;
        connStatusName.value = "连接断开";
        stopHeartbeat(); // Stop the heartbeat when connection fails
        return;
      });

      // Listen to WebSocket messages
      webSocketService.messages.listen((message) {
        final parsedMessage = jsonDecode(message);
        print(parsedMessage);
        handleIncomingMessage(parsedMessage);
      }).onError((error) {
        print('WebSocket 消息监听错误: $error');
        if (!isConnectionFailed) {
          showErrorDialog('错误', 'WebSocket 消息监听失败。');
          isConnectionFailed = true; // Mark failure
        }
        isConnecting = false;
        connStatusName.value = "连接断开";
        stopHeartbeat(); // Stop the heartbeat on error
      });

      startHeartbeat(); // Start heartbeat once connected
    } catch (e) {
      print('连接 WebSocket 发生错误: $e');
      if (!isConnectionFailed) {
        showErrorDialog('错误', '连接 WebSocket 失败，请重试。');
        isConnectionFailed = true; // Mark failure
      }
      isConnecting = false;
      connStatusName.value = "连接断开";
      stopHeartbeat(); // Stop the heartbeat on error
    }
  }

  // Stop heartbeat timer when connection fails
  void stopHeartbeat() {
    if (_heartbeatTimer != null) {
      _heartbeatTimer!.cancel();
      _heartbeatTimer = null;
    }
  }

  // Send heartbeat messages every 2 seconds
  void startHeartbeat() {
    _heartbeatTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!webSocketService.isConnected.value) {
        if (connStatusName.value != "连接断开") {
          connStatusName.value = "连接失败";
        }
        isConnecting = false;
        return; // Stop heartbeat if connection failed
      }

      final heartbeatMessage = {
        'type': 'status',
        'user_type': 'student',
      };

      webSocketService.sendMessage(heartbeatMessage);
      print("Heartbeat sent to server");

      // 检查是否超时
      if (lastHeartbeatTime != null &&
          DateTime.now().difference(lastHeartbeatTime!).inSeconds >
              heartbeatTimeoutSeconds) {
        // 如果超过超时限制没有收到响应，认为连接断开
        connStatusName.value = "连接断开";
        stopHeartbeat(); // 停止心跳检测
        // 可以显示错误提示或者重新连接
        showErrorDialog('错误', '连接超时，服务器未响应。');
      }
    });
  }

  // Handle incoming messages
  void handleIncomingMessage(Map<String, dynamic> message) {
    final messageType = message['type'];
    switch (messageType) {
      case 'confirm':
        final student = message['student'];
        'Student: $student has confirmed the connection.'.toHint();
        break;
      case 'timer':
        final action = message['message'];
        switch (action) {
          case 'start':
            countdownLogic.startTimer();
            break;
          case 'pause':
            countdownLogic.pause();
            break;
          case 'stop':
            countdownLogic.stop();
            break;
          case 'reset':
            countdownLogic.reset();
            break;
        }
      case 'status':
        print('receive message: $message');
        final status = message['status'];
        switch (status) {
          case 0:
            connStatusName.value = "未连接";
            break;
          case 1:
            connStatusName.value = "教师端已连接";
            break;
          case 2:
            connStatusName.value = "教师端断开";
            break;
          case 3:
            connStatusName.value = "匹配成功";
            break;
          default:
            connStatusName.value = "状态异常，请联系技术人员"; // 处理未知状态
        }
        break;
      case 'error':
        final error = message['message'];
        if (error.contains('登录码已过期')) {
          "登录已失效，需重新登录".toHint();
          LoginData.clear();
          Future.delayed(Duration(milliseconds: 1000));
          Get.to(() => LoginPage());
        }
        error.toString().toHint();
      case 'select_start':
        // 提取 units 字段
        List<Map<String, dynamic>> units =
            List<Map<String, dynamic>>.from(message['units']);
        // 将 units 赋值给 Rx 变量
        unitsList.value = units;
        print("Received units: ${unitsList.value}");
      case 'question':
        final question = message['questions'];
        print('question: $question seconds remaining.');
        examLogic.updateQuestions(question
            .map((q) {
              return Question(
                title: q["title"] ?? '未知标题',
                answer: '',
              );
            })
            .toList()
            .cast<Question>());
        break;
      case 'animate':
        var indexString = message['message'];
        if (indexString != null) {
          var index = int.parse(indexString);
          print('Received animate message: $index');
          examLogic.currentQuestionIndex.value = index;
          examLogic.animateToItem(index);
        } else {
          print('Index is null, cannot animate.');
        }
        break;
      default:
        print('Unknown message type: $messageType');
    }
  }

  void sendStudentSelect(int unitId) {
    final selectMessage = {
      'type': 'select_done',
      'code': examCode.value,
      'user_type': 'student',
      'status': 3,
      'message': unitId.toString(), // 显式转换类型
    };

    webSocketService.sendMessage(selectMessage);
  }

  void disconnect() {
    try {
      stopHeartbeat(); // 停止心跳
      if (webSocketService.isConnected.value) {
        webSocketService.disconnect(); // 调用 WebSocketService 的断开方法
        isConnecting = false; // 标记为未连接
        connStatusName.value = "连接断开";
        print("Disconnected from WebSocket.");
      }
    } catch (e) {
      print("Error while disconnecting: $e");
      showErrorDialog('错误', '断开连接时发生错误，请稍后重试。');
    }
  }

  void showErrorDialog(String title, String message) {
    if (!isConnectionFailed) {
      Get.dialog(
        AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      isConnectionFailed = true; // Mark failure after showing dialog
    }
  }
}
