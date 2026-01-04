import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/app_providers.dart';

/// 题库学习主页面 - 选择自研题库或AI题库
class SubjectBankPage extends StatelessWidget {
  const SubjectBankPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Container(
      padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(32)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '题库学习',
              style: TextStyle(
                fontSize: screenAdapter.getAdaptiveFontSize(32),
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: screenAdapter.getAdaptiveHeight(60)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOptionCard(
                  screenAdapter: screenAdapter,
                  title: '自研题库',
                  description: '精选自研题目，助你高效备考',
                  icon: Icons.library_books,
                  color: Colors.blue,
                  onTap: () {
                    // 导航到自研题库学习页面
                    Get.toNamed('/subject-bank/self-research');
                  },
                ),
                SizedBox(width: screenAdapter.getAdaptiveWidth(40)),
                _buildOptionCard(
                  screenAdapter: screenAdapter,
                  title: 'AI题库',
                  description: '智能推荐，个性化学习',
                  icon: Icons.smart_toy,
                  color: Colors.purple,
                  onTap: () {
                    // 导航到AI题库学习页面
                    Get.toNamed('/subject-bank/ai-subject');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required dynamic screenAdapter,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(16)),
      child: Container(
        width: screenAdapter.getAdaptiveWidth(300),
        height: screenAdapter.getAdaptiveHeight(250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: screenAdapter.getAdaptivePadding(10),
              offset: Offset(0, screenAdapter.getAdaptiveHeight(5)),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: screenAdapter.getAdaptiveIconSize(80),
              color: color,
            ),
            SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
            Text(
              title,
              style: TextStyle(
                fontSize: screenAdapter.getAdaptiveFontSize(24),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: screenAdapter.getAdaptiveHeight(10)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenAdapter.getAdaptivePadding(20),
              ),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenAdapter.getAdaptiveFontSize(14),
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
