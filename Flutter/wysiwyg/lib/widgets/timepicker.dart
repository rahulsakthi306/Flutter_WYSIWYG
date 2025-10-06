import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

List<String> type = [
  'filled-circle',
  'outlined-circle',
  'filled-square',
  'outlined-square',
  'underlined',
];

class TTimePicker extends StatefulWidget {
  final String type;
  final String? label;
  final String? hintText;
  final bool isDisabled;
  final TimeOfDay? selectedTime;
  final String? helperText;
  final String? timeFormat; 
  final String? fillColor;
  final bool needClear;
  final Widget? prefix;
  final Widget? suffix;
  final bool isFloatLabel;
  final MainAxisAlignment? floatingLabelPosition;
  final TextEditingController? controller;
  final VoidCallback? callback;
  final double widthFactor;
  final List<Map<String, dynamic>>? animationConfig;
  final void Function(TimeOfDay?)? onChanged;


  const TTimePicker({
    super.key,
    this.type = 'outlined-square',
    this.isDisabled = false,
    this.selectedTime,
    this.helperText,
    this.hintText,
    this.timeFormat,
    this.label,
    this.onChanged, 
    this.fillColor, 
    this.needClear =false,  
    this.prefix, 
    this.suffix, 
    this.isFloatLabel =true, 
    this.floatingLabelPosition = MainAxisAlignment.start, 
    this.controller, 
    this.widthFactor = 1.0, 
    this.animationConfig = const [],
    this.callback, 
 
  });

  @override
  State<TTimePicker> createState() => _TTimePickerState();
}

class _TTimePickerState extends State<TTimePicker> {
  TextEditingController _controller = TextEditingController();

   // Animation
  late AnimationController controller;
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
  void initState() {
    super.initState();
    if (widget.selectedTime != null) {
      _controller.text = _formatTime(widget.selectedTime!);
    }
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
      borderRadius = BorderRadius.circular(30);
    } else if (widget.type.contains('square')) {
      borderRadius = BorderRadius.zero;
    } else {
      borderRadius = BorderRadius.circular(8);
    }

    InputDecoration inputDecoration;
    switch (widget.type) {
      case 'filled-circle':
        inputDecoration = InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: borderRadius,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: widget.label ?? 'Select a time',
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
          labelText: widget.label ?? 'Select a time',
          hintText: widget.hintText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          helperText: widget.helperText,
        );
        break;
      case 'filled-square':
        inputDecoration = InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.zero,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 4.0),
          labelText: widget.label ?? 'Select a time',
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
          labelText: widget.label ?? 'Select a time',
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
          labelText: widget.label ?? 'Select a time',
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
          labelText: widget.label ?? 'Select a time',
          hintText: widget.hintText,
          prefixIcon: !widget.isFloatLabel ? widget.prefix : null,
          suffixIcon: isClearable,
          helperText: widget.helperText,
        );
    }

    return _applyAnimations( Visibility(
        visible: true,
        child: SizedBox(
          // width: size.width,
          // height: size.height,
          child: TextFormField(
            controller: _controller,
            decoration: inputDecoration,
            readOnly: true,
            enabled: !widget.isDisabled,
            onTap: !widget.isDisabled ? _selectTime : (){},
          ),
        ),
      ),
    );
  }

  // Method to show the time picker
  Future<void> _selectTime() async {
    TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: widget.selectedTime ?? TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        _controller.text = _formatTime(selectedTime);
      });
      widget.onChanged?.call(selectedTime);
    }
  }

  String _formatTime(TimeOfDay time) {
    String format = widget.timeFormat ?? 'HH:mm';
    final DateFormat dateFormat = DateFormat(format);
    final DateTime timeAsDateTime = DateTime(0, 0, 0, time.hour, time.minute);
    return dateFormat.format(timeAsDateTime);
  }

}
