import 'dart:convert'; // For base64Decode
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../api/config_api.dart';

// 常量定义（用于 PDF 文件加密）
const String encryptionKeyBase64 = 'E/ZlVum4KDMuHSmAPsClWlQfhpqLcGgfeCe0QUZwmoE=';
const String encryptionIVBase64 = 'cJqeex1SKESDkkc4mz+nLg==';

class EncryptionUtil {
  // K1 常量（用于题目加密）
  static const String k1 = "C0EmZ/HCluK188v3mH1anKurLsheOzDl0nGdCY1lWLA=";
  static const int defaultCacheDurationInMinutes = 10080;

  // 使用常量初始化密钥和IV（用于 PDF 文件）
  static final _key = encrypt.Key.fromBase64(encryptionKeyBase64);
  static final _iv = encrypt.IV.fromBase64(encryptionIVBase64);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  static final EncryptionUtil _instance = EncryptionUtil._internal();

  factory EncryptionUtil() {
    return _instance;
  }

  EncryptionUtil._internal();

  /// 加密字节数据（用于 PDF 文件）
  static Uint8List encryptBytes(Uint8List bytes) {
    final encrypted = _encrypter.encryptBytes(bytes, iv: _iv);
    return encrypted.bytes;
  }

  /// 解密字节数据（用于 PDF 文件）
  static Uint8List decryptBytes(Uint8List bytes) {
    final encrypted = encrypt.Encrypted(bytes);
    return Uint8List.fromList(_encrypter.decryptBytes(encrypted, iv: _iv));
  }

  // ========== 以下为题目加密/解密相关方法 ==========

  /// 从服务端获取 K2
  Future<String> fetchK2FromServer() async {
    try {
      final data = await ConfigApi.configEncr();
      final serverKey = data["server_key"];
      if (serverKey != null && serverKey is String) {
        return serverKey;
      } else {
        throw Exception('Failed to fetch K2: Invalid response format');
      }
    } catch (e) {
      throw Exception('Error fetching K2: $e');
    }
  }

  Future<void> cacheK2(String k2, {int cacheDurationInMinutes = defaultCacheDurationInMinutes}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedK2', k2);
    final expirationTimestamp = DateTime.now().millisecondsSinceEpoch + cacheDurationInMinutes * 60 * 1000;
    await prefs.setInt('k2CacheExpirationTimestamp', expirationTimestamp);
  }

  /// 从缓存中获取 K2
  Future<String?> getCachedK2() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedK2 = prefs.getString('cachedK2');
    final cacheExpirationTimestamp = prefs.getInt('k2CacheExpirationTimestamp');

    if (cachedK2 != null && cacheExpirationTimestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now <= cacheExpirationTimestamp) {
        return cachedK2;
      }
    }

    return null; // 缓存过期或不存在
  }

  Future<String> getK2({int cacheDurationInMinutes = defaultCacheDurationInMinutes}) async {
    final cachedK2 = await getCachedK2();

    if (cachedK2 != null) {
      return cachedK2;
    }

    debugPrint('Fetching K2 from server');
    final k2 = await fetchK2FromServer();
    await cacheK2(k2, cacheDurationInMinutes: cacheDurationInMinutes);
    return k2;
  }

  Uint8List xor(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      throw ArgumentError('Lists must have the same length for XOR');
    }
    final result = Uint8List(a.length);
    for (int i = 0; i < a.length; i++) {
      result[i] = a[i] ^ b[i];
    }
    return result;
  }

  /// 通过 K1 和 K2 组合密钥
  Uint8List combineKey(String base64K1, String base64K2) {
    final k1Bytes = base64Decode(base64K1);
    final k2Bytes = base64Decode(base64K2);
    return xor(k1Bytes, k2Bytes);
  }

  /// AES-256 加密（用于题目）
  static Future<String> encryptAES256(String plainText) async {
    final encryptionUtil = EncryptionUtil();
    final k2 = await encryptionUtil.getK2();
    final combinedKey = encryptionUtil.combineKey(k1, k2);
    final keyBytes = combinedKey;
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV.fromLength(16); // 随机生成 IV
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final ivAndCipherText = iv.bytes + encrypted.bytes; // 拼接 IV 和密文
    return base64Encode(ivAndCipherText); // Base64 编码
  }

  /// AES-256 解密（用于题目）
  static Future<String> decryptAES256(String cipherTextBase64) async {
    final encryptionUtil = EncryptionUtil();
    final k2 = await encryptionUtil.getK2();
    final combinedKey = encryptionUtil.combineKey(k1, k2);
    final keyBytes = combinedKey;
    final key = encrypt.Key(keyBytes);
    final ivAndCipherText = base64Decode(cipherTextBase64);

    if (ivAndCipherText.length < 16) {
      throw ArgumentError('Cipher text is too short');
    }

    final iv = encrypt.IV(ivAndCipherText.sublist(0, 16)); // 提取 IV
    final cipherText = ivAndCipherText.sublist(16); // 提取密文

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt(encrypt.Encrypted(cipherText), iv: iv);
  }
}
