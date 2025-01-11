import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin_flutter/api/exam_topic_api.dart';
import 'package:admin_flutter/ex/ex_hint.dart';
import 'package:admin_flutter/component/dialog.dart';
import '../../../../api/major_api.dart';
import '../../../../common/config_util.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';

// 新增 Unit 和 Topic 数据模型
class Unit {
  int id;
  String name;
  int examId;
  String examName;
  int studentId;
  String studentName;
  int classId;
  String className;
  List<Topic> topics;

  Unit({
    required this.id,
    required this.name,
    required this.examId,
    required this.examName,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.topics,
  });
}

class Topic {
  int id;
  int examId;
  int unitId;
  int classId;
  String className;
  String examName;
  int studentId;
  String studentName;
  int topicId;
  String topicTitle;
  String topicAnswer;
  String majorName;
  bool isCorrect;
  String? isCorrectName;
  int score;
  int status;
  String statusName;
  String practiceTime;
  String createTime;
  String updateTime;

  Topic({
    required this.id,
    required this.examId,
    required this.unitId,
    required this.classId,
    required this.className,
    required this.examName,
    required this.studentId,
    required this.studentName,
    required this.topicId,
    required this.topicTitle,
    required this.topicAnswer,
    required this.majorName,
    required this.isCorrect,
    this.isCorrectName,
    required this.score,
    required this.status,
    required this.statusName,
    required this.practiceTime,
    required this.createTime,
    required this.updateTime,
  });
}

class ExamTopicLogic extends GetxController {
  int id; // 添加 id 变量
  ExamTopicLogic(this.id);

  var list = <Map<String, dynamic>>[].obs;
  var loading = false.obs;
  final searchText = ''.obs;
  // 使用 Unit 列表
  var unitList = <Unit>[].obs;
  var columns = <GridColumn>[].obs;

  final GlobalKey<CascadingDropdownFieldState> majorDropdownKey =
  GlobalKey<CascadingDropdownFieldState>();

  // 当前编辑的题目数据
  RxList<int> selectedRows = <int>[].obs;
  // 专业列表数据
  Rx<String> selectedStudentIde = "0".obs;

  final examTopicId = 0.obs; // 对应 ID
  final examTopicName = ''.obs; // 对应 Name
  final majorId = 0.obs; // 对应 MajorID
  final jobCode = 0.obs; // 对应 JobCode
  final sort = 0.obs; // 对应 Sort
  final creator = ''.obs; // 对应 Creator
  final examTopicCategory = ''.obs; // 对应 Category
  final pageCount = 0.obs; // 对应 PageCount
  final status = 0.obs; // 对应 Status

  // Maps for reverse lookup
  Map<String, String> level3IdToLevel2Id = {};
  Map<String, String> level2IdToLevel1Id = {};

  void find() {
    list.clear();
    loading.value = true;
    print("Fetching exam units..."); // Debug log
    try {
      ExamTopicApi.examUnitList({
        "exam_id": (id.toString() ?? ""),
      }).then((value) async {
        if (value != null && value["list"] != null) {
          unitList.clear();
          for (var unitData in value["list"]) {
            List<Topic> topics = [];
            if (unitData["topics"] != null) {
              for (var topicData in unitData["topics"]) {
                topics.add(Topic(
                  id: topicData["id"],
                  examId: topicData["exam_id"],
                  unitId: topicData["unit_id"],
                  classId: topicData["class_id"],
                  className: topicData["class_name"],
                  examName: topicData["exam_name"],
                  studentId: topicData["student_id"],
                  studentName: topicData["student_name"],
                  topicId: topicData["topic_id"],
                  topicTitle: topicData["topic_title"],
                  topicAnswer: topicData["topic_answer"],
                  majorName: topicData["major_name"] ?? "",
                  isCorrect: topicData["is_correct"] ?? false,
                  isCorrectName: topicData["is_correct_name"],
                  score: topicData["score"] ?? 0,
                  status: topicData["status"] ?? 0,
                  statusName: topicData["status_name"] ?? "",
                  practiceTime: topicData["practice_time"] ?? "",
                  createTime: topicData["create_time"],
                  updateTime: topicData["update_time"],
                ));
              }
            }
            unitList.add(Unit(
              id: unitData["id"],
              name: unitData["name"],
              examId: unitData["exam_id"],
              examName: unitData["exam_name"],
              studentId: unitData["student_id"],
              studentName: unitData["student_name"],
              classId: unitData["class_id"],
              className: unitData["class_name"],
              topics: topics,
            ));
          }
          await Future.delayed(const Duration(milliseconds: 300));
          loading.value = false;
        } else {
          loading.value = false;
          "未获取到练习题数据".toHint();
        }
      }).catchError((error) {
        loading.value = false;
        print("获取练习题列表失败: $error");
        "获取练习题列表失败: $error".toHint();
      });
    } catch (e) {
      loading.value = false;
      print("获取练习题列表失败: $e");
      "获取练习题列表失败: $e".toHint();
    }
  }

  void _initColumns() {
    columns.value = [
      GridColumn(columnName: 'ID', label: _buildHeaderCell('ID'), width: 80),
      GridColumn(columnName: '试卷名称', label: _buildHeaderCell('试卷名称'), width: 150),
      GridColumn(columnName: '班级名称', label: _buildHeaderCell('班级名称'), width: 150),
      GridColumn(columnName: '考生名称', label: _buildHeaderCell('考生名称'), width: 100),
      GridColumn(columnName: '试题', label: _buildHeaderCell('试题'), width: 200),
      GridColumn(columnName: '答案', label: _buildHeaderCell('答案'), width: 250),
      GridColumn(columnName: '专业名称', label: _buildHeaderCell('专业名称'), width: 100),
      GridColumn(columnName: '练习状态', label: _buildHeaderCell('练习状态'), width: 100),
      GridColumn(columnName: '练习时间', label: _buildHeaderCell('练习时间'), width: 120),
      GridColumn(columnName: '操作', label: _buildHeaderCell('操作'), width: 140),
    ];
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      color: Color(0xFFF3F4F8),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[800]),
      ),
    );
  }

  @override
  void onInit() {
    super.onInit();
    _initColumns();
    find();
  }

  void reset() {
    majorDropdownKey.currentState?.reset();
    searchText.value = '';
    selectedRows.clear();

    // 重新初始化数据
    find();
  }
}