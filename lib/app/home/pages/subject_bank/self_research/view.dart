import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common/app_providers.dart';
import 'logic.dart';

/// 自研题库学习页面
class SelfResearchPage extends StatelessWidget {
  const SelfResearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(SelfResearchLogic());
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Container(
      padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16)),
      child: Column(
        children: [
          // 顶部标题栏
          _buildHeader(screenAdapter, logic),
          SizedBox(height: screenAdapter.getAdaptiveHeight(16)),

          // 题目列表区域
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  screenAdapter.getAdaptivePadding(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: screenAdapter.getAdaptivePadding(10),
                    offset: Offset(0, screenAdapter.getAdaptiveHeight(2)),
                  ),
                ],
              ),
              child: Obx(() {
                if (logic.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (logic.subjects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          logic.errorMessage.value.isEmpty
                              ? Icons.assignment_outlined
                              : Icons.error_outline,
                          size: screenAdapter.getAdaptiveIconSize(80),
                          color: logic.errorMessage.value.isEmpty
                              ? Colors.grey[400]
                              : Colors.red[400],
                        ),
                        SizedBox(height: screenAdapter.getAdaptiveHeight(16)),
                        if (logic.errorMessage.value.isEmpty) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '暂无题目',
                                style: TextStyle(
                                  fontSize: screenAdapter.getAdaptiveFontSize(16),
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: screenAdapter.getAdaptiveWidth(4)),
                              IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  size: screenAdapter.getAdaptiveIconSize(24),
                                ),
                                onPressed: () => logic.refresh(),
                                tooltip: '刷新题目',
                              ),
                            ]
                          )
                        ] else ...[
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenAdapter.getAdaptivePadding(40),
                            ),
                            child: Text(
                              logic.errorMessage.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenAdapter.getAdaptiveFontSize(14),
                                color: Colors.red[600],
                              ),
                            ),
                          ),
                          SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
                          ElevatedButton.icon(
                            onPressed: () => logic.refresh(),
                            icon: Icon(
                              Icons.refresh,
                              size: screenAdapter.getAdaptiveIconSize(20),
                            ),
                            label: Text(
                              '重试',
                              style: TextStyle(
                                fontSize: screenAdapter.getAdaptiveFontSize(16),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenAdapter.getAdaptivePadding(32),
                                vertical: screenAdapter.getAdaptivePadding(12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16)),
                  itemCount: logic.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = logic.subjects[index];
                    return _buildQuestion(
                      screenAdapter: screenAdapter,
                      logic: logic,
                      subject: subject,
                      index: index,
                    );
                  },
                );
              }),
            ),
          ),

          SizedBox(height: screenAdapter.getAdaptiveHeight(16)),

          // 底部分页栏
          _buildPagination(screenAdapter, logic),
        ],
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildHeader(dynamic screenAdapter, SelfResearchLogic logic) {
    return Container(
      padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16)),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.library_books,
                size: screenAdapter.getAdaptiveIconSize(28),
                color: Colors.blue[700],
              ),
              SizedBox(width: screenAdapter.getAdaptiveWidth(12)),
              Text(
                '自研题库学习',
                style: TextStyle(
                  fontSize: screenAdapter.getAdaptiveFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Obx(() => Text(
                    '共 ${logic.total.value} 题',
                    style: TextStyle(
                      fontSize: screenAdapter.getAdaptiveFontSize(14),
                      color: Colors.grey[600],
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建单个题目卡片
  Widget _buildQuestion({
    required dynamic screenAdapter,
    required SelfResearchLogic logic,
    required SubjectModel subject,
    required int index,
  }) {
    return Obx(() {
      final isExpanded = logic.expandedAnswers.contains(subject.id);

      return Container(
        margin: EdgeInsets.only(
          bottom: screenAdapter.getAdaptivePadding(12),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            screenAdapter.getAdaptivePadding(6),
          ),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 题目标题行
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenAdapter.getAdaptivePadding(8),
                      vertical: screenAdapter.getAdaptivePadding(4),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(
                        screenAdapter.getAdaptivePadding(4),
                      ),
                    ),
                    child: Text(
                      '第 ${index + 1} 题',
                      style: TextStyle(
                        fontSize: screenAdapter.getAdaptiveFontSize(10),
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: screenAdapter.getAdaptiveWidth(8)),
                  _buildTag(screenAdapter, _getCateLabel(subject.cate), Colors.orange),
                  SizedBox(width: screenAdapter.getAdaptiveWidth(8)),
                  _buildTag(screenAdapter, _getLevelLabel(subject.level), Colors.purple),
                ],
              ),
              SizedBox(height: screenAdapter.getAdaptiveHeight(10)),

              // 问题内容
              Container(
                padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(10)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(
                    screenAdapter.getAdaptivePadding(6),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: screenAdapter.getAdaptiveIconSize(20),
                      color: Colors.blue[600],
                    ),
                    SizedBox(width: screenAdapter.getAdaptiveWidth(10)),
                    Expanded(
                      child: Text(
                        subject.title,
                        style: TextStyle(
                          fontSize: screenAdapter.getAdaptiveFontSize(14),
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenAdapter.getAdaptiveHeight(10)),

              // 显示答案按钮
              ElevatedButton.icon(
                onPressed: () => logic.toggleAnswer(subject.id),
                icon: Icon(
                  isExpanded ? Icons.visibility_off : Icons.visibility,
                  size: screenAdapter.getAdaptiveIconSize(16),
                ),
                label: Text(
                  isExpanded ? '隐藏答案' : '显示答案',
                  style: TextStyle(
                    fontSize: screenAdapter.getAdaptiveFontSize(12),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpanded ? Colors.grey[400] : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenAdapter.getAdaptivePadding(12),
                    vertical: screenAdapter.getAdaptivePadding(6),
                  ),
                ),
              ),

              // 答案内容（展开时显示）
              if (isExpanded) ...[
                SizedBox(height: screenAdapter.getAdaptiveHeight(10)),
                Container(
                  padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(10)),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(
                      screenAdapter.getAdaptivePadding(6),
                    ),
                    border: Border.all(
                      color: Colors.green[200]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: screenAdapter.getAdaptiveIconSize(20),
                        color: Colors.green[600],
                      ),
                      SizedBox(width: screenAdapter.getAdaptiveWidth(10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '参考答案：',
                              style: TextStyle(
                                fontSize: screenAdapter.getAdaptiveFontSize(12),
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            SizedBox(height: screenAdapter.getAdaptiveHeight(4)),
                            Text(
                              subject.answer,
                              style: TextStyle(
                                fontSize: screenAdapter.getAdaptiveFontSize(13),
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  /// 构建标签
  Widget _buildTag(dynamic screenAdapter, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenAdapter.getAdaptivePadding(6),
        vertical: screenAdapter.getAdaptivePadding(2),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(4)),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: screenAdapter.getAdaptiveFontSize(9),
          color: color.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// 构建分页栏
  Widget _buildPagination(dynamic screenAdapter, SelfResearchLogic logic) {
    return Container(
      padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenAdapter.getAdaptivePadding(10),
            offset: Offset(0, screenAdapter.getAdaptiveHeight(2)),
          ),
        ],
      ),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () => logic.refresh(),
          icon: Icon(
            Icons.refresh,
            size: screenAdapter.getAdaptiveIconSize(20),
          ),
          label: Text(
            '换一换',
            style: TextStyle(
              fontSize: screenAdapter.getAdaptiveFontSize(16),
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: screenAdapter.getAdaptivePadding(40),
              vertical: screenAdapter.getAdaptivePadding(16),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  /// 获取题型类别标签
  String _getCateLabel(String cate) {
    const Map<String, String> cateMap = {
      'fit_ability': '适岗能力',
      'professional': '专业知识',
      'motivation': '求职动机',
      'operation': '专业实操',
    };
    return cateMap[cate] ?? cate;
  }

  /// 获取难度等级标签
  String _getLevelLabel(String level) {
    const Map<String, String> levelMap = {
      'simple': '简单',
      'middle': '中等',
      'difficulty': '困难',
      'real': '真题',
    };
    return levelMap[level] ?? level;
  }
}
