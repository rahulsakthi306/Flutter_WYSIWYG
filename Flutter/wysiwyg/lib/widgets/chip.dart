import 'package:flutter/material.dart';

class TChip extends StatefulWidget {
  final String type; 
  final IconData? icon;
  final String label;
  final String colorType;
  


  const TChip({
    super.key,
    this.type = 'capsule',
    this.icon = Icons.add, 
    this.label = '',
    this.colorType = 'primary', 
  });

  @override
  State<TChip> createState() => _TChipState();
}

class _TChipState extends State<TChip> {
  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry borderRadius;

    switch (widget.type) {
      case 'capsule':
        borderRadius = BorderRadius.circular(50);
        break;
      case 'rectangle':
        borderRadius = BorderRadius.zero;
        break;
      case 'rounded':
      default:
        borderRadius = BorderRadius.circular(30);
        break;
    }

    Widget chipLabel;
    if (widget.icon != null && widget.label.isNotEmpty) {
      chipLabel = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon),
          SizedBox(width: 8),
          Text(widget.label),
        ],
      );
    } else if (widget.icon != null) {
      chipLabel = Icon(widget.icon);
    } else {
      chipLabel = Text(widget.label);
    }

    Color containerColor;
    switch (widget.colorType) {
      case 'primary':
        containerColor = Theme.of(context).colorScheme.primaryContainer;
        break;
      case 'secondary':
        containerColor = Theme.of(context).colorScheme.secondary;
        break;
      case 'tertiary':
        containerColor = Theme.of(context).colorScheme.tertiary;
        break;
      case 'transparent':
        containerColor = Colors.transparent;
        break;
      case 'light':
        containerColor = Colors.white;
        break;
      case 'dark':
        containerColor = Colors.black;
        break;
      case 'greyShade':
        containerColor = Colors.grey.shade200;
        break;
      default:
        containerColor = Colors.transparent;
        break;
    }

    return GestureDetector(
      onTap: () {},
      onDoubleTap: () {},
      onLongPress: () {},
      child: Chip(
        label: chipLabel,
        backgroundColor: containerColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
