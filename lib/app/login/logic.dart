import 'dart:async';
import 'dart:math';

import 'package:student_exam/ex/ex_hint.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slider_captcha/slider_captcha.dart';

import '../../api/user_api.dart';
import '../../common/app_data.dart';
import '../../common/biz_type.dart';
import '../../common/app_providers.dart';
import '../../theme/ui_theme.dart';
import '../home/view.dart';

class LoginLogic extends GetxController {
  static const List<String> sliderImages = [
    'assets/images/slider/captcha_1.jpg',
    'assets/images/slider/captcha_2.jpg',
    'assets/images/slider/captcha_3.jpg',
  ];

  var phoneText = TextEditingController();
  var codeText = TextEditingController();
  final isLoggedIn = false.obs;
  final countdown = 0.obs;
  final sendingSms = false.obs;

  Timer? _countdownTimer;
  final Random _random = Random();

  @override
  void onInit() {
    super.onInit();
    loadPhoneInfo();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    // LoginLogic 为 permanent，输入框控制器长期复用，不在此处 dispose
    super.onClose();
  }

  static const String _phonePrefKey = 'student_login_phone';

  Future<void> loadPhoneInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPhone = prefs.getString(_phonePrefKey) ??
        prefs.getString('phone') ??
        prefs.getString('account');
    if (savedPhone != null && savedPhone.isNotEmpty) {
      phoneText.text = savedPhone;
    }
  }

  Future<void> savePhoneInfo(String phone) async {
    if (phone.isEmpty) {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_phonePrefKey, phone);
    await prefs.setString('phone', phone);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  String pickSliderImage() {
    return sliderImages[_random.nextInt(sliderImages.length)];
  }

  Future<void> onGetSmsCode(BuildContext context) async {
    final phone = phoneText.text.trim();
    debugPrint('[LoginLogic] 🟢 点击获取验证码 phone=$phone');
    if (!_isValidPhone(phone)) {
      debugPrint('[LoginLogic] ⚠️ 手机号格式不正确');
      '请输入正确的手机号'.toHint();
      return;
    }
    if (countdown.value > 0 || sendingSms.value) {
      debugPrint(
          '[LoginLogic] ⚠️ 发送中或倒计时中 countdown=${countdown.value} sending=${sendingSms.value}');
      return;
    }

    final passed = await showSliderCaptchaDialog(context);
    debugPrint('[LoginLogic] 🔐 滑块验证结果: $passed');
    if (passed == true) {
      await sendSms();
    }
  }

  Future<bool?> showSliderCaptchaDialog(BuildContext context) {
    final screenAdapter = AppProviders.instance.screenAdapter;
    final dialogWidth = screenAdapter.getAdaptiveWidth(420);
    final imageHeight = screenAdapter.getAdaptiveHeight(240);

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final SliderController sliderController = SliderController();
        String imagePath = pickSliderImage();
        int captchaKey = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: screenAdapter.getAdaptiveWidth(24),
                vertical: screenAdapter.getAdaptiveHeight(24),
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(screenAdapter.getAdaptivePadding(8)),
              ),
              child: SizedBox(
                width: dialogWidth,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenAdapter.getAdaptivePadding(12),
                    screenAdapter.getAdaptivePadding(8),
                    screenAdapter.getAdaptivePadding(8),
                    screenAdapter.getAdaptivePadding(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '安全验证',
                              style: TextStyle(
                                fontSize:
                                    screenAdapter.getAdaptiveFontSize(15),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: '刷新',
                            onPressed: () {
                              setState(() {
                                imagePath = pickSliderImage();
                                captchaKey++;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                sliderController.create.call();
                              });
                            },
                            icon: Icon(
                              Icons.refresh,
                              size: screenAdapter.getAdaptiveIconSize(20),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            tooltip: '关闭',
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            icon: Icon(
                              Icons.close,
                              size: screenAdapter.getAdaptiveIconSize(20),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenAdapter.getAdaptiveHeight(4)),
                      SizedBox(
                        width: dialogWidth - screenAdapter.getAdaptiveWidth(20),
                        child: SliderCaptcha(
                          key: ValueKey('slider_$captchaKey'),
                          controller: sliderController,
                          title: '拖动滑块完成拼图',
                          titleStyle: TextStyle(
                            fontSize: screenAdapter.getAdaptiveFontSize(12),
                            color: Colors.white,
                          ),
                          captchaSize: 48,
                          imageToBarPadding: 10,
                          borderImager: 4,
                          image: SizedBox(
                            width: double.infinity,
                            height: imageHeight,
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                          colorBar: UiTheme.primary(),
                          colorCaptChar: Colors.white,
                          onConfirm: (value) async {
                            if (value) {
                              Navigator.of(dialogContext).pop(true);
                            } else {
                              '验证失败，请重试'.toHint();
                              sliderController.create.call();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> sendSms() async {
    final phone = phoneText.text.trim();
    if (!_isValidPhone(phone)) {
      '请输入正确的手机号'.toHint();
      return;
    }
    if (countdown.value > 0 || sendingSms.value) {
      return;
    }

    sendingSms.value = true;
    debugPrint('[LoginLogic] 📤 开始发送短信验证码 phone=$phone');
    try {
      await UserApi.sendSms(phone);
      await savePhoneInfo(phone);
      debugPrint('[LoginLogic] ✅ 短信验证码发送成功');
      '验证码发送成功'.toHint();
      _startCountdown(60);
    } catch (e) {
      debugPrint('[LoginLogic] ❌ 短信验证码发送失败: $e');
    } finally {
      sendingSms.value = false;
    }
  }

  void _startCountdown(int seconds) {
    countdown.value = seconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value <= 1) {
        countdown.value = 0;
        timer.cancel();
      } else {
        countdown.value--;
      }
    });
  }

  void login() async {
    final phone = phoneText.text.trim();
    final code = codeText.text.trim();
    if (!_isValidPhone(phone)) {
      '请输入正确的手机号'.toHint();
      return;
    }
    if (code.isEmpty) {
      '验证码不能为空'.toHint();
      return;
    }

    debugPrint('[LoginLogic] 🚀 开始登录 phone=$phone');
    try {
      var data = await UserApi.login({
        'phone': phone,
        'code': code,
      });

      if (data['token'] != null && data['token'].toString().isNotEmpty) {
        final token = data['token'].toString();
        final tokenPreview =
            token.length <= 20 ? token : '${token.substring(0, 20)}...';
        debugPrint('[LoginLogic] ✅ 登录成功 token=$tokenPreview');
        await savePhoneInfo(phone);
        await LoginData.easySave((dg) {
          dg.token = data['token'];
          dg.user = data['user']['userName'];
          dg.code = data['user']['phone'] ?? phone;
          dg.id = int.parse(data['user']['email']);
          dg.classId = data['user']['classId'] ?? 0;
          dg.bizType = BizType.normalize(data['user']['bizType']);
        });
        isLoggedIn.value = true;
        Get.off(() => HomePage());
      } else {
        debugPrint('[LoginLogic] ❌ 登录失败: token为空 data=$data');
        "登录失败".toHint();
      }
    } catch (e) {
      debugPrint('[LoginLogic] ❌ 登录异常: $e');
      "登录失败：${e.toString()}".toHint();
    }
  }

  /// 退出后回到登录页：保留手机号，清空验证码与倒计时
  void resetLoginFormKeepPhone() {
    codeText.clear();
    _countdownTimer?.cancel();
    countdown.value = 0;
    sendingSms.value = false;
  }

  void logout() {
    LoginData.easySave((p0) {
      p0.token = "";
      p0.role = "";
      p0.user = "";
      p0.bizType = BizType.militaryCivilian;
    });
    isLoggedIn.value = false;
    resetLoginFormKeepPhone();
  }
}
