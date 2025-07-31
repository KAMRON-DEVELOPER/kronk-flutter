import 'package:flutter/material.dart';

//
// class Dimensions {
//   final BuildContext context;
//   final double screenWidth;
//   final double screenHeight;
//   final double devicePixelRatio;
//   final double with1;
//   final double with2;
//   final double margin1;
//   final double margin2;
//   final double margin3;
//   final double margin4;
//   final double margin5;
//   final double padding1;
//   final double padding2;
//   final double padding3;
//   final double padding4;
//   final double buttonHeight1;
//   final double buttonHeight2;
//   final double buttonHeight3;
//   final double buttonHeight4;
//   final double buttonHeight5;
//   final double textSize1;
//   final double textSize2;
//   final double textSize3;
//   final double textSize4;
//   final double textSize5;
//   final double textSize6;
//   final double radius1;
//   final double radius2;
//   final double radius3;
//   final double radius4;
//   final double iconSize1;
//   final double iconSize2;
//   final double iconSize3;
//   final double iconSize4;
//   final double iconSize5;
//   final double iconSize6;
//   final double height1;
//   final double height2;
//   final double themeCircleRadius;
//   final double feedImageSelectorWidth;
//   final double tabHeight1;
//   final double avatarHeight;
//   final double avatarRadius;
//   final double bannerHeight;
//   final double spacing2;
//   final double appBarHeight;
//   final double bottomHeight;
//
//   Dimensions({
//     required this.context,
//     required this.screenWidth,
//     required this.screenHeight,
//     required this.devicePixelRatio,
//     required this.with1,
//     required this.with2,
//     required this.margin1,
//     required this.margin2,
//     required this.margin3,
//     required this.margin4,
//     required this.margin5,
//     required this.padding1,
//     required this.padding2,
//     required this.padding3,
//     required this.padding4,
//     required this.buttonHeight1,
//     required this.buttonHeight2,
//     required this.buttonHeight3,
//     required this.buttonHeight4,
//     required this.buttonHeight5,
//     required this.textSize1,
//     required this.textSize2,
//     required this.textSize3,
//     required this.textSize4,
//     required this.textSize5,
//     required this.textSize6,
//     required this.radius1,
//     required this.radius2,
//     required this.radius3,
//     required this.radius4,
//     required this.iconSize1,
//     required this.iconSize2,
//     required this.iconSize3,
//     required this.iconSize4,
//     required this.iconSize5,
//     required this.iconSize6,
//     required this.height1,
//     required this.height2,
//     required this.themeCircleRadius,
//     required this.feedImageSelectorWidth,
//     required this.tabHeight1,
//     required this.avatarHeight,
//     required this.avatarRadius,
//     required this.bannerHeight,
//     required this.spacing2,
//     required this.appBarHeight,
//     required this.bottomHeight,
//   });
//
//   /// Factory constructor to calculate values based on the screen size.
//   factory Dimensions.of(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     final screenWidth = size.width;
//     final screenHeight = size.height;
//
//     final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
//
//     final with1 = screenWidth * 0.94; // 392px
//     final with2 = screenWidth * 0.86;
//
//     final margin1 = screenWidth / 10;
//     final margin2 = screenWidth * 0.07;
//     final margin3 = screenWidth / 28;
//     final margin4 = screenWidth / 36;
//     final margin5 = screenWidth / 50;
//
//     final padding1 = screenWidth / 24; // 16px
//     final padding2 = screenWidth / 32; // 12px
//     final padding3 = screenWidth / 48; // 8px
//     final padding4 = screenWidth / 98; // 4px
//
//     final buttonHeight1 = screenHeight / 16;
//     final buttonHeight2 = screenHeight / 18;
//     final buttonHeight3 = screenHeight / 20;
//     final buttonHeight4 = screenHeight / 28;
//     final buttonHeight5 = screenWidth / 11;
//
//     final textSize1 = screenWidth / 8;
//     final textSize2 = screenWidth / 12;
//     final textSize3 = screenWidth / 20;
//     final textSize4 = screenWidth / 28;
//     final textSize5 = screenWidth / 32;
//     final textSize6 = screenWidth / 24;
//
//     final double cornerRadius1 = screenWidth / 27;
//     final double cornerRadius2 = screenWidth / 32;
//     final double cornerRadius3 = screenWidth / 34;
//     final double cornerRadius4 = screenWidth / 36;
//
//     final double iconSize1 = screenWidth / 12;
//     final double iconSize2 = screenWidth / 16;
//     final double iconSize3 = screenWidth / 20;
//     final double iconSize4 = screenWidth / 22;
//     final double iconSize5 = screenWidth / 24;
//     final double iconSize6 = screenWidth / 18;
//
//     final height1 = screenHeight / 7.5;
//     final double height2 = screenWidth / 9;
//
//     final themeCircleRadius = screenWidth / 7;
//
//     final feedImageSelectorWidth = screenWidth / 4;
//
//     final tabHeight1 = screenWidth / 12;
//
//     final double avatarHeight = screenWidth / 4;
//     final double avatarRadius = screenWidth / 8;
//     final double bannerHeight = screenWidth * 9 / 20;
//
//     final double spacing2 = screenWidth / 32.5;
//     final double appBarHeight = screenWidth / 8.15;
//     final double bottomHeight = screenWidth / 9.8;
//
//     return Dimensions(
//       context: context,
//       screenWidth: screenWidth,
//       screenHeight: screenHeight,
//       devicePixelRatio: devicePixelRatio,
//       with1: with1,
//       with2: with2,
//       margin1: margin1,
//       margin2: margin2,
//       margin3: margin3,
//       margin4: margin4,
//       margin5: margin5,
//       padding1: padding1,
//       padding2: padding2,
//       padding3: padding3,
//       padding4: padding4,
//       buttonHeight1: buttonHeight1,
//       buttonHeight2: buttonHeight2,
//       buttonHeight3: buttonHeight3,
//       buttonHeight4: buttonHeight4,
//       buttonHeight5: buttonHeight5,
//       textSize1: textSize1,
//       textSize2: textSize2,
//       textSize3: textSize3,
//       textSize4: textSize4,
//       textSize5: textSize5,
//       textSize6: textSize6,
//       radius1: cornerRadius1,
//       radius2: cornerRadius2,
//       radius3: cornerRadius3,
//       radius4: cornerRadius4,
//       iconSize1: iconSize1,
//       iconSize2: iconSize2,
//       iconSize3: iconSize3,
//       iconSize4: iconSize4,
//       iconSize5: iconSize5,
//       iconSize6: iconSize6,
//       height1: height1,
//       height2: height2,
//       themeCircleRadius: themeCircleRadius,
//       feedImageSelectorWidth: feedImageSelectorWidth,
//       tabHeight1: tabHeight1,
//       avatarHeight: avatarHeight,
//       avatarRadius: avatarRadius,
//       bannerHeight: bannerHeight,
//       spacing2: spacing2,
//       appBarHeight: appBarHeight,
//       bottomHeight: bottomHeight,
//     );
//   }
// }

double scale(double value, double screenWidth) {
  const baseWidth = 390.0;
  return screenWidth / baseWidth * value;
}

class Sizes {
  static double baseWidth = 392.7272;
  static late double screenWidth;
  static late double screenHeight;
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
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    double scale(num value) => screenWidth / baseWidth * value;

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
