import 'package:student_exam/app/home/view.dart';
import 'package:student_exam/app/login/view.dart';
import 'package:student_exam/common/app_data.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';


class LaunchLogic extends GetxController {

  @override
  void onInit() async {
    super.onInit();
    // 休眠3秒
    //await Future.delayed(128.ms);
    var data = await LoginData.read();
    if (data.token.isEmpty) {
      Get.off(() => LoginPage());
    }else{
      Get.off(() => HomePage());
    }
  }
}
