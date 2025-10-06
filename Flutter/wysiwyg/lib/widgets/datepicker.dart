import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

List<String> type = [
  'filled-circle',
  'outlined-circle',
  'filled-square',
  'outlined-square',
  'underlined',
];

class TDatePicker extends StatefulWidget {
  final String type;
  final String? label;
  final String? hintText;
  final bool isDisabled;
  final String? selectedDate;
  final void Function(DateTime?)? onChanged;
  final String? helperText;
  final String? dateFormat;
  final String? fillColor;
  final bool needClear;
  final Widget? prefix;
  final Widget? suffix;
  final bool isFloatLabel;
  final bool? allowPastDates;
  final bool? allowFutureDates;
  final MainAxisAlignment? floatingLabelPosition;
  final TextEditingController? controller;
  final VoidCallback? callback;
  final double widthFactor;
  final List<Map<String, dynamic>>? animationConfig;

  const TDatePicker({
    super.key,
    this.type = 'outlined-square',
    this.isDisabled = false,
    this.helperText,
    this.hintText,
    this.selectedDate,
    this.dateFormat,
    this.label,
    this.onChanged,
    this.needClear = false,
    this.prefix,
    this.suffix,
    this.fillColor, 
    this.isFloatLabel = false,
    this.floatingLabelPosition = MainAxisAlignment.start, 
    this.allowPastDates,
    this.allowFutureDates,
    this.controller,
    this.callback,
    this.widthFactor = 1.0, 
    this.animationConfig = const [],

  });

  @override
  State<TDatePicker> createState() => _TDatePickerState();
}

class _TDatePickerState extends State<TDatePicker> with TickerProviderStateMixin {


   // Animation 
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

  @override
  void initState() {
    super.initState();
     _setupAnimations();
  }

    void _setupAnimations() {    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final curves = {
      "ease in": Curves.easeIn,
      "ease in out": Curves.easeInOut,
      "ease out": Curves.easeOut,
      "bounce": Curves.bounceOut,
      "elastic": Curves.elasticOut,
      "linear": Curves.linear,
    };

    if (widget.animationConfig != null) {
      for (final anim in widget.animationConfig!) {
        if (anim["value"] == true) {
          switch (anim["name"]) {
            case "fade":
              setState(() {
                _isFadAnimating = true;
                final props = anim["fadeProps"];
                _fadeAnim = Tween<double>(
                  begin: (props["initialOpacity"]["value"] ?? 0).toDouble(),
                  end: (props["finalOpacity"]["value"] ?? 1).toDouble(),
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve:
                      curves[props["animationCurve"]["value"]] ?? Curves.linear,
                ));
              });
              break;
            case "slide":
              setState(() {
                _isSlideAnimating = true;
                final props = anim["slideProps"];
                _slideAnim = Tween<Offset>(
                  begin: Offset(
                    (props["horizontalSlide"][0]["value"] ?? 0).toDouble(),
                    (props["verticalSlide"][0]["value"] ?? 0).toDouble(),
                  ),
                  end: Offset(
                    (props["horizontalSlide"][1]["value"] ?? 0).toDouble(),
                    (props["verticalSlide"][1]["value"] ?? 0).toDouble(),
                  ),
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve: curves[props["animationCurve"]["value"]] ?? Curves.linear,
                ));
              });
              break;
            case "scale":
              setState(() {
                _isScaleAnimating = true;
                final props = anim["scaleProps"];
                _scaleAnim = Tween<double>(
                  begin: (props["initialScale"][0]["value"] ?? 1).toDouble(),
                  end: (props["finalScale"][0]["value"] ?? 1).toDouble(),
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve:
                      curves[props["animationCurve"]["value"]] ?? Curves.linear,
                ));
              });
              break;
            case "roate":
              setState(() {
                _isRotateAnimating = true;
                final props = anim["roateProps"];
                _rotateAnim = Tween<double>(
                  begin: (props["initialTurn"]["value"] ?? 0).toDouble(),
                  end: (props["finalTurn"]["value"] ?? 0).toDouble(),
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve:
                      curves[props["animationCurve"]["value"]] ?? Curves.linear,
                ));
              });
              break;
          }
        }
      }
    }

    _controller.forward();
  }

  DateTime? _tryParse(String value) {
    try {
      return DateFormat(widget.dateFormat ?? 'yyyy/MM/dd').parseStrict(value);
    } catch (_) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
  }

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
    String labelText = widget.label ?? 'Select a date';

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
      borderRadius = BorderRadius.circular(30);
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
    switch (widget.type) {
      case 'filled-circle':
        inputDecoration = InputDecoration(
          filled: true,
          fillColor: containerColor,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: borderRadius,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: labelText,
          hintText: widget.hintText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          helperText: widget.helperText,
        );
        break;
      case 'outlined-circle':
        inputDecoration = InputDecoration(
          filled: false,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            borderRadius: borderRadius,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: labelText,
          hintText: widget.hintText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          helperText: widget.helperText,
        );
        break;
      case 'filled-square':
        inputDecoration = InputDecoration(
          filled: true,
          fillColor: containerColor,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.zero,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: labelText,
          hintText: widget.hintText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          helperText: widget.helperText,
        );
        break;
      case 'outlined-square':
        inputDecoration = InputDecoration(
          filled: false,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: labelText,
          hintText: widget.hintText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          helperText: widget.helperText,
        );
        break;
      case 'underlined':
        inputDecoration = InputDecoration(
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: labelText,
          hintText: widget.hintText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          helperText: widget.helperText,
        );
        break;
      case 'underlined-square':
        inputDecoration = InputDecoration(
          filled: false,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: labelText,
          hintText: widget.hintText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          helperText: widget.helperText,
        );
        break;
      default:
        inputDecoration = InputDecoration(
          filled: false,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            borderRadius: borderRadius,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: labelText,
          hintText: widget.hintText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          helperText: widget.helperText,
        );
    }

    return SizedBox(
    
      // height: size.height,
      child: TextFormField(
        controller: TextEditingController(
          text: widget.selectedDate != null ? _formatDate(widget.selectedDate! as DateTime) : '',
        ),
        decoration: inputDecoration,
        enabled: !widget.isDisabled,
        readOnly: true,
        onTap: !widget.isDisabled ? _selectDate : (){},
      ),
    );
  }

  // Method to show the date picker
 Future<void> _selectDate() async {
    DateTime today = DateTime.now();
    DateTime justToday = DateTime(today.year, today.month, today.day);

    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime(2100);

    bool allowPast = widget.allowPastDates ?? true;
    bool allowFuture = widget.allowFutureDates ?? true;

    selectableDayPredicate(DateTime day) {
      bool isBeforeToday = day.isBefore(justToday);
      bool isAfterToday = day.isAfter(justToday);

      if (!allowPast && isBeforeToday) {
        return false;
      }
      if (!allowFuture && isAfterToday) {
        return false; 
      }
      return true;
    }

    DateTime? parsedInitial = widget.selectedDate != null ? _tryParse(widget.selectedDate!) : null;
    DateTime initialDate = parsedInitial ?? justToday;
    if (!selectableDayPredicate(initialDate)) {
      initialDate = justToday;
    }

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: selectableDayPredicate,
    );

    if (selectedDate != null) {
      widget.controller?.text = _formatDate(selectedDate);
      widget.onChanged?.call(selectedDate);
    }
  }

  String _formatDate(DateTime date) {
    String format = widget.dateFormat ?? 'yyyy-MM-dd';
    return DateFormat(format).format(date);
  }

}
