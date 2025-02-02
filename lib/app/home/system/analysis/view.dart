import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_exam/app/home/pages/psyc/view.dart';
import 'package:student_exam/ex/ex_list.dart';
import '../../../../theme/theme_util.dart';
import '../../pages/exam/view.dart';
import '../../pages/lecture/view.dart';
import '../../sidebar/logic.dart';
import '../../tab_bar/logic.dart';
import 'logic.dart';

class AnalysisPage extends StatelessWidget {
  final logic = Get.put(AnalysisLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ThemeUtil.height(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FeatureSection(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "数据分析",
      icon: Icons.analytics,
      page: AnalysisPage(),
    );
  }
}

class FeatureSection extends StatelessWidget {
  final sideLogic = Get.put(TabBarLogic());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height:100),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFeatureCard(
                      title: '面试模拟',
                      subtitle: '智能模拟面试\n提升面试技巧',
                      color: Colors.red,
                      icon: Icons.person_outline,
                      onTap: () => TabBarLogic.addPage(ExamPage.newThis()),
                      backgroundImage: 'assets/images/home_exam_pg.png',
                    ),
                    const SizedBox(width: 100),
                    _buildFeatureCard(
                      title: '讲义学习',
                      subtitle: '系统化学习\n提升专业能力',
                      color: Colors.blue,
                      icon: Icons.menu_book_outlined,
                      onTap: () => TabBarLogic.addPage(LecturePage.newThis()),
                      backgroundImage: 'assets/images/home_lecture_pg.png',
                    ),
                    const SizedBox(width: 100),
                    _buildFeatureCard(
                      title: '心理测试',
                      subtitle: '了解自我\n职业规划指导',
                      color: Colors.purple,
                      icon: Icons.psychology_outlined,
                      onTap: () => TabBarLogic.addPage(PsychologyPage.newThis()),
                      backgroundImage: 'assets/images/home_psychology_pg.png',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required String backgroundImage,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 275,
            height: 289.63,
            child: Stack(
              children: [
                // 背景图片
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      backgroundImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
                // 背景渐变
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.73, -0.68),
                        end: const Alignment(0.73, 0.68),
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // 标题和副标题
                Positioned(
                  left: 25,
                  top: 112,
                  child: Container(
                    width: 225,
                    height: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            height: 1.2,
                            fontFamily: 'PingFang SC',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: 16,
                            height: 1.4,
                            fontFamily: 'PingFang SC',
                            fontWeight: FontWeight.w300,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // 彩色条
                Positioned(
                  left: 24,
                  top: 70,
                  child: Container(
                    width: 97.86,
                    height: 6.75,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // 左上角徽章
                Positioned(
                  left: 24,
                  top: 0,
                  child: _buildBadge(color),
                ),
                // 图标
                Positioned(
                  left: 81,
                  top: 28,
                  child: _buildIcon(icon, color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(Color color) {
    return Container(
      width: 81.48,
      height: 59.26,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.83, -0.56),
          end: const Alignment(-0.83, 0.56),
          colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
        ),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }
}