import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screen_adapter.dart';
import '../main.dart' show screenAdapter;

class AdaptiveLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final BoxDecoration? decoration;

  const AdaptiveLayout({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.backgroundColor,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        width: width != null ? screenAdapter.getAdaptiveWidth(width!) : null,
        height: height != null ? screenAdapter.getAdaptiveHeight(height!) : null,
        padding: padding != null
            ? EdgeInsets.only(
                left: screenAdapter.getAdaptivePadding(padding!.left),
                top: screenAdapter.getAdaptivePadding(padding!.top),
                right: screenAdapter.getAdaptivePadding(padding!.right),
                bottom: screenAdapter.getAdaptivePadding(padding!.bottom),
              )
            : null,
        margin: margin != null
            ? EdgeInsets.only(
                left: screenAdapter.getAdaptivePadding(margin!.left),
                top: screenAdapter.getAdaptivePadding(margin!.top),
                right: screenAdapter.getAdaptivePadding(margin!.right),
                bottom: screenAdapter.getAdaptivePadding(margin!.bottom),
              )
            : null,
        decoration: decoration,
        color: backgroundColor,
        child: child,
      );
    });
  }
}

class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AdaptiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final adaptedStyle = style?.copyWith(
        fontSize: style?.fontSize != null
            ? screenAdapter.getAdaptiveFontSize(style!.fontSize!)
            : null,
      );

      return Text(
        text,
        style: adaptedStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    });
  }
}

class AdaptiveIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const AdaptiveIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Icon(
        icon,
        size: size != null ? screenAdapter.getAdaptiveIconSize(size!) : null,
        color: color,
      );
    });
  }
}

class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Color? color;
  final Color? textColor;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: width != null ? screenAdapter.getAdaptiveWidth(width!) : null,
        height: height != null ? screenAdapter.getAdaptiveHeight(height!) : null,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            padding: padding != null
                ? EdgeInsets.only(
                    left: screenAdapter.getAdaptivePadding(padding!.left),
                    top: screenAdapter.getAdaptivePadding(padding!.top),
                    right: screenAdapter.getAdaptivePadding(padding!.right),
                    bottom: screenAdapter.getAdaptivePadding(padding!.bottom),
                  )
                : null,
          ),
          child: child,
        ),
      );
    });
  }
}

// 自适应数据表格列宽
class AdaptiveTableColumn {
  static double getWidth(double baseWidth) {
    return screenAdapter.getAdaptiveWidth(baseWidth);
  }
} 