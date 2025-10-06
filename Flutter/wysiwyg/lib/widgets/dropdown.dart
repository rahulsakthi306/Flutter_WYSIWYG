import 'package:flutter/material.dart';

List<String> type = [
 'filled-circle',
  'outlined-circle',
  'filled-square',
  'outlined-square',
  'underlined',
];

List<String> size = ['small', 'medium', 'large', 'max'];

class TDropdown extends StatefulWidget {
  final String type;
  final String size;
  final String? hintText;
  final bool isDisabled;
  final String? label;
  final List<String> items;
  final String? selectedItem;
  final void Function(String?)? onChanged;
  final String? helperText;
  final bool searchable;


  const TDropdown({
    super.key,
    this.type = 'underlined',
    this.size = 'max',
    this.hintText,
    this.isDisabled = false,
    this.label,
    this.items = const ['ko','egh','ertger'],
    this.selectedItem,
    this.onChanged,
     this.helperText,
      this.searchable = false,
  });

  @override
  State<TDropdown> createState() => _TDropdownState();
}

class _TDropdownState extends State<TDropdown> {
  @override
  Widget build(BuildContext context) {
    String labelText = widget.label ?? 'Select an option';
    Size size = _getSize(widget.size);

    BorderRadius borderRadius;

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
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: borderRadius,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16,horizontal: 12),
          labelText: labelText,
          hintText: widget.hintText,
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
          labelText: labelText,
          hintText: widget.hintText,
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
           helperText: widget.helperText,
        );
    }

    return SizedBox(
      width: size.width,
      // height: size.height,
      child: DropdownButtonFormField<String>(
        decoration: inputDecoration,
        value: widget.selectedItem,
        items: widget.items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: widget.isDisabled ? null : widget.onChanged,
      ),
    );
  }

  Size _getSize(String size) {
    switch (size) {
      case 'small':
        return Size(120, 40);
      case 'medium':
        return Size(200, 48);
      case 'large':
        return Size(300, 56);
      case 'max':
        return Size(double.infinity, 56); 
      default:
        return Size(200, 48);
    }
  }
}
