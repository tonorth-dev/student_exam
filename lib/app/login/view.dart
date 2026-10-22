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
  final logic = Get.put(LoginLogic(), permanent: true);

  @override
  void initState() {
    super.initState();
    logic.resetLoginFormKeepPhone();
    logic.loadPhoneInfo();
  }

  @override
  Widget build(BuildContext context) {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: screenAdapter.getAdaptiveWidth(320),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '红师教育学生端',
                  style: TextStyle(
                      fontSize: screenAdapter.getAdaptiveFontSize(32)),
                ),
                SizedBox(height: screenAdapter.getAdaptiveHeight(18)),
                textInput(logic.phoneText,
                    hintText: '请输入手机号',
                    labelText: '手机号',
                    keyboardType: TextInputType.phone),
                SizedBox(height: screenAdapter.getAdaptiveHeight(12)),
                Row(
                  children: [
                    Expanded(
                      child: textInput(logic.codeText,
                          hintText: '请输入短信验证码', labelText: '验证码'),
                    ),
                    SizedBox(width: screenAdapter.getAdaptiveWidth(10)),
                    Obx(() {
                      final canTap = logic.countdown.value == 0 &&
                          !logic.sendingSms.value;
                      final label = logic.countdown.value > 0
                          ? '${logic.countdown.value}s'
                          : (logic.sendingSms.value ? '发送中' : '获取验证码');
                      return SizedBox(
                        width: screenAdapter.getAdaptiveWidth(110),
                        height: screenAdapter.getAdaptiveHeight(48),
                        child: ElevatedButton(
                          onPressed: canTap
                              ? () => logic.onGetSmsCode(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Theme.of(context).primaryColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: screenAdapter.getAdaptiveFontSize(13),
                              color: canTap ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }),
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
                        borderRadius: BorderRadius.circular(
                            screenAdapter.getAdaptivePadding(8))),
                    child: Center(
                        child: Text(
                      '登入',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: screenAdapter.getAdaptiveFontSize(16)),
                    )),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget textInput(TextEditingController text,
      {String? hintText,
      String? labelText,
      bool password = false,
      TextInputType? keyboardType}) {
    final screenAdapter = AppProviders.instance.screenAdapter;

    return TextField(
      controller: text,
      obscureText: password,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: screenAdapter.getAdaptiveFontSize(14)),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(screenAdapter.getAdaptivePadding(4)),
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
          borderRadius:
              BorderRadius.circular(screenAdapter.getAdaptivePadding(4)),
        ),
      ),
    );
  }
}
