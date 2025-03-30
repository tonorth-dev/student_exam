import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/app_providers.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleStr;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool centerTitle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final Color backgroundColor;
  final VoidCallback? onBackPressed;
  
  const CommonAppBar({
    super.key,
    this.titleStr = '',
    this.actions,
    this.leading,
    this.backgroundColor = Colors.white,
    this.showBackButton = true,
    this.centerTitle = true,
    this.systemOverlayStyle,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenAdapter = AppProviders.instance.screenAdapter;
    
    return AppBar(
      systemOverlayStyle: systemOverlayStyle,
      backgroundColor: backgroundColor,
      centerTitle: centerTitle,
      title: Text(
        titleStr,
        style: TextStyle(
          fontSize: screenAdapter.getAdaptiveFontSize(18),
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevation: 0,
      leading: !showBackButton
          ? leading
          : IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: screenAdapter.getAdaptiveIconSize(24),
                color: Colors.black,
              ),
              onPressed: onBackPressed ??
                  () {
                    Navigator.pop(context);
                  },
            ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize {
    final screenAdapter = AppProviders.instance.screenAdapter;
    return Size.fromHeight(screenAdapter.getAdaptiveHeight(56));
  }
} 