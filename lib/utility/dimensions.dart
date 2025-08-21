import 'package:flutter/material.dart';

double scale(double value, double screenWidth) {
  const baseWidth = 390.0;
  return screenWidth / baseWidth * value;
}

class Sizes {
  static double baseWidth = 392.7272;
  static late double screenWidth;
  static late double screenHeight;
  static late double devicePixelRatio;
  static late double viewPaddingTop;
  static late double viewPaddingBottom;
  static late double navbarHeight;
  static late double s2;
  static late double s4;
  static late double s6;
  static late double s8;
  static late double s10;
  static late double s12;
  static late double s16;
  static late double s20;
  static late double s24;
  static late double s32;
  static late double s40;
  static late double s48;
  static late double s56;
  static late double s64;

  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
    devicePixelRatio = mediaQuery.devicePixelRatio;
    viewPaddingTop = mediaQuery.viewPadding.top;
    viewPaddingBottom = mediaQuery.viewPadding.bottom;
    navbarHeight = scale(56);

    s2 = scale(2);
    s4 = scale(4);
    s6 = scale(6);
    s8 = scale(8);
    s10 = scale(10);
    s12 = scale(12);
    s16 = scale(16);
    s20 = scale(20);
    s24 = scale(24);
    s32 = scale(32);
    s40 = scale(40);
    s48 = scale(48);
    s56 = scale(56);
    s64 = scale(64);
  }

  static double scale(num value) => screenWidth / baseWidth * value;
}
