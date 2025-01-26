import 'package:student_exam/app/home/pages/lecture/pdf_pre_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme/theme_util.dart';
import '../../sidebar/logic.dart';
import 'file_view.dart';
import 'lecture_view.dart';
import 'logic.dart';

class LecturePage extends StatelessWidget {
  final logic = Get.put(LectureLogic());

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/lecture_page_bg.png'), // Replace with your background image path
          fit: BoxFit.fill, // Set the image fill method
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Align children to the top
              crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left
              children: [
                SizedBox(height: 110), // Optional: Add some space
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
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
          SizedBox(width: 30),
          SizedBox(
            width: 300,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Align children to the top
              crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left
              children: [
                SizedBox(height: 20), // Adjust the height as needed for spacing
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
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
          ThemeUtil.lineV(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 780,
                height: MediaQuery.of(context).size.height * 0.95,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
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