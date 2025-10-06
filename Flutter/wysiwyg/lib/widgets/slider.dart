import 'package:flutter/material.dart';

List<String> type = ['top', 'left', 'right', 'bottom'];

class TSlider extends StatefulWidget {
  final double value;
  final int divisions;
  final void Function(double)? onChanged;
  final String? label;
  final double min;
  final double max;
  final String size;
  final String labelPosition;

  const TSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 'max',
    this.max = 100,
    this.divisions = 10,
    this.min = 0,
    this.labelPosition = 'left',
    this.label,
  }); 

  @override
  State<TSlider> createState() {
    return _TSliderState();
  }
}

class _TSliderState extends State<TSlider> {
  Size _getSize(String size) {
    switch (size) {
      case 'small':
        return const Size(120, 40);
      case 'medium':
        return const Size(200, 48);
      case 'large':
        return const Size(300, 56);
      case 'max':
        return const Size(double.infinity, 56);
      default:
        return const Size(200, 48);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = _getSize(widget.size);

    Widget continuousSliderWidget = SizedBox(
      width: size.width,
      child: Slider(
        value: widget.value ?? 0,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        label: widget.value?.round().toString(),
        onChanged: widget.onChanged,
         
      ),
    );

    switch (widget.labelPosition) {
      case 'left':
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(widget.label ?? ''),
            widget.size == 'max' ? Flexible(child: continuousSliderWidget) : continuousSliderWidget,
          ],
        );
      case 'right':
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            widget.size == 'max' ? Flexible(child: continuousSliderWidget) : continuousSliderWidget,
            Text(widget.label ?? ''),
          ],
        );
      case 'top':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.label ?? ''),
            continuousSliderWidget,
          ],
        );
      case 'bottom':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            continuousSliderWidget,
            Text(widget.label ?? ''),
          ],
        );
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            continuousSliderWidget,
            Text(widget.label ?? ''),
          ],
        );
    }
  }
}
