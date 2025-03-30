import 'package:student_exam/app/home/pages/lecture/pdf_pre_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/theme_util.dart';
import '../../../../common/app_providers.dart';
import '../../sidebar/logic.dart';
import 'file_view.dart';
import 'lecture_view.dart';
import 'logic.dart';

class LecturePage extends StatelessWidget {
  final logic = Get.put(LectureLogic());
  // 获取 screenAdapter 实例
  final screenAdapter = AppProviders.instance.screenAdapter;

  LecturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/lecture_page_bg.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: screenAdapter.getAdaptiveWidth(300),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenAdapter.getAdaptiveHeight(110)),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16.0)),
                    child: LectureTableView(
                      key: const Key("lectureT_table"),
                      title: "讲义列表",
                      logic: logic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: screenAdapter.getAdaptiveWidth(30)),
          SizedBox(
            width: screenAdapter.getAdaptiveWidth(260),
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16.0)),
                    child: LectureFileView(
                      key: const Key("file_table"),
                      title: "文件管理",
                      logic: logic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: screenAdapter.getAdaptivePadding(0),
              right: screenAdapter.getAdaptivePadding(0),
              top: screenAdapter.getAdaptivePadding(0),
              bottom: screenAdapter.getAdaptivePadding(13)
            ),
            height: screenAdapter.getAdaptiveHeight(742),
            child: ThemeUtil.lineVC(width: screenAdapter.getAdaptiveWidth(10)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: screenAdapter.getAdaptiveWidth(820),
                height: MediaQuery.of(context).size.height * 0.95,
                child: Container(
                  padding: EdgeInsets.all(screenAdapter.getAdaptivePadding(16.0)),
                  child: PdfPreView(
                    key: const Key("pdf_review"),
                    title: "文件预览",
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "讲义学习",
      icon: Icons.menu_book_outlined,
      page: LecturePage(),
    );
  }
}