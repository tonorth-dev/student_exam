import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:student_exam/api/exam_api.dart';
import 'package:student_exam/ex/ex_hint.dart';

import '../../../../api/ws_api.dart';
import '../../../../common/app_data.dart';
import 'exam_logic.dart';

class WSLogic extends GetxController {
  final RxList students = [].obs; // 动态绑定学生数据
  final RxMap exam = {}.obs; // 动态绑定学生数据
  late StudentDataSource dataSource; // 数据源
  var examId = 0; // 考试ID
  RxString connStatusName = "未连接".obs;
  final WebSocketService webSocketService = WebSocketService();
  bool isConnecting = false;
  // 用来记录上次心跳发送的时间
  Timer? _heartbeatTimer; // 定时器
  DateTime? lastHeartbeatTime;
  final int heartbeatTimeoutSeconds = 10; // 假设超时时间是5秒
  RxString examCode = "".obs;
  bool isConnectionFailed = false;

  void connectStudent(String code) async {
    try {
      isConnecting = true;
      connStatusName.value = "正在连接..."; // 连接中状态
      await webSocketService.connect(code, "").catchError((error) {
        print('WebSocket 连接错误: $error');
        if (!isConnectionFailed) {
          showErrorDialog('错误', 'WebSocket 连接失败，请重试。');
          isConnectionFailed = true;  // Mark failure
        }
        isConnecting = false;
        connStatusName.value = "连接失败";
        stopHeartbeat();  // Stop the heartbeat when connection fails
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
          isConnectionFailed = true;  // Mark failure
        }
        isConnecting = false;
        connStatusName.value = "连接失败";
        stopHeartbeat();  // Stop the heartbeat on error
      });

      startHeartbeat();  // Start heartbeat once connected
    } catch (e) {
      print('连接 WebSocket 发生错误: $e');
      if (!isConnectionFailed) {
        showErrorDialog('错误', '连接 WebSocket 失败，请重试。');
        isConnectionFailed = true;  // Mark failure
      }
      isConnecting = false;
      connStatusName.value = "连接失败";
      stopHeartbeat();  // Stop the heartbeat on error
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
        connStatusName.value = "连接失败";
        return;  // Stop heartbeat if connection failed
      }

      final heartbeatMessage = {
        'type': 'status',
        'user_type': 'student',
      };

      webSocketService.sendMessage(heartbeatMessage);
      print("Heartbeat sent to server");

      // 检查是否超时
      if (lastHeartbeatTime != null && DateTime.now().difference(lastHeartbeatTime!).inSeconds > heartbeatTimeoutSeconds) {
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
        final timer = message['timer'];
        print('Timer: $timer seconds remaining.');
        break;
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
            connStatusName.value = "学生端已匹配成功";
            break;
          default:
            connStatusName.value = "状态异常，请联系技术人员"; // 处理未知状态
        }
        break;
      default:
        print('Unknown message type: $messageType');
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

  void pullExam() async {
    try {
      var data = await ExamApi.pullExam();
      if (data != null && data.isNotEmpty) {
        examId = data['id'];
        exam.value = {
          "id": data['id'],
          "name": data['name'],
          "class_id": data['class_id'],
          "class_name": data['class_name'],
          "level": data['level'],
          "level_name": data['level_name'],
          "cate": data['cate'],
          "cate_name": data['cate_name'],
          "question_count": data['question_count'],
          "student_count": data['student_count'],
        };
        students.value = data['students']; // 更新学生数据
        dataSource = StudentDataSource(students, data['id']); // 初始化数据源
        showStudentsDialog(exam['name']); // 展示弹窗
      } else {
        '没有分配的试题'.toHint();
      }
    } catch (e) {
      print("Error in pullExam: $e");
      if (!e.toString().contains('登录已失效')) {
        '系统发生错误，没有抽取到试题'.toHint();
      }
    }
  }

  void showStudentsDialog(String title) {
    Get.defaultDialog(
      title: title,
      content: Container(
        width: 1000, // 表格宽度
        height: 600, // 表格高度
        child: SfDataGrid(
          source: dataSource,
          columnWidthMode: ColumnWidthMode.fill,
          headerGridLinesVisibility: GridLinesVisibility.both,
          rowHeight: 60, // 行高
          gridLinesVisibility: GridLinesVisibility.both,
          allowSwiping: false, // 禁止悬浮行为
          columns: [
            GridColumn(
              columnName: 'name',
              label: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                color: Color(0xE0FB8C00),
                child: const Text(
                  '考生姓名',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            GridColumn(
              columnName: 'job_code',
              label: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                color: Color(0xE0FB8C00),
                child: const Text(
                  '岗位代码',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            GridColumn(
              columnName: 'job',
              label: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                color: Color(0xE0FB8C00),
                child: const Text(
                  '职位',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            GridColumn(
              columnName: 'practiced',
              label: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                color: Color(0xE0FB8C00),
                child: const Text(
                  '已练习',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            GridColumn(
              columnName: 'notPracticed',
              label: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                color: Color(0xE0FB8C00),
                child: const Text(
                  '未练习',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            GridColumn(
              columnName: 'action',
              label: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                color: Color(0xE0FB8C00),
                child: const Text(
                  '操作',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentDataSource extends DataGridSource {
  final ExamLogic examLogic = Get.put(ExamLogic());
  List<DataGridRow> _rows = [];
  var examId = 0;

  StudentDataSource(List students, this.examId) {
    _rows = students.map<DataGridRow>((student) {
      return DataGridRow(cells: [
        DataGridCell(columnName: 'name', value: student['student_name']),
        DataGridCell(columnName: 'job_code', value: student['job_code']),
        DataGridCell(columnName: 'job', value: student['job_name']),
        DataGridCell(columnName: 'practiced', value: student['practiced_count']),
        DataGridCell(columnName: 'notPracticed', value: student['not_practiced_count']),
        DataGridCell(columnName: 'action', value: student['student_id']),
      ]);
    }).toList();
    examId = examId;
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final rowIndex = _rows.indexOf(row);
    final backgroundColor = rowIndex % 2 == 0
        ? Color(0xB0FFFFFF) // 偶数行背景色
        : Color(0x20FFECB3); // 奇数行背景色

    return DataGridRowAdapter(
      color: backgroundColor,
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'action') {
          return Container(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                // 关闭当前弹窗并开始练习
                Get.back();
                final studentId = cell.value;
                examLogic.startPractice(studentId, examId);
                examLogic.animateToItem(examLogic.currentQuestionIndex.value);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 设置圆角半径为8
                ),
              ),
              child: const Text("开始练习"),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.center,
          child: SelectableText(cell.value.toString()), // 可选文本
        );
      }).toList(),
    );
  }
}
