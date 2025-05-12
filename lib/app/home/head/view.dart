import 'package:student_exam/app/home/sidebar/logic.dart';
import 'package:student_exam/ex/ex_anim.dart';
import 'package:student_exam/ex/ex_list.dart';
import 'package:student_exam/state.dart';
import 'package:student_exam/theme/theme_util.dart';
import 'package:student_exam/theme/ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/app_providers.dart';
import 'logic.dart';

class HeadView extends StatefulWidget {
  @override
  _HeadViewState createState() => _HeadViewState();
}

class _HeadViewState extends State<HeadView> {
  final HeadLogic controller = Get.put(HeadLogic());
  final screenAdapter = AppProviders.instance.screenAdapter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.refreshUserData();
  }

  @override
  Widget build(BuildContext context) {
    return _head();
  }

  Widget _head() {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              ThemeUtil.width(),
              InkWell(
                  onTap: () {
                    sidebarExpanded.value = !sidebarExpanded.value;
                    sidebarShow.value = false;
                  },
                  child: const Icon(Icons.menu)),
              ThemeUtil.width(),
              _breadcrumb(),
              const Spacer(),
        Padding(
          padding: EdgeInsets.only(
              left: screenAdapter.getAdaptivePadding(10.0),
              top: screenAdapter.getAdaptivePadding(20.0),
              right: screenAdapter.getAdaptivePadding(20.0),
              bottom: screenAdapter.getAdaptivePadding(10.0)),
          child:
              InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () {
                  controller.clickHeadImage();
                },
                child: ClipOval(
                  // 圆形头像
                    child: Image.asset("assets/images/cat.jpeg",height: 42,width: 42,)),
              ),
        ),
              ThemeUtil.width(),
            ],
          ),
        ),
        ThemeUtil.lineH(),
      ],
    );
  }

  /// 面包屑组件
  Widget _breadcrumb() {
    return Obx(() {
      return Row(
        children: SidebarLogic.breadcrumbList.toWidgetsWithIndex((e, index) {
          var isLast = index != SidebarLogic.breadcrumbList.length - 1;
          var color = UiTheme.getTextColor(!isLast);
          return Row(
            children: [
              Icon(
                e.icon,
                size: 16,
                color: e.color,
              ),
              const SizedBox(width: 2,),
              Text(e.name,style: TextStyle(color:color),),
              const SizedBox(
                width: 6,
              ),
              Visibility(
                  visible: isLast,
                  child:  Icon(Icons.arrow_forward_ios,size: 12,color: color,)),
              const SizedBox(
                width: 6,
              ),
            ],
          );
        }),
      ).toFadeInWithMoveX(SidebarLogic.breadcrumbList.isNotEmpty);
    });
  }
}
