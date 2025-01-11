import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/ui_theme.dart';
import 'logic.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final logic = Get.put(LoginLogic());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '红师教育登录入口',
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(height: 18),
              Obx(() => DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: '选择角色',
                  border: OutlineInputBorder(),
                ),
                value: logic.selectedRole.value,
                onChanged: (String? newValue) {
                  logic.selectedRole.value = newValue!;
                },
                items: <String>['超级管理员', '题库管理', '考生管理', '岗位管理', '讲义和心理管理']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              )),
              SizedBox(height: 10),
              textInput(logic.accountText, hintText: '请输入账号', labelText: '账号'),
              SizedBox(height: 10),
              textInput(logic.passwordText,
                  hintText: '请输入密码', labelText: '密码', password: true),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: textInput(logic.captchaText,
                        hintText: '请输入验证码', labelText: '验证码'),
                  ),
                  SizedBox(width: 10),
                  InkWell(
                    onTap: logic.fetchCaptcha,
                    child: Obx(() {
                      if (logic.captchaImageUrl.value.isNotEmpty) {
                        // 如果是 Base64 编码的图片，使用 Image.memory 解析
                        if (logic.captchaImageUrl.value.startsWith('data:image/png;base64,')) {
                          return Image.memory(
                            logic.base64ToImage(logic.captchaImageUrl.value),
                            width: 100,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          );
                        } else {
                          // 否则，尝试使用 Image.network 加载图片
                          return Image.network(
                            logic.captchaImageUrl.value,
                            width: 100,
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error);
                            },
                          );
                        }
                      } else {
                        return const Icon(Icons.error);
                      }
                    }),
                  )
                ],
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () {
                  logic.login();
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                      child: Text(
                        '登入',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
    return TextField(
      controller: text,
      obscureText: password,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
        hintText: hintText,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 2,
            color: UiTheme.primary(),
          ),
        ),
      ),
    );
  }
}
