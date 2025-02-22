import 'dart:convert'; // For base64Decode
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;

// 常量定义
const String encryptionKeyBase64 = 'E/ZlVum4KDMuHSmAPsClWlQfhpqLcGgfeCe0QUZwmoE=';
const String encryptionIVBase64 = 'cJqeex1SKESDkkc4mz+nLg==';

class EncryptionUtil {
  // 使用常量初始化密钥和IV
  static final _key = encrypt.Key.fromBase64(encryptionKeyBase64);
  static final _iv = encrypt.IV.fromBase64(encryptionIVBase64);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  /// 加密字节数据
  static Uint8List encryptBytes(Uint8List bytes) {
    final encrypted = _encrypter.encryptBytes(bytes, iv: _iv);
    return encrypted.bytes;
  }

  /// 解密字节数据
  static Uint8List decryptBytes(Uint8List bytes) {
    final encrypted = encrypt.Encrypted(bytes);
    return Uint8List.fromList(_encrypter.decryptBytes(encrypted, iv: _iv));
  }
}