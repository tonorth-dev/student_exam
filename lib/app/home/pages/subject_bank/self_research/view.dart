import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../common/app_providers.dart';
import '../../../../../component/star_rating.dart';
import 'logic.dart';

/// 专业题库学习页面（带TabBar和评分功能）
class SelfResearchPage extends StatelessWidget {
  const SelfResearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(SelfResearchLogic());
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Obx(() {
      if (logic.isCategoriesLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (logic.categories.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: screenAdapter.getAdaptiveIconSize(80),
                color: Colors.red[400],
              ),
              SizedBox(height: screenAdapter.getAdaptiveHeight(16)),
              Text(
                logic.errorMessage.value.isEmpty ? '暂无题库分类' : logic.errorMessage.value,
                style: TextStyle(
                  fontSize: screenAdapter.getAdaptiveFontSize(16),
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
              ElevatedButton.icon(
                onPressed: () => logic.loadCategories(),
                icon: Icon(Icons.refresh, size: screenAdapter.getAdaptiveIconSize(20)),
                label: Text('重试', style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(16))),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16)),
        child: Column(
          children: [
            // 顶部标题栏
            _buildHeader(screenAdapter, logic),
            SizedBox(height: screenAdapter.getAdaptiveHeight(16)),

            // TabBar
            _buildTabBar(screenAdapter, logic),
            SizedBox(height: screenAdapter.getAdaptiveHeight(16)),

            // 题目列表区域
            Expanded(
              child: _buildTabBarView(screenAdapter, logic),
            ),

            SizedBox(height: screenAdapter.getAdaptiveHeight(16)),

            // 底部分页栏
            _buildPagination(screenAdapter, logic),
          ],
        ),
      );
    });
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
                '专业题库学习',
                style: TextStyle(
                  fontSize: screenAdapter.getAdaptiveFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          Obx(() => Text(
                '共 ${logic.currentTotal} 题',
                style: TextStyle(
                  fontSize: screenAdapter.getAdaptiveFontSize(14),
                  color: Colors.grey[600],
                ),
              )),
        ],
      ),
    );
  }

  /// 构建TabBar
  Widget _buildTabBar(dynamic screenAdapter, SelfResearchLogic logic) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: screenAdapter.getAdaptivePadding(10),
            offset: Offset(0, screenAdapter.getAdaptiveHeight(2)),
          ),
        ],
      ),
      child: TabBar(
        controller: logic.tabController,
        isScrollable: true,
        labelColor: Colors.blue[700],
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blue[700],
        labelStyle: TextStyle(
          fontSize: screenAdapter.getAdaptiveFontSize(16),
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: screenAdapter.getAdaptiveFontSize(14),
        ),
        tabs: logic.categories.map((category) {
          final index = logic.categories.indexOf(category);
          return Tab(text: '题库${index + 1}');
        }).toList(),
      ),
    );
  }

  /// 构建TabBarView
  Widget _buildTabBarView(dynamic screenAdapter, SelfResearchLogic logic) {
    return TabBarView(
      controller: logic.tabController,
      children: logic.categories.map((category) {
        return _buildCategoryContent(screenAdapter, logic);
      }).toList(),
    );
  }

  /// 构建单个category的内容
  Widget _buildCategoryContent(dynamic screenAdapter, SelfResearchLogic logic) {
    return Obx(() {
      if (logic.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (logic.currentSubjects.isEmpty) {
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
              Text(
                logic.errorMessage.value.isEmpty ? '暂无题目' : logic.errorMessage.value,
                style: TextStyle(
                  fontSize: screenAdapter.getAdaptiveFontSize(16),
                  color: Colors.grey[600],
                ),
              ),
              if (logic.errorMessage.value.isNotEmpty) ...[
                SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
                ElevatedButton.icon(
                  onPressed: () => logic.refresh(),
                  icon: Icon(Icons.refresh, size: screenAdapter.getAdaptiveIconSize(20)),
                  label: Text('重试', style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(16))),
                ),
              ],
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: screenAdapter.getAdaptivePadding(10),
              offset: Offset(0, screenAdapter.getAdaptiveHeight(2)),
            ),
          ],
        ),
        child: ListView.builder(
          padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16)),
          itemCount: logic.currentSubjects.length,
          itemBuilder: (context, index) {
            final subject = logic.currentSubjects[index];
            final globalIndex = (logic.currentPage - 1) * logic.pageSize + index + 1;
            return _buildQuestion(
              screenAdapter: screenAdapter,
              logic: logic,
              subject: subject,
              index: globalIndex,
            );
          },
        ),
      );
    });
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
        margin: EdgeInsets.only(bottom: screenAdapter.getAdaptivePadding(12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(6)),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 题目标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenAdapter.getAdaptivePadding(8),
                          vertical: screenAdapter.getAdaptivePadding(4),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(4)),
                        ),
                        child: Text(
                          '第 $index 题',
                          style: TextStyle(
                            fontSize: screenAdapter.getAdaptiveFontSize(10),
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: screenAdapter.getAdaptiveWidth(8)),
                      _buildTag(screenAdapter, _getCateLabel(subject.cate), Colors.orange),
                      SizedBox(width: screenAdapter.getAdaptiveWidth(20)),
                      // 星级评分
                      StarRating(
                        rating: subject.avgRating,
                        size: screenAdapter.getAdaptiveIconSize(20),
                        onRatingChanged: (rating) {
                          logic.rateSubject(subject.id, rating);
                        },
                      ),
                    ],
                  ),

                ],
              ),
              SizedBox(height: screenAdapter.getAdaptiveHeight(10)),

              // 问题内容
              Container(
                padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(10)),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(6)),
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
                  style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(12)),
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
                    borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(6)),
                    border: Border.all(color: Colors.green[200]!, width: 1),
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
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
    return Obx(() {
      final currentPage = logic.currentPage;
      final totalPages = logic.totalPages;

      if (totalPages == 0) {
        return const SizedBox.shrink();
      }

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 上一页按钮
            ElevatedButton.icon(
              onPressed: currentPage > 1 ? () => logic.previousPage() : null,
              icon: Icon(
                Icons.chevron_left,
                size: screenAdapter.getAdaptiveIconSize(22),
              ),
              label: Text(
                '上一页',
                style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(16)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentPage > 1 ? Colors.blue : Colors.grey[300],
                foregroundColor: currentPage > 1 ? Colors.white : Colors.grey[600],
                padding: EdgeInsets.symmetric(
                  horizontal: screenAdapter.getAdaptivePadding(20),
                  vertical: screenAdapter.getAdaptivePadding(20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(8)),
                ),
              ),
            ),
            SizedBox(width: screenAdapter.getAdaptiveWidth(16)),

            // 页码显示
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenAdapter.getAdaptivePadding(20),
                vertical: screenAdapter.getAdaptivePadding(12),
              ),
              child: Text(
                '第 $currentPage 页',
                style: TextStyle(
                  fontSize: screenAdapter.getAdaptiveFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ),

            SizedBox(width: screenAdapter.getAdaptiveWidth(16)),

            // 下一页按钮
            ElevatedButton.icon(
              onPressed: currentPage < totalPages ? () => logic.nextPage() : null,
              label: Text(
                '下一页',
                style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(16)),
              ),
              icon: Icon(
                Icons.chevron_right,
                size: screenAdapter.getAdaptiveIconSize(22),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentPage < totalPages ? Colors.blue : Colors.grey[300],
                foregroundColor: currentPage < totalPages ? Colors.white : Colors.grey[600],
                padding: EdgeInsets.symmetric(
                  horizontal: screenAdapter.getAdaptivePadding(20),
                  vertical: screenAdapter.getAdaptivePadding(20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(4)),
                ),
              ),
            ),
          ],
        ),
      );
    });
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
