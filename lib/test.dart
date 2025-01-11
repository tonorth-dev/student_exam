import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:encrypt/encrypt.dart';

/// 原始密钥（Base64 格式）
const String originalKeyBase64 = "qaznMpx3SULVO5ag8tRUlGUAMoo0AK5ylgQPx5RB7Jg=";

/// XOR 两个 Uint8List 的内容
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

/// 将密钥分成 K1 和 K2
Map<String, String> splitKey(String base64Key) {
  final keyBytes = base64Decode(base64Key);
  final random = Random.secure();

  // 生成随机 K2
  final k2 = List<int>.generate(keyBytes.length, (_) => random.nextInt(256));
  final k2Bytes = Uint8List.fromList(k2);

  // 计算 K1 = 原始密钥 XOR K2
  final k1Bytes = xor(Uint8List.fromList(keyBytes), k2Bytes);

  // 返回分割后的 Base64 格式 K1 和 K2
  return {
    'K1': base64Encode(k1Bytes),
    'K2': base64Encode(k2Bytes),
  };
}

/// 通过 K1 和 K2 组合密钥
Uint8List combineKey(String base64K1, String base64K2) {
  final k1Bytes = base64Decode(base64K1);
  final k2Bytes = base64Decode(base64K2);
  return xor(k1Bytes, k2Bytes);
}

/// AES-256 加密
String encryptAES256(String plainText, Uint8List keyBytes) {
  final key = Key(keyBytes);
  final iv = IV.fromLength(16); // 随机生成 IV
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

  final encrypted = encrypter.encrypt(plainText, iv: iv);
  final ivAndCipherText = iv.bytes + encrypted.bytes; // 拼接 IV 和密文
  return base64Encode(ivAndCipherText); // Base64 编码
}

/// AES-256 解密
String decryptAES256(String cipherTextBase64, Uint8List keyBytes) {
  final key = Key(keyBytes);
  final ivAndCipherText = base64Decode(cipherTextBase64);

  if (ivAndCipherText.length < 16) {
    throw ArgumentError('Cipher text is too short');
  }

  final iv = IV(ivAndCipherText.sublist(0, 16)); // 提取 IV
  final cipherText = ivAndCipherText.sublist(16); // 提取密文

  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  return encrypter.decrypt(Encrypted(cipherText), iv: iv);
}

void main() {
  // === 初始密钥分割 ===
  final splitKeys = splitKey(originalKeyBase64);
  final k1 = "C0EmZ/HCluK188v3mH1anKurLsheOzDl0nGdCY1lWLA=";
  final k2 = "ou3BVW2136BgyF1XaqkOCM6rHEJqO56XRHWSzhkktCg=";

  print('K1 (Client-Side): $k1');
  print('K2 (Server-Side): $k2');

  // 模拟客户端从服务端获取 K2，组合密钥
  final combinedKey = combineKey(k1, k2);
  print('Combined Key: ${base64Encode(combinedKey)}');

  // === 加密过程 ===
  final plainText = 'Hello, this is a secure message!';
  final cipherText = encryptAES256(plainText, combinedKey);
  print('Encrypted Text: $cipherText');

  // === 解密过程 ===
  final decryptedText = decryptAES256(cipherText, combinedKey);
  print('Decrypted Text: $decryptedText');

  // === 模拟缓存 K2 后减少请求 ===
  final cachedK2 = k2; // 假设客户端缓存了 K2
  final cachedCombinedKey = combineKey(k1, cachedK2);
  final decryptedWithCachedKey = decryptAES256(cipherText, cachedCombinedKey);
  print('Decrypted with Cached K2: $decryptedWithCachedKey');
}
