import 'package:get/get.dart';

import '../../../api/config_api.dart';


class ConfigLogic extends GetxController {
  static Map<String, dynamic>? ConfigData;

  Future<void> loadConfigData() async {
    try {
      final response = await ConfigApi.configList();
      if (response != null) {
        ConfigData = response;
        print("load config");
        print(ConfigData);
      } else {
        throw Exception("Failed to load config: ${response['msg'] ?? 'Unknown error'}");
      }
    } catch (e) {
      print("Failed to load config: $e");
      rethrow; // 重新抛出异常，以便在调用方捕获
    }
  }
}
