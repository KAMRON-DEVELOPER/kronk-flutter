import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kronk/constants/kronk_icon.dart';
import 'package:kronk/utility/dimensions.dart';

extension StringExtensions on String {
  String? get isValidUsername {
    final nameRegExp = RegExp(r'^[A-Za-z][A-Za-z0-9_]{4,19}$');
    if (isEmpty) {
      return null;
    } else if (!nameRegExp.hasMatch(this)) {
      return 'Username is incorrect';
    }
    return null;
  }

  String? get isValidPassword {
    final passwordRegExp = RegExp(r'^(?!.*(?:012|123|234|345|456|567|678|789|890))(?=.*[A-Za-z0-9]).{6,20}$');
    if (isEmpty) {
      return null;
    } else if (!passwordRegExp.hasMatch(this)) {
      return 'Password is incorrect';
    }
    return null;
  }

  String? get isValidEmail {
    final regex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$');
    if (isEmpty) {
      return null;
    } else if (!regex.hasMatch(this)) {
      return 'Email is incorrect. Please enter a valid email address.';
    }
    return null;
  }

  String? get isValidCode {
    if (isEmpty) {
      return 'Please, fill the code field';
    } else if (length < 4) {
      return 'Too short. The code should contain 4 digits.';
    } else if (length > 4) {
      return 'Too long. The code should contain 4 digits.';
    } else {
      return null;
    }
  }

  bool get isEmail {
    final RegExp emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegex.hasMatch(this);
  }

  Color fromHex() {
    final buffer = StringBuffer();
    if (length == 6 || length == 7) buffer.write('ff');
    buffer.write(replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toTitleCaseWithSpaces() {
    return split('_').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  String capitalize() {
    return isEmpty ? '' : this[0].toUpperCase() + substring(1).replaceAll('_', ' ');
  }

  String toSnakeCase() {
    return replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (match) => '${match.group(1)}_${match.group(2)}').toLowerCase();
  }
}

extension NumExtensions on num {
  /// Converts this number to a pixel value suitable for image caching,
  /// based on the current device's pixel ratio.
  ///
  /// Useful for setting cache size for `CachedNetworkImageProvider` or
  /// any image-related widget that needs pixel-accurate sizing.
  ///
  /// Example:
  /// ```dart
  /// final size = 120.cacheSize(context); // returns int
  /// ```
  int cacheSize(BuildContext context) {
    return (this * MediaQuery.of(context).devicePixelRatio).round();
  }

  /// Converts this number to a pixel value (double) suitable for
  /// precise image layout calculations based on device pixel ratio.
  ///
  /// Example:
  /// ```dart
  /// final size = 120.doubleCacheSize(context); // returns double
  /// ```
  double doubleCacheSize(BuildContext context) {
    return (this * MediaQuery.of(context).devicePixelRatio).floorToDouble();
  }

  /// Scales this number according to the device's screen width,
  /// using your custom `Sizes.scale()` method.
  ///
  /// This gives consistent sizing across different screen sizes by
  /// comparing against a base width (e.g., 390).
  ///
  /// Example:
  /// ```dart
  /// final padding = 16.dp; // returns double, scaled to screen width
  /// ```
  ///
  /// ⚠️ Make sure `Sizes.init(context)` is called before using this.
  double get dp {
    return Sizes.scale(this);
  }
}

extension IntExtensions on int {
  String get normalize {
    final bool isWithinRange100 = compareTo(100) == 0 || compareTo(100) < 0;
    final bool isWithinRange1k = compareTo(1000) == 0 || compareTo(1000) < 0;
    return isWithinRange100 ? toString() : (isWithinRange1k ? '+${this ~/ 1000}k' : '+${this ~/ 10000}k');
  }

  String get weekdayName {
    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[this - 1];
  }

  String get monthName {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[this - 1];
  }
}

extension IconColorExtension on IconData {
  Color get appropriateColor {
    if (this == KronkIcon.repeat6) return Colors.green;
    if (this == KronkIcon.heartOutline) return Colors.redAccent;
    if (this == KronkIcon.bookmarkOutline5) return Colors.orangeAccent;
    return Colors.deepPurpleAccent;
  }
}

extension ChatDateFormat on DateTime {
  /// Telegram-style date label for chat previews:
  /// - Today → "3:45 PM"
  /// - This week → "Mon", "Tue", etc.
  /// - Otherwise → "7/16/25"
  String toChatLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDate = DateTime(year, month, day);

    final differenceInDays = today.difference(inputDate).inDays;

    if (differenceInDays == 0) {
      // Today → show time
      return DateFormat.jm().format(this); // "3:45 PM"
    } else if (differenceInDays < 7 && now.weekday >= weekday) {
      // Same week → show weekday
      return DateFormat.E().format(this); // "Mon", "Tue", ...
    } else {
      // Older → MM/DD/YY
      return DateFormat('M/d/yy').format(this); // "7/16/25"
    }
  }
}
