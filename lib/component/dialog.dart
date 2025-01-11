import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyDialog extends StatelessWidget {
  final String content;

  const CopyDialog({Key? key, required this.content}) : super(key: key);

  // Static method to show the dialog
  static void show(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) => CopyDialog(content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0), // Rounded corners
      ),
      child: Container(
        width: 800, // Custom width
        padding: EdgeInsets.all(20), // Inner padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with custom font and alignment
            Text(
              "全部内容",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF25B7E8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16), // Spacing

            // Content text area with scrollable view if content is long
            Container(
              constraints: BoxConstraints(maxHeight: 300),
              // Set max height for scrolling
              child: SingleChildScrollView(
                child: SelectableText(
                  content,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.left,
                  // Enable text selection within the dialog
                  showCursor: true,
                  cursorColor: Colors.blue,
                  cursorWidth: 2,
                ),
              ),
            ),
            SizedBox(height: 16), // Spacing

            // Button row with Copy and Close buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Copy button with icon
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("复制成功!")),
                    );
                  },
                  icon: Icon(Icons.copy, size: 15),
                  label: Text("复制"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF25B7E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Close button
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, size: 15),
                  label: Text("关闭"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DynamicInputDialog {
  static void show({
    required BuildContext context,
    required String title,
    required final Widget child,
    Map<String, dynamic> decorations = const {},
    required Function(Map<String, dynamic>) onSubmit,
  }) {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final Map<String, dynamic> formData = {};
    int captcha = _generateCaptcha();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFBA00),
            ),
            textAlign: TextAlign.center,
          ),
          surfaceTintColor: Colors.white,
          shadowColor: Colors.grey,
          content: SingleChildScrollView(
            child: Form(key: _formKey, child: child),
          ),
        );
      },
    );
  }

  // Generate a random captcha
  static int _generateCaptcha() {
    return Random().nextInt(9000) + 1000;
  }

  // Build captcha field widget
  static Widget _buildCaptchaField(int captcha, Map<String, dynamic> formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("验证码: $captcha", style: TextStyle(fontSize: 16)),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                captcha = _generateCaptcha();
              },
            ),
          ],
        ),
        TextFormField(
          decoration: InputDecoration(labelText: "请输入验证码"),
          validator: (value) {
            if (value != captcha.toString()) {
              return "验证码错误";
            }
            return null;
          },
          onSaved: (value) {
            formData['captcha'] = value;
          },
        ),
      ],
    );
  }
}
