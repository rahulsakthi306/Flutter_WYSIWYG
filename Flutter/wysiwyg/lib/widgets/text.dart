import 'package:flutter/material.dart';

class TextWidget extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final FontWeight fontWeight;
  final String textTheme;
  final TextOverflow textOverflow;
  final TextAlign textAlign;

  const TextWidget({
    super.key,
    required this.text,
    this.textStyle,
    this.textTheme = 'labelMedium',
    this.textOverflow = TextOverflow.fade,
    this.textAlign = TextAlign.center,
    this.fontWeight = FontWeight.w100
  });

  @override
  Widget build(BuildContext context) {

    TextStyle themeTextStyle = _getTextThemeStyle(textTheme);

    return Text(
      text,
      overflow: textOverflow,
      textAlign: textAlign,
      style: textStyle ?? themeTextStyle,
    );
  }

  TextStyle _getTextThemeStyle(String theme) {
    switch (theme) {
      case 'displayLarge':
        return TextStyle(fontSize: 57, fontWeight: fontWeight);
      case 'displayMedium':
        return TextStyle(fontSize: 45, fontWeight: fontWeight);
      case 'displaySmall':
        return TextStyle(fontSize: 36, fontWeight: fontWeight);
      case 'headlineLarge':
        return TextStyle(fontSize: 32, fontWeight: fontWeight);
      case 'headlineMedium':
        return TextStyle(fontSize: 28, fontWeight: fontWeight);
      case 'headlineSmall':
        return TextStyle(fontSize: 24, fontWeight: fontWeight);
      case 'titleLarge':
        return TextStyle(fontSize: 22, fontWeight: fontWeight);
      case 'titleMedium':
        return TextStyle(fontSize: 16, fontWeight: fontWeight);
      case 'titleSmall':
        return TextStyle(fontSize: 14, fontWeight: fontWeight);
      case 'labelLarge':
        return TextStyle(fontSize: 14, fontWeight: fontWeight);
      case 'labelMedium':
        return TextStyle(fontSize: 12, fontWeight: fontWeight);
      case 'labelSmall':
        return TextStyle(fontSize: 11, fontWeight: fontWeight);
      case 'bodyLarge':
        return TextStyle(fontSize: 16, fontWeight: fontWeight);
      case 'bodyMedium':
        return TextStyle(fontSize: 14, fontWeight: fontWeight);
      case 'bodySmall':
        return TextStyle(fontSize: 12, fontWeight: fontWeight);
      default:
        return TextStyle(fontSize: 12, fontWeight: fontWeight);
    }
  }
}
