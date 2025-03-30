import 'package:flutter/material.dart';
import 'package:student_exam/common/screen_adapter.dart';
import 'package:window_manager/window_manager.dart';
import '../main.dart' show screenAdapter;

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final double? toolbarHeight;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.flexibleSpace,
    this.toolbarHeight,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.leading,
  });

  final _screenAdapter = screenAdapter;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ?? (automaticallyImplyLeading ? DragToMoveArea(
        child: Icon(
          Icons.menu,
          size: _screenAdapter.getAdaptiveIconSize(24),
        ),
      ) : null),
      title: Text(
        title,
        style: TextStyle(
          fontSize: _screenAdapter.getAdaptiveFontSize(18),
        ),
      ),
      actions: actions,
      flexibleSpace: flexibleSpace,
      toolbarHeight: toolbarHeight ?? _screenAdapter.getAdaptiveHeight(80),
      backgroundColor: backgroundColor,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight ?? _screenAdapter.getAdaptiveHeight(80),
      );
} 