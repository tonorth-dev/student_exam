import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../component/table/ex.dart';
import '../../../../theme/theme_util.dart';
import 'logic.dart';

class LectureFileView extends StatefulWidget {
  final String title;
  final LectureLogic logic;

  const LectureFileView({Key? key, required this.title, required this.logic}) : super(key: key);

  @override
  _LectureFileViewState createState() => _LectureFileViewState();
}

class _LectureFileViewState extends State<LectureFileView> {
  final Map<int, bool> _loadingStates = {};
  late TreeController<DirectoryNode> treeController;

  @override
  void initState() {
    super.initState();
    treeController = TreeController<DirectoryNode>(
      roots: widget.logic.directoryTree,
      childrenProvider: (DirectoryNode node) => node.children.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableEx.actions(
          children: [
            SizedBox(width: 30), // 添加一些间距
            Container(
              height: 50,
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade300],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        ThemeUtil.lineH(),
        ThemeUtil.height(),
        Expanded(
          child: Obx(() {
            if (widget.logic.directoryTree.isEmpty) {
              return _buildEmptyState(context);
            } else {
              return _buildTreeView(context);
            }
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: Colors.grey.shade100),
      child: Center(
        child: Text(
          "点击讲义列表的管理按钮，进行文件管理",
          style: TextStyle(
              fontSize: 16.0,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  TreeView<DirectoryNode> _buildTreeView(BuildContext context) {
    treeController.expandAll(); // 控制默认展开或关闭

    return TreeView<DirectoryNode>(
      treeController: treeController,
      nodeBuilder: (BuildContext context, TreeEntry<DirectoryNode> entry) {
        return _buildTreeNode(context, entry);
      },
    );
  }

  Widget _buildTreeNode(BuildContext context, TreeEntry<DirectoryNode> entry) {
    final DirectoryNode dirNode = entry.node;
    final bool isFileNode = dirNode.filePath != null && dirNode.filePath!.isNotEmpty;
    final bool isLeafNode = dirNode.children.isEmpty;
    final bool isExpanded = entry.isExpanded;

    // 根据节点层级设置缩进
    final double indentLevel = entry.level * 24.0; // 每一级增加24像素的缩进

    // 检查是否为选中状态
    final bool isSelected = widget.logic.selectedNodeId == dirNode.id;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (isFileNode && isLeafNode) {
          widget.logic.updatePdfUrl(dirNode.filePath!);
          // 设置选中状态
          setState(() {
            widget.logic.selectedNodeId = dirNode.id;
          });
        } else {
          treeController.toggleExpansion(entry.node);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(left: indentLevel, top: 8.0, bottom: 8.0),
        child: Row(
          children: [
            // 固定宽度容器，确保图标不会影响文本对齐
            Container(
              width: 24, // 固定宽度
              alignment: Alignment.centerLeft,
              child: (isFileNode && isLeafNode)
                  ? Icon(Icons.insert_drive_file, size: 16, color: Colors.blueGrey) // 文件图标
                  : Icon(isExpanded ? Icons.remove : Icons.add, size: 16, color: Colors.greenAccent), // 文件夹展开/折叠图标
            ),
            Expanded(
              child: Text(
                dirNode.name,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.blueAccent : Colors.black, // 变色样式
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            SizedBox(width: 16),
            _buildOperationButtons(context, dirNode), // 确保此方法已定义
          ],
        ),
      ),
    );
  }

  Widget _buildOperationButtons(BuildContext context, DirectoryNode dirNode) {
    bool isFilePathEmpty =
        dirNode.filePath == null || dirNode.filePath!.isEmpty;
    bool isLeafNode = dirNode.children.isEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconButton(
          Icons.add,
          "添加",
              () => _addSubdirectory(context, dirNode),
          color: Colors.blueAccent,
          isEnabled: isFilePathEmpty,
        ),
        _buildIconButton(
          Icons.file_upload,
          "上传文件",
              () => _importFile(context, dirNode),
          color: Colors.blueAccent,
          isEnabled: isLeafNode, // 仅当是叶子节点时启用
        ),
        if (_loadingStates[dirNode.id] ?? false)
          SizedBox(
            width: 20, // 固定宽度为30像素
            height: 20,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        if (!(_loadingStates[dirNode.id] ?? false))
          _buildIconButton(
          Icons.upload_file,
          "导入目录",
              () => _importDir(context, dirNode),
          color: Colors.blueAccent,
          isEnabled: true,
        ),
        _buildIconButton(
          Icons.edit,
          "编辑",
              () => _updateDir(context, dirNode),
          color: Colors.green,
          isEnabled: true, // 编辑按钮总是启用
        ),
        _buildIconButton(
          Icons.delete,
          "删除",
              () => _confirmDelete(context, dirNode, isLeafNode),
          color: Colors.orangeAccent,
          isEnabled: true, // 删除按钮总是启用
        ),
        SizedBox(width: 10,)
      ],
    );
  }

  Widget _buildIconButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
    bool isEnabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: isEnabled ? onPressed : null,
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: Colors.transparent,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isEnabled ? (color ?? Colors.black) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DirectoryNode node, bool isLeafNode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("确认删除"),
        content: isLeafNode ? Text("您确定要删除节点 '${node.name}' 吗？") : Text("您确定要删除节点 '${node.name}' 吗？删除后其子目录也都将被删除！", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        actions: [
          TextButton(
            child: Text("取消"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text("删除", style: TextStyle(color: Colors.red)),
            onPressed: () {
              widget.logic.deleteDirectory(node.id);
              widget.logic.loadDirectoryTree(widget.logic.selectedLectureId.value, true);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _addSubdirectory(BuildContext context, DirectoryNode parent) {
    String? newDirName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("添加节点"),
        content: TextField(
          onChanged: (value) => newDirName = value,
          decoration: InputDecoration(hintText: "目录名称"),
        ),
        actions: [
          TextButton(
            child: Text("取消"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text("添加"),
            onPressed: () {
              if (newDirName != null && newDirName!.isNotEmpty) {
                widget.logic.addNewDirectory(newDirName!, parent.id);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _importFile(BuildContext context, DirectoryNode node) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      widget.logic.importFileToNode(file, node);
    }
  }

  void _importDir(BuildContext context, DirectoryNode node) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) {
      return;
    }

    setState(() {
      _loadingStates[node.id] = true; // 设置当前节点为加载状态
    });

    try {
      File file = File(result.files.single.path!);
      await widget.logic.importFileToDir(
        file,
        int.parse(widget.logic.selectedLectureId.value),
        node.id,
      );
    } finally {
      setState(() {
        _loadingStates[node.id] = false; // 操作完成，重置加载状态
      });
    }
  }

  void _updateDir(BuildContext context, DirectoryNode node) {
    TextEditingController controller = TextEditingController(text: node.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("修改节点名称"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "节点名称"),
        ),
        actions: [
          TextButton(
            child: Text("取消"),
            onPressed: () {
              Navigator.of(context).pop();
              controller.dispose(); // 释放控制器
            },
          ),
          TextButton(
            child: Text("更新"),
            onPressed: () {
              final newDirName = controller.text;
              if (newDirName.isNotEmpty) {
                widget.logic.updateDirectory(newDirName, node.id);
                Navigator.of(context).pop();
                controller.dispose(); // 释放控制器
              }
            },
          ),
        ],
      ),
    );
  }
}
