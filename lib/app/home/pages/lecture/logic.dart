import 'dart:io';

import 'package:student_exam/api/job_api.dart';
import 'package:student_exam/ex/ex_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_exam/api/lecture_api.dart';
import 'package:student_exam/ex/ex_hint.dart';
import 'package:student_exam/component/dialog.dart';
import '../../../../api/major_api.dart';
import '../../../../common/config_util.dart';
import '../../../../component/table/table_data.dart';
import '../../../../component/widget.dart';

class FileModel {
  final String url;
  final String name;
  // 添加其他需要的属性
  
  FileModel({
    required this.url,
    required this.name,
  });
}

class LectureLogic extends GetxController {
  var list = <Map<String, dynamic>>[].obs;
  var total = 0.obs;
  var size = 15.obs;
  var page = 1.obs;
  var loading = false.obs;
  final searchText = ''.obs;
  final RxString selectedKey = ''.obs; // 初始化为空字符串
  final RxList<String> expandedKeys = <String>[].obs;

  final RxString selectedLectureId = '0'
      .obs; // To track which lecture's directory we are viewing
  final RxList<DirectoryNode> directoryTree = RxList<DirectoryNode>([]);

  var isLoading = false.obs;


  final GlobalKey<CascadingDropdownFieldState> majorDropdownKey =
  GlobalKey<CascadingDropdownFieldState>();

  // 当前编辑的题目数据
  var currentEditLecture = RxMap<String, dynamic>({}).obs;
  RxList<int> selectedRows = <int>[].obs;

  final ValueNotifier<dynamic> selectedLevel1 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel2 = ValueNotifier(null);
  final ValueNotifier<dynamic> selectedLevel3 = ValueNotifier(null);

  // 专业列表数据
  List<Map<String, dynamic>> majorList = [];
  Map<String, List<Map<String, dynamic>>> subMajorMap = {};
  Map<String, List<Map<String, dynamic>>> subSubMajorMap = {};
  List<Map<String, dynamic>> level1Items = [];
  Map<String, List<Map<String, dynamic>>> level2Items = {};
  Map<String, List<Map<String, dynamic>>> level3Items = {};
  Rx<String> selectedMajorId = "0".obs;

  // Maps for reverse lookup
  Map<String, String> level3IdToLevel2Id = {};
  Map<String, String> level2IdToLevel1Id = {};

  // 添加文件列表
  final RxList<FileModel> fileList = <FileModel>[].obs;
  // 添加当前选中的文件
  final Rx<FileModel?> selectedFile = Rx<FileModel?>(null);

  // 添加当前选中节点的索引
  final RxInt selectedNodeIndex = RxInt(0);

  // 将 selectedNodeId 改为可观察变量
  final RxInt selectedNodeId = 0.obs;

  final Rx<DirectoryNode?> selectedNode = Rx<DirectoryNode?>(null);

  void find(int newSize, int newPage) {
    size.value = newSize;
    page.value = newPage;
    list.clear();
    selectedRows.clear();
    loading.value = true;
    // 打印调用堆栈
    try {
      LectureApi.lectureList({
        "size": size.value.toString(),
        "page": page.value.toString(),
        "keyword": searchText.value.toString() ?? "",
        "major_id": (selectedMajorId.value.toString() ?? ""),
      }).then((value) async {
        if (value != null && value["list"] != null) {
          total.value = value["total"] ?? 0;
          list.assignAll((value["list"] as List<dynamic>).toListMap());
          await Future.delayed(const Duration(milliseconds: 300));
          loading.value = false;
        } else {
          loading.value = false;
          "未获取到讲义数据".toHint();
        }
      }).catchError((error) {
        loading.value = false;
        print("获取讲义列表失败: $error");
        "获取讲义列表失败: $error".toHint();
      });
    } catch (e) {
      loading.value = false;
      print("获取讲义列表失败: $e");
      "获取讲义列表失败: $e".toHint();
    }
  }

  var columns = <ColumnData>[];

  @override
  void onInit() {
    super.onInit(); // Fetch and populate major data on initialization

    columns = [
      ColumnData(title: "ID", key: "id", width: 0),
      ColumnData(title: "讲义名称", key: "name", width: 150),
      ColumnData(title: "专业", key: "major_name", width: 100),
      ColumnData(title: "岗位代码", key: "job_code", width: 0),
      ColumnData(title: "排序", key: "sort", width: 0),
      ColumnData(title: "创建者", key: "creator"),
      ColumnData(title: "讲义类别", key: "category"),
      ColumnData(title: "大小", key: "size"),
      ColumnData(title: "页数", key: "pagecount"),
      ColumnData(title: "状态", key: "status"),
      ColumnData(title: "创建时间", key: "created_time"),
    ];

    // 初始化数据
    // find(size.value, page.value);
  }


  @override
  void refresh() {
    find(size.value, page.value);
  }

  void loadDirectoryTree(String lectureId, bool isRefresh) async {
    if (selectedLectureId.value == lectureId && !isRefresh) {
      return; // No need to reload if the selected lecture hasn't changed
    }

    selectedLectureId.value = lectureId;
    try {
      final treeData = await LectureApi.getLectureDirectoryTree(lectureId);
      print(treeData);
      directoryTree.value = _buildTreeFromAPIResponse(treeData);
    } catch (e) {
      print("Failed to load directory tree: $e");
      // Handle error, possibly show to user or log
    }
  }

  List<DirectoryNode> _buildTreeFromAPIResponse(dynamic data) {
    // 转换为 Map，以 id 为键
    final Map<int, DirectoryNode> nodeMap = {
      for (var item in data)
        item['id']: DirectoryNode.fromJson(item),
    };

    final List<DirectoryNode> tree = [];

    for (var node in nodeMap.values) {
      if (node.parentId != null && nodeMap.containsKey(node.parentId)) {
        // 如果有父节点，加入父节点的 children
        nodeMap[node.parentId]?.children.add(node);
      } else {
        // 如果没有父节点，说明是根节点
        tree.add(node);
      }
    }

    return tree;
  }

  final selectedPdfUrl = RxnString("");

  void updatePdfUrl(String url) {
    if (url.isEmpty) {
      selectedPdfUrl.value = "";
      debugPrint('Selected PDF URL updated: ${selectedPdfUrl.value}');
      return;
    }
    if (selectedPdfUrl.value !=
        "${ConfigUtil.ossUrl}$url") {
      selectedPdfUrl.value =
      "${ConfigUtil.ossUrl}$url";
      debugPrint('Selected PDF URL updated: ${selectedPdfUrl.value}');
    }
  }

  // 将 _getAllNodes 改为公开方法
  List<DirectoryNode> getAllNodes(List<DirectoryNode> nodes) {
    List<DirectoryNode> result = [];
    for (var node in nodes) {
      result.add(node);
      if (node.children.isNotEmpty) {
        result.addAll(getAllNodes(node.children));
      }
    }
    return result;
  }

  // 修改使用 getAllNodes 的地方
  void moveToNextChapter() {
    if (selectedPdfUrl.value == null || selectedPdfUrl.value!.isEmpty) return;
    
    final currentUrl = ConfigUtil.ossUrl;
    final nodes = getAllNodes(directoryTree);
    final currentIndex = nodes.indexWhere((node) => 
      node.filePath != null && 
      selectedPdfUrl.value == "$currentUrl${node.filePath}"
    );
    
    if (currentIndex < nodes.length - 1) {
      final nextNode = nodes[currentIndex + 1];
      if (nextNode.filePath != null) {
        selectedNodeId.value = nextNode.id;  // 使用 .value 更新
        updateSelectedFile(nextNode);
        update(['file_list']);
      }
    }
  }

  void moveToPreviousChapter() {
    if (selectedPdfUrl.value == null || selectedPdfUrl.value!.isEmpty) return;
    
    final currentUrl = ConfigUtil.ossUrl;
    final nodes = getAllNodes(directoryTree);
    final currentIndex = nodes.indexWhere((node) => 
      node.filePath != null && 
      selectedPdfUrl.value == "$currentUrl${node.filePath}"
    );
    
    if (currentIndex > 0) {
      final previousNode = nodes[currentIndex - 1];
      if (previousNode.filePath != null) {
        selectedNodeId.value = previousNode.id;  // 使用 .value 更新
        updateSelectedFile(previousNode);
        update(['file_list']);
      }
    }
  }

  // 更新选中的文件
  void updateSelectedFile(DirectoryNode node) {
    selectedNode.value = node;  // Update selected node
    selectedNodeId.value = node.id;
    if (node.filePath != null) {
      updatePdfUrl(node.filePath!);
    }
  }

  DirectoryNode? getNextNode() {
    if (selectedPdfUrl.value == null || selectedPdfUrl.value!.isEmpty) return null;
    
    final currentUrl = ConfigUtil.ossUrl;
    final nodes = getAllNodes(directoryTree);
    final currentIndex = nodes.indexWhere((node) => 
      node.filePath != null && 
      selectedPdfUrl.value == "$currentUrl${node.filePath}"
    );
    
    return currentIndex < nodes.length - 1 ? nodes[currentIndex + 1] : null;
  }

  DirectoryNode? getPreviousNode() {
    if (selectedPdfUrl.value == null || selectedPdfUrl.value!.isEmpty) return null;
    
    final currentUrl = ConfigUtil.ossUrl;
    final nodes = getAllNodes(directoryTree);
    final currentIndex = nodes.indexWhere((node) => 
      node.filePath != null && 
      selectedPdfUrl.value == "$currentUrl${node.filePath}"
    );
    
    return currentIndex > 0 ? nodes[currentIndex - 1] : null;
  }
}

class DirectoryNode {
  final int id;
  final int? parentId;
  final int level;
  final String name;
  final String? filePath;
  RxList<DirectoryNode> children;

  DirectoryNode(
      {required this.id, this.parentId, required this.level, required this.name, this.filePath, List<
          DirectoryNode>? children})
      : children = RxList(children ?? []);

  factory DirectoryNode.fromJson(Map<String, dynamic> json) {
    return DirectoryNode(
      id: json['id'],
      parentId: json['parent_id'],
      level: json['level'],
      name: json['name'],
      filePath: json['file_path'],
      children: (json['children'] as List<dynamic>?)
          ?.map((child) => DirectoryNode.fromJson(child))
          .toList() ?? [],
    );
  }
}