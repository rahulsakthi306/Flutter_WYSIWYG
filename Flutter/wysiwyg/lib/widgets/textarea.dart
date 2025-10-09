import 'package:flutter/material.dart';

List<String> type = [
  'filled-circle',
  'outlined-circle',
  'filled-square',
  'outlined-square',
  'underlined',
];


class TTextArea extends StatefulWidget {
  final String type;
  final String? hintText;
  final bool isDisabled;
  final TextAlign textAlign;
  final TextAlignVertical textAlignVertical;
  final bool showCursor;
  final String? helperText;
  final Widget? prefix;
  final Widget? suffix;
  final bool needClear;
  final String? label;
  final int maxlines;
  final TextInputType? keyboardType;
  final String? fillColor;
  final bool isFloatLabel;
  final MainAxisAlignment? floatingLabelPosition;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final VoidCallback? callback;
  final double widthFactor;
  final List<Map<String, dynamic>>? animationConfig;

  const TTextArea({
    super.key,
    this.type = 'outlined-squaree',
    this.hintText,
    this.isDisabled = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical = TextAlignVertical.top,
    this.showCursor = true,
    this.helperText,
    this.prefix,
    this.suffix,
    this.needClear = false,
    this.controller,
    this.onChanged,
    this.validator,
    this.label,
    this.maxlines = 5, 
    this.keyboardType = TextInputType.multiline,
    this.fillColor, 
    this.isFloatLabel = false,
    this.floatingLabelPosition = MainAxisAlignment.start, 
    this.widthFactor = 1.0,
    this.animationConfig = const [],
    this.callback, 
  });

  @override
  State<TTextArea> createState() => _TTextAreaState();
}

class _TTextAreaState extends State<TTextArea> {

   late AnimationController _controller;
  Animation<double>? _fadeAnim;
  bool _isFadAnimating = false;
  Animation<Offset>? _slideAnim;
  bool _isSlideAnimating = false;
  Animation<double>? _scaleAnim;
  bool _isScaleAnimating = false;
  Animation<double>? _rotateAnim;
  bool _isRotateAnimating = false;

  // Linear Gradient
  Gradient? linearGradient;

    Widget _applyAnimations(Widget child) {
    Widget animated = child;

    if (_fadeAnim != null && _isFadAnimating) {
      animated = FadeTransition(opacity: _fadeAnim!, child: animated);
    }
    if (_slideAnim != null && _isSlideAnimating) {
      animated = SlideTransition(position: _slideAnim!, child: animated);
    }
    if (_scaleAnim != null && _isScaleAnimating) {
      animated = ScaleTransition(scale: _scaleAnim!, child: animated);
    }
    if (_rotateAnim != null && _isRotateAnimating) {
      animated = RotationTransition(turns: _rotateAnim!, child: animated);
    }

    return animated;
  }


  @override
  Widget build(BuildContext context) {

    BorderRadius borderRadius;
     Widget isClearable = widget.needClear
    ? (widget.controller?.text.isNotEmpty ?? false)
        ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              widget.controller?.clear();
            },
          )
        : const SizedBox()
    : widget.suffix ?? const SizedBox();

    if (widget.type.contains('circle')) {
      borderRadius = BorderRadius.circular(10);
    } else if (widget.type.contains('square')) {
      borderRadius = BorderRadius.zero;
    } else {
      borderRadius = BorderRadius.circular(8);
    }

    Color containerColor;
    switch (widget.fillColor) {
      case "primary":
        containerColor = Theme.of(context).colorScheme.primary;
        break;
      case "secondary":
        containerColor = Theme.of(context).colorScheme.secondary;
        break;
      case "tertiary":
        containerColor = Theme.of(context).colorScheme.tertiary;
        break;
      case "transparent":
        containerColor = Colors.transparent;
        break;
      case "light":
        containerColor = Colors.white;
        break;
      case "dark":
        containerColor = Colors.black;
        break;
      case "greyShade":
        containerColor = Colors.grey.shade200;
        break;
      default:
        containerColor = Colors.transparent;
        break;
    }

    InputDecoration inputDecoration;
     if(widget.type == 'filled-circle') {
          inputDecoration = InputDecoration(
          filled: true,
          fillColor: containerColor,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: borderRadius,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: widget.label ?? 'Enter text here',
          hintText: widget.hintText,
          helperText: widget.helperText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          floatingLabelBehavior: !widget.isFloatLabel
              ? FloatingLabelBehavior.auto
              : FloatingLabelBehavior.never,
        );
     } else  if(widget.type == 'outlined-circle') { 
          inputDecoration = InputDecoration(
          filled: false,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            borderRadius: borderRadius,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: widget.label ?? 'Enter text here',
          hintText: widget.hintText,
          helperText: widget.helperText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          floatingLabelBehavior: !widget.isFloatLabel
              ? FloatingLabelBehavior.auto
              : FloatingLabelBehavior.never,
        );
      }  else  if(widget.type == 'filled-square') {
            inputDecoration = InputDecoration(
          filled: true,
          fillColor: containerColor,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.zero,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12,horizontal: 12),
          labelText: widget.label ?? 'Enter text here',
          hintText: widget.hintText,
          helperText: widget.helperText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          floatingLabelBehavior: !widget.isFloatLabel
              ? FloatingLabelBehavior.auto
              : FloatingLabelBehavior.never,
        );
      } else  if(widget.type == 'outlined-square') {
          inputDecoration = InputDecoration(
          filled: false,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: widget.label ?? 'Enter text here',
          hintText: widget.hintText,
          helperText: widget.helperText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          floatingLabelBehavior: !widget.isFloatLabel
              ? FloatingLabelBehavior.auto
              : FloatingLabelBehavior.never,
        );
      } else  if(widget.type == 'underlined') {
            inputDecoration = InputDecoration(
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: widget.label ?? 'Enter text here',
          hintText: widget.hintText,
          helperText: widget.helperText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          floatingLabelBehavior: !widget.isFloatLabel
              ? FloatingLabelBehavior.auto
              : FloatingLabelBehavior.never,
        );
      } else {
          inputDecoration = InputDecoration(
          filled: false,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            borderRadius: borderRadius,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: widget.label ?? 'Enter text here',
          hintText: widget.hintText,
          helperText: widget.helperText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          floatingLabelBehavior: !widget.isFloatLabel
              ? FloatingLabelBehavior.auto
              : FloatingLabelBehavior.never,
        );
      }

 
 
    return _applyAnimations(
     Visibility(
        visible: true,
        child: Column(
          children: [
            if (!widget.isFloatLabel)
              Row(
                mainAxisAlignment: widget.floatingLabelPosition ?? MainAxisAlignment.start,
                children:  [
                              if (widget.prefix != null) ...[
                                widget.prefix ?? const SizedBox(),
                                const SizedBox(width: 8),
                              ],
                              Text(widget.label ?? ''),
                              if(widget.suffix != null)...[
                                const SizedBox(width: 8),
                                widget.suffix ?? const SizedBox(),
                              ]
                            ],
              ),
          SizedBox(height: 8),
          SizedBox(
          child: TextFormField(
            controller: widget.controller,
            decoration: inputDecoration,
            keyboardType: widget.keyboardType,
            textAlign: widget.textAlign,
            textAlignVertical: widget.textAlignVertical,
            showCursor: widget.showCursor,
            enabled: !widget.isDisabled,
            onChanged: widget.onChanged,
            validator: widget.validator,
            maxLines: widget.maxlines),
            ),
          ],
        ),
      ),
    );
  }

  Size _getSize(String size, int maxLines) {
  double height;

  switch (size) {
    case 'small':
      height = 100;
      return  Size(150, height);
    case 'medium':
      height = 120;
      return Size(200, height);
    case 'large':
      height = 126;
      return Size(300, height);
    case 'max':
      height = 100;
      return Size(double.infinity, height);
    default:
      height = 48;
  }

  double extendedHeight = height + (maxLines - 1) * 24; 
  return Size(double.infinity, extendedHeight);
}
}
