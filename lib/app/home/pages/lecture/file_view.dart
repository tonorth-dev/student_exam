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

    // 添加监听器，当目录树更新时选中第一个文件节点
    ever(widget.logic.directoryTree, (_) {
      _selectFirstFileNode();
    });
  }

  // 选中第一个文件节点的方法
  void _selectFirstFileNode() {
    if (widget.logic.directoryTree.isEmpty) return;
    
    // 获取所有节点的平铺列表
    final allNodes = widget.logic.getAllNodes(widget.logic.directoryTree);
    
    // 查找第一个包含文件路径的节点
    final firstFileNode = allNodes.firstWhereOrNull(
      (node) => node.filePath != null && node.filePath!.isNotEmpty
    );
    
    // 如果找到了文件节点，就选中它并执行选中动作
    if (firstFileNode != null) {
      // 确保节点的父节点都被展开
      var current = firstFileNode;
      while (current.parentId != null) {
        final parent = allNodes.firstWhereOrNull(
          (node) => node.id == current.parentId
        );
        if (parent != null) {
          treeController.expand(parent);
          current = parent;
        } else {
          break;
        }
      }

      // 执行选中动作
      if (firstFileNode.filePath != null) {
        widget.logic.updateSelectedFile(firstFileNode);
        widget.logic.updatePdfUrl(firstFileNode.filePath!);
      }
    }
  }

  @override
  void dispose() {
    treeController.dispose();
    super.dispose();
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
      decoration: BoxDecoration(color: Colors.grey.shade50),
      child: Center(
        child: Text(
          "请点击讲义进行学习",
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
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
    final double indentLevel = entry.level * 24.0;

    return Obx(() {
      final bool isSelected = widget.logic.selectedNodeId.value == dirNode.id;
      
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (isFileNode && isLeafNode) {
            widget.logic.updateSelectedFile(dirNode);
          } else {
            treeController.toggleExpansion(entry.node);
          }
        },
        child: Container(
          color: isSelected ? Colors.red.withOpacity(0.1) : Colors.transparent,
          child: Padding(
            padding: EdgeInsets.only(left: indentLevel, top: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 24,
                  alignment: Alignment.centerLeft,
                  child: (isFileNode && isLeafNode)
                      ? Icon(
                          Icons.insert_drive_file,
                          size: 16,
                          color: Colors.red.shade400,
                        )
                      : Icon(
                          isExpanded ? Icons.remove : Icons.add,
                          size: 16,
                          color: Colors.red.shade300,
                        ),
                ),
                Expanded(
                  child: Text(
                    dirNode.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.red.shade700 : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        ),
      );
    });
  }
}
