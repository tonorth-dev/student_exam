import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

extension ExHint on String {
  /// 提示，默认带有一个信息图标
  void toHint() {
    BotToast.showCustomText(
      duration: Duration(seconds: 2), // 设置停留时间为2秒
      onlyOne: true, // 确保同一时间只显示一个提示
      toastBuilder: (close) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75), // 半透明黑色背景
            borderRadius: BorderRadius.circular(8), // 圆角边框
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 10,
                offset: Offset(0, 3), // 阴影位置
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 26, horizontal: 36), // 调整内边距
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline, // 默认使用信息图标
                size: 24,
                color: Colors.white,
              ),
              SizedBox(width: 12), // 图标和文本之间的间距
              Flexible(
                child: Text(
                  this,
                  style: TextStyle(
                    fontSize: 18, // 调整字体大小
                    fontFamily: 'PingFang SC',
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // 限制最大行数以避免过长文本溢出
                  overflow: TextOverflow.ellipsis, // 多余文字用省略号表示
                ),
              ),
            ],
          ),
        );
      },
      align: Alignment.center, // 垂直居中
    );
  }
}