import 'package:student_exam/app/home/pages/note/pdf_pre_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../sidebar/logic.dart';
import 'note_view.dart';
import 'logic.dart';


class NotePage extends StatelessWidget {
  final logic = Get.put(NoteLogic());

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(16.0),
            child: NoteTableView(
                key: const Key("noteT_table"), title: "题本列表", logic: logic),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PdfPreView(
                key: const Key("pdf_review"), title: "文件预览"),
          ),
        ),
      ],
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "查看题本",
      icon: Icons.app_registration_outlined,
      page: NotePage(),
    );
  }
}