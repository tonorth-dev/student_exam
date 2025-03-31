import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/app_providers.dart';
import '../../head/logic.dart';

class CommonAppBar {
  static PreferredSizeWidget buildExamAppBar() {
    final headerLogic = Get.find<HeadLogic>();
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    return PreferredSize(
      preferredSize: Size.fromHeight(screenAdapter.getAdaptiveHeight(80)),
      child: AppBar(
        title: const Text(''),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: FlexibleSpaceBar(
          background: Image.asset(
            'assets/images/exam_banner_logo.png',
            fit: BoxFit.fill,
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: screenAdapter.getAdaptivePadding(16.0)),
              child: InkWell(
                borderRadius: BorderRadius.circular(screenAdapter.getAdaptiveWidth(32)),
                onTap: () {
                  headerLogic.clickHeadImage();
                },
                child: ClipOval(
                  child: Image.asset(
                    "assets/images/cat.jpeg",
                    height: screenAdapter.getAdaptiveHeight(42),
                    width: screenAdapter.getAdaptiveWidth(42),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 这里可以添加其他类型的 AppBar，例如：
  // static PreferredSizeWidget buildLectureAppBar() { ... }
  // static PreferredSizeWidget buildNoteAppBar() { ... }
} 