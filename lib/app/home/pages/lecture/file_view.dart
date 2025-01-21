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
          "请点击讲义进行学习",
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
        ],
      ),
    );
  }
}
