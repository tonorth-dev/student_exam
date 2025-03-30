import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/ui_theme.dart';
import '../../common/app_providers.dart';
import 'logic.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final logic = Get.put(LoginLogic());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 使用 addPostFrameCallback 确保在构建完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logic.fetchCaptcha();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: screenAdapter.getAdaptiveWidth(300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '红师教育学生端',
                style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(32)),
              ),
              SizedBox(height: screenAdapter.getAdaptiveHeight(18)),
              textInput(logic.passwordText,
                  hintText: '请输入密码', labelText: '输入密码', password: true),
              SizedBox(height: screenAdapter.getAdaptiveHeight(10)),
              Row(
                children: [
                  Expanded(
                    child: textInput(logic.captchaText,
                        hintText: '请输入验证码', labelText: '验证码'),
                  ),
                  SizedBox(width: screenAdapter.getAdaptiveWidth(10)),
                  InkWell(
                    onTap: logic.fetchCaptcha,
                    child: Obx(() {
                      if (logic.captchaImageUrl.value.isNotEmpty) {
                        // 如果是 Base64 编码的图片，使用 Image.memory 解析
                        if (logic.captchaImageUrl.value.startsWith('data:image/png;base64,')) {
                          return Image.memory(
                            logic.base64ToImage(logic.captchaImageUrl.value),
                            width: screenAdapter.getAdaptiveWidth(100),
                            height: screenAdapter.getAdaptiveHeight(40),
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.error,
                                size: screenAdapter.getAdaptiveIconSize(24),
                              );
                            },
                          );
                        } else {
                          // 否则，尝试使用 Image.network 加载图片
                          return Image.network(
                            logic.captchaImageUrl.value,
                            width: screenAdapter.getAdaptiveWidth(100),
                            height: screenAdapter.getAdaptiveHeight(40),
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.error,
                                size: screenAdapter.getAdaptiveIconSize(24),
                              );
                            },
                          );
                        }
                      } else {
                        return Icon(
                          Icons.error,
                          size: screenAdapter.getAdaptiveIconSize(24),
                        );
                      }
                    }),
                  )
                ],
              ),
              SizedBox(height: screenAdapter.getAdaptiveHeight(20)),
              InkWell(
                onTap: () {
                  logic.login();
                },
                child: Container(
                  width: double.infinity,
                  height: screenAdapter.getAdaptiveHeight(50),
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(8))),
                  child: Center(
                      child: Text(
                        '登入',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: screenAdapter.getAdaptiveFontSize(16)
                        ),
                      )),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget textInput(TextEditingController text,
      {String? hintText, String? labelText, bool password = false}) {
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    return TextField(
      controller: text,
      obscureText: password,
      style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(4)),
        ),
        labelText: labelText,
        labelStyle: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
        hintText: hintText,
        hintStyle: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenAdapter.getAdaptivePadding(12),
          vertical: screenAdapter.getAdaptivePadding(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: screenAdapter.getAdaptiveWidth(2),
            color: UiTheme.primary(),
          ),
          borderRadius: BorderRadius.circular(screenAdapter.getAdaptivePadding(4)),
        ),
      ),
    );
  }
}
