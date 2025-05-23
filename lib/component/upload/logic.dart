import 'dart:typed_data';

import 'package:student_exam/common/http_util.dart';
import 'package:student_exam/common/image_util.dart';
import 'package:student_exam/ex/ex_hint.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';


class UploadLogic extends GetxController {

  var imageList = <String>[].obs;
  var testMode = true;
  XTypeGroup? type;
  bool multiple = false;
  int limit = 1;

  void selectFile() async {
    var list = await ImageUtil.selectFile(type: type);
    var bySum = 0;
    if (list.isNotEmpty) {
      for (var el in list) {
        if (imageList.length >= limit) {
          "超过最大上传数量".toHint();
          break;
        }
        var byList = await el.readAsBytes();
        bySum += byList.length;
        // 测试模式可以不上传预览
        if (testMode) {
          imageList.add(el.path);
        } else {
          var fileUrl = await fileUpload(byList, el.name);
          imageList.add(fileUrl);
        }
      }
    }
    debugPrint("总大小:${bySum / 1024 / 1024}M");
  }

  static Future<dynamic> fileUpload(Uint8List fromBytes, String name) async {
    return await HttpUtil.uploadByte("/file/upload", fromBytes, name);
  }
}
