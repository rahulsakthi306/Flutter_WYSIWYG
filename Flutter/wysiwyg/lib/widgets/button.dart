import 'package:flutter/material.dart';

List<String> type = [
  'elevated-circle',
  'filled-circle',
  'outlined-circle',
  'icon-circle',
  'elevated-square',
  'filled-square',
  'outlined-square',
  'icon-square',
  'tonal'
];

List<String> size = ['small', 'medium', 'large', 'block'];

List<String> buttonVariant = ['primary', 'success', 'error', 'warning', 'info'];

class TBUtton extends StatefulWidget {
  final String type;
  final String? variant;
  final String? label;
  final VoidCallback? onPressed;
  final String size;
  final Icon? icon;
  final bool isDisabled;
  final bool enableSpinner;
  final String spinnerPosition;
  final Map<String, dynamic>? formData;
  final VoidCallback? callback;
  final GlobalKey<FormState>? formKey;

  const TBUtton({
    super.key,
    this.type = 'elevated-circle',
    this.variant,
    this.size = 'medium',
    this.isDisabled = false,
    this.icon,
    this.enableSpinner = false,
    this.spinnerPosition = 'left',
    this.label,
    this.onPressed,
    this.formData, 
    this.callback, 
    this.formKey,
  });

  @override
  State<TBUtton> createState() => _TBUttonState();
}

class _TBUttonState extends State<TBUtton> {
  Size _getsize(String size) {
    switch (size) {
      case 'small':
        return Size(120, 40);
      case 'medium':
        return Size(200, 48);
      case 'large':
        return Size(300, 56);
      case 'block':
        return Size(double.infinity, 56);
      default:
        return Size(200, 48);
    }
  }

  Color _getButtonColor(String variant) {
    switch (variant) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    String labelText = widget.label ?? 'Click here';
    final size = _getsize(widget.size);
    final buttonColor = _getButtonColor(widget.variant ?? '');
    final isDisabled = widget.isDisabled;

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(size),
      backgroundColor: WidgetStatePropertyAll(
        isDisabled ? buttonColor.withAlpha(128) : buttonColor,
      ),
      foregroundColor: WidgetStatePropertyAll(
        isDisabled ? Colors.grey : Colors.white,
      ),
      overlayColor: WidgetStatePropertyAll(
          isDisabled ? Colors.transparent : buttonColor.withAlpha(80)),
      elevation: WidgetStatePropertyAll(isDisabled ? 0 : 4),
    );

    final textStyle = Theme.of(context).textTheme.titleMedium;

    Widget buttonContent;
    if (widget.enableSpinner) {
      Widget spinner = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: isDisabled ? Colors.grey : Theme.of(context).indicatorColor,
          strokeWidth: 2,
        ),
      );

      switch (widget.spinnerPosition) {
        case 'left':
          buttonContent = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              spinner,
              SizedBox(width: 12),
              Text(labelText, style: textStyle),
            ],
          );
          break;
        case 'right':
          buttonContent = Row(
            mainAxisSize: MainAxisSize.min, // Prevents the Row from expanding
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(labelText, style: textStyle),
              SizedBox(width: 12),
              spinner,
            ],
          );
          break;
        case 'center':
        default:
          buttonContent = Row(
            mainAxisSize: MainAxisSize.min, // Prevents the Row from expanding
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              spinner,
              SizedBox(width: 12),
              Text(labelText, style: textStyle),
            ],
          );
          break;
      }
    } else {
      buttonContent = widget.icon == null
          ? Text(labelText, style: textStyle)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon!,
                SizedBox(width: 12),
                Text(
                  labelText,
                  style: textStyle,
                ),
              ],
            );
    }

    Widget buildButton(Widget buttonChild, ButtonStyle buttonStyle) {
      return ElevatedButton(
        onPressed: isDisabled ? null : (){
        },
        style: buttonStyle,
        child: buttonChild,
      );
    }

    switch (widget.type) {
      case 'elevated-circle':
        return buildButton(buttonContent, buttonStyle);
      case 'elevated-square':
        return buildButton(
          buttonContent,
          buttonStyle.copyWith(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            )),
          ),
        );
      case 'filled-circle':
        return buildButton(buttonContent, buttonStyle);
      case 'tonal':
        return buildButton(buttonContent, buttonStyle);
      case 'outlined-circle':
        return buildButton(buttonContent, buttonStyle);
      case 'filled-square':
        return buildButton(
          buttonContent,
          buttonStyle.copyWith(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            )),
          ),
        );
      case 'outlined-square':
        return buildButton(
          buttonContent,
          buttonStyle.copyWith(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            )),
          ),
        );
      case 'icon-circle':
        return ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: buttonStyle.copyWith(
            shape: WidgetStatePropertyAll(CircleBorder()),
            padding: WidgetStatePropertyAll(EdgeInsets.all(20)),
          ),
          child: widget.icon ?? Icon(Icons.error),
        );
      case 'icon-square':
        return ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: buttonStyle.copyWith(
            shape: WidgetStatePropertyAll(RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            )),
            padding: WidgetStatePropertyAll(EdgeInsets.all(20)),
          ),
          child: widget.icon ?? Icon(Icons.error),
        );
      default:
        return buildButton(buttonContent, buttonStyle);
    }
  }
}