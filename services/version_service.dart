import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:student_exam/api/version_api.dart';
import 'package:student_exam/models/version_info.dart';
import 'package:flutter/foundation.dart';

class VersionService {
  final VersionApi _api = VersionApi();

  Future<VersionInfo?> checkForUpdates() async {
    try {
      final currentVersion = await _getCurrentVersion();
      final response = await VersionApi.checkVersion();
      final latestVersion = VersionInfo.fromJson(response, Platform.isMacOS);
      
      // 如果不需要更新，返回 null
      if (!_compareVersions(currentVersion, latestVersion.version)) {
        return null;
      }
      return latestVersion;
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return null;
    }
  }

  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  bool _compareVersions(String currentVersion, String latestVersion) {
    // 移除版本号中的 'v' 前缀
    currentVersion = currentVersion.replaceAll('v', '');
    latestVersion = latestVersion.replaceAll('v', '');

    final current = currentVersion.split('.');
    final latest = latestVersion.split('.');

    // 确保两个版本号都有三个部分
    while (current.length < 3) current.add('0');
    while (latest.length < 3) latest.add('0');

    for (var i = 0; i < 3; i++) {
      final currentNum = int.parse(current[i]);
      final latestNum = int.parse(latest[i]);
      
      if (latestNum > currentNum) {
        return true;
      } else if (latestNum < currentNum) {
        return false;
      }
    }
    // 如果所有部分都相等，说明版本相同，不需要更新
    return false;
  }
} 