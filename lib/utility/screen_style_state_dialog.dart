import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/riverpod/general/screen_style_state_provider.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/extensions.dart';

void showScreenStyleStateDialog(BuildContext context, String screenName) {
  const List<String> backgroundImages = [
    '1.jpg',
    '2.jpg',
    '3.jpg',
    '5.jpg',
    '6.jpeg',
    '7.jpeg',
    '8.jpeg',
    '9.jpeg',
    '10.jpeg',
    '11.jpeg',
    '12.jpeg',
    '13.jpeg',
    '14.jpeg',
    '15.jpeg',
    '16.jpeg',
    '17.jpeg',
    '18.jpeg',
    '19.jpg',
    '20.jpg',
    '21.jpg',
    '22.jpg',
    '23.jpg',
    '24.jpg',
    '25.jpg',
    '26.jpg',
    '27.jpg',
    '28.jpg',
  ];

  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final theme = ref.watch(themeProvider);
          final ScreenStyleState screenStyleState = ref.watch(screenStyleStateProvider(screenName));
          final notifier = ref.read(screenStyleStateProvider(screenName).notifier);
          final bool isFloating = screenStyleState.layoutStyle == LayoutStyle.floating;

          final double width = 96.dp;
          final double height = 16 / 9 * width;
          return Dialog(
            backgroundColor: theme.tertiaryBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.dp)),
            child: Padding(
              padding: EdgeInsets.all(8.dp),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 8.dp,
                children: [
                  /// Background image list
                  SizedBox(
                    height: height,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: backgroundImages.length,
                      itemBuilder: (context, index) {
                        final String backgroundImage = 'assets/images/${backgroundImages.elementAt(index)}';
                        return Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            /// Images list
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.dp),
                              child: GestureDetector(
                                onTap: () => notifier.updateScreenStyleState(backgroundImage: backgroundImage),
                                child: Image.asset(backgroundImage, height: height, width: width, cacheHeight: height.cacheSize(context), cacheWidth: width.cacheSize(context)),
                              ),
                            ),

                            /// Selected background image indicator
                            if (screenStyleState.backgroundImage == backgroundImage)
                              Positioned(
                                bottom: 8.dp,
                                child: Icon(Icons.check_circle_rounded, color: theme.secondaryText, size: 32.dp),
                              ),
                          ],
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(width: 8.dp),
                    ),
                  ),

                  /// Toggle button
                  Row(
                    spacing: 8.dp,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.updateScreenStyleState(layoutStyle: LayoutStyle.edgeToEdge),
                          child: Container(
                            height: 64.dp,
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(8.dp),
                              border: Border.all(color: isFloating ? theme.secondaryBackground : theme.primaryText),
                            ),
                            child: Center(
                              child: Text(
                                'Edge-to-edge',
                                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => notifier.updateScreenStyleState(layoutStyle: LayoutStyle.floating),
                          child: Container(
                            height: 64.dp,
                            decoration: BoxDecoration(
                              color: theme.secondaryBackground,
                              borderRadius: BorderRadius.circular(8.dp),
                              border: Border.all(color: isFloating ? theme.primaryText : theme.secondaryBackground),
                            ),
                            child: Center(
                              child: Text(
                                'Floating',
                                style: GoogleFonts.quicksand(color: theme.primaryText, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  /// Slider Rounded Corner
                  Slider(
                    value: screenStyleState.borderRadius,
                    min: 0,
                    max: 24,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    onChanged: (double newRadiusRadius) => notifier.updateScreenStyleState(borderRadius: newRadiusRadius),
                  ),

                  /// Slider opacity
                  Slider(
                    value: screenStyleState.opacity,
                    min: 0,
                    max: 1,
                    activeColor: theme.primaryText,
                    inactiveColor: theme.primaryText.withValues(alpha: 0.2),
                    thumbColor: theme.primaryText,
                    onChanged: (double newOpacity) => notifier.updateScreenStyleState(opacity: newOpacity),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
