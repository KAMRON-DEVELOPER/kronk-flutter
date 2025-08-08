import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:toastification/toastification.dart';

final serverError = const ToastificationType.custom('serverError', Colors.red, Icons.error_outline_rounded);

ToastificationItem showToast(
  BuildContext context,
  WidgetRef ref,
  ToastificationType type,
  String message, {
  Duration autoCloseDuration = const Duration(seconds: 3),
  bool showGlyph = true,
}) {
  final theme = ref.read(themeProvider);
  final foregroundColor = getForegroundColor(type: type, theme: theme);
  final backgroundColor = getBackgroundColor(type: type, theme: theme);
  final glyph = getGlyph(type: type);

  final titleText = showGlyph ? '$glyph $message' : message;

  return toastification.show(
    context: context,
    type: type,
    dragToClose: true,
    applyBlurEffect: true,
    style: ToastificationStyle.simple,
    title: Text(titleText, maxLines: 10, overflow: TextOverflow.visible),
    alignment: Alignment.topCenter,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    autoCloseDuration: autoCloseDuration,
    borderSide: BorderSide.none,
    borderRadius: BorderRadius.circular(12.dp),
    padding: EdgeInsets.symmetric(horizontal: 16.dp, vertical: 12.dp),
    closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
    animationBuilder: (context, animation, alignment, child) => FadeTransition(opacity: animation, child: child),
    // animationBuilder: (context, animation, alignment, child) => ScaleTransition(scale: animation, child: child),
  );
}

Color getForegroundColor({required ToastificationType type, required MyTheme theme}) {
  switch (type) {
    case ToastificationType.success:
      return Colors.greenAccent;
    case ToastificationType.info:
      return theme.primaryText;
    case ToastificationType.warning:
      return Colors.yellowAccent;
    case ToastificationType.error:
      return Colors.deepOrangeAccent;
    case _:
      return Colors.redAccent;
  }
}

Color getBackgroundColor({required ToastificationType type, required MyTheme theme}) {
  switch (type) {
    case ToastificationType.success:
      return Colors.green;
    case ToastificationType.info:
      return theme.primaryText;
    case ToastificationType.warning:
      return Colors.yellow;
    case ToastificationType.error:
      return Colors.deepOrange;
    case _:
      return Colors.red;
  }
}

String getGlyph({required ToastificationType type}) {
  switch (type) {
    case ToastificationType.success:
      return '🎉 ';
    case ToastificationType.info:
      return '🚀 ';
    case ToastificationType.warning:
      return '⚠️ ';
    case ToastificationType.error:
      return '🚨 ';
    case _:
      return '🌋 ';
  }
}
