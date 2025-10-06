import 'package:flutter/material.dart';

class TIcon extends StatelessWidget {
  final IconData icon;
  final String size; 
  final Color? color;
  final Function()? onTap;

  const TIcon({
    super.key,
    this.onTap,
    this.icon = Icons.question_mark,
    this.size = 'medium', 
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    double iconSize;

    switch (size) {
      case 'small':
        iconSize = 16.0;
        break;
      case 'large':
        iconSize = 32.0;
        break;
      case 'medium':
      default:
        iconSize = 24.0;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: iconSize,
        color: color,
      ),
    );
  }
}
