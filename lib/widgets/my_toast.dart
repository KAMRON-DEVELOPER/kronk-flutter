import 'package:flutter/material.dart';
import 'package:kronk/constants/my_theme.dart';

enum ToastType { info, warning, error, serverError }

class MyToast {
  static void showToast({required BuildContext context, required MyTheme activeTheme, required String message, required ToastType type, required Duration duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: activeTheme.secondaryBackground,
        content: Text(
          message,
          style: TextStyle(color: getToastColor(type: type), fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.vertical,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 314, left: 16, right: 16),
      ),
    );
  }

  static void removeToast({required BuildContext context}) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}

Color getToastColor({required ToastType type}) {
  switch (type) {
    case ToastType.info:
      return Colors.lightBlueAccent;
    case ToastType.warning:
      return Colors.yellowAccent;
    case ToastType.error:
      return Colors.redAccent;
    case ToastType.serverError:
      return Colors.deepOrange;
  }
}

String getGlyph({required ToastType type}) {
  switch (type) {
    case ToastType.info:
      return '🚀';
    case ToastType.warning:
      return '⚠️';
    case ToastType.error:
      return '🚨';
    case ToastType.serverError:
      return '🌋';
  }
}

final String icons = '🤥 🤨 🤡 🤞 😎 🤏 🔄';
