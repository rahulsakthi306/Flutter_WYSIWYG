import 'package:flutter/material.dart';

class TSwitch extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool isDisabled;
  final String leftContent;
  final String rightContent;

  const TSwitch({
    super.key,
    this.value,
    this.onChanged,
    this.label,
    this.isDisabled = false,
    this.leftContent = '',
    this.rightContent = '',
  });

  @override
  Widget build(BuildContext context) {
    Widget switchWidget = Switch(
      activeColor: Theme.of(context).primaryColor,
      value: value ?? false,
      onChanged: isDisabled ? null : onChanged,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leftContent.isNotEmpty) ...[
          Text(leftContent),
          SizedBox(width: 8.0),
        ],
        switchWidget,
        if (rightContent.isNotEmpty) ...[
          SizedBox(width: 8.0),
          Text(rightContent),
        ],
      ],
    );
  }
}
