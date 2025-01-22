import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        Container(
          width: 885,
          height: 310.81,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildFeatureCard(
                '面试模拟', 
                '智能模拟面试\n提升面试技巧', 
                Colors.red,
                Icons.person_outline,
                () => sideLogic.tabList.toWidgetsWithIndex((_, index) => ExamPage()),
              ),
              SizedBox(width: 30),
              _buildFeatureCard(
                '讲义学习', 
                '系统化学习\n提升专业能力', 
                Colors.blue,
                Icons.menu_book_outlined,
                () => sideLogic.tabList.toWidgetsWithIndex((_, index) => LecturePage()),
              ),
              SizedBox(width: 30),
              _buildFeatureCard(
                '心理测试', 
                '了解自我\n职业规划指导', 
                Colors.purple,
                Icons.psychology_outlined,
                () => sideLogic.tabList.toWidgetsWithIndex((_, index) => LecturePage()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title, 
    String subtitle, 
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    // 根据标题选择对应的背景图
    String backgroundImage = title == '面试模拟' 
        ? 'assets/images/home_exam_bg.png'
        : title == '讲义学习'
            ? 'assets/images/home_lecture_bg.png'
            : 'assets/images/home_psychology_bg.png';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 275,
        height: 289.63,
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  backgroundImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.73, -0.68),
                    end: Alignment(0.73, 0.68),
                    colors: [
                      Colors.white.withOpacity(0.9),  // 增加不透明度以确保文字可读
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.1)),
                ),
              ),
            ),
            // Title and Subtitle
            Positioned(
              left: 25,
              top: 112,
              child: Container(
                width: 162,
                height: 102,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontFamily: 'PingFang SC',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontSize: 18,
                        fontFamily: 'PingFang SC',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Colored Bar
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
            // Top-left badge
            Positioned(
              left: 24,
              top: 0,
              child: _buildBadge(color),
            ),
            // Icon
            Positioned(
              left: 81,
              top: 28,
              child: _buildIcon(icon, color),
            ),
          ],
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
          begin: Alignment(0.83, -0.56),
          end: Alignment(-0.83, 0.56),
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
            offset: Offset(0, 4),
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