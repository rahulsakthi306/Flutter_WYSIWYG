import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:wysiwyg/provider/global.dart';
import 'package:wysiwyg/widgets/avatar.dart';
import 'package:wysiwyg/widgets/button.dart';
import 'package:wysiwyg/widgets/checkbox.dart';
import 'package:wysiwyg/widgets/chip.dart';
import 'package:wysiwyg/widgets/datepicker.dart';
import 'package:wysiwyg/widgets/dropdown.dart';
import 'package:wysiwyg/widgets/icon.dart';
import 'package:wysiwyg/widgets/image.dart';
import 'package:wysiwyg/widgets/progressbar.dart';
import 'package:wysiwyg/widgets/radio.dart';
import 'package:wysiwyg/widgets/slider.dart';
import 'package:wysiwyg/widgets/switch.dart';
import 'package:wysiwyg/widgets/text.dart';
import 'package:wysiwyg/widgets/textarea.dart';
import 'package:wysiwyg/widgets/textinput.dart';
import 'package:wysiwyg/widgets/timepicker.dart';

Widget buildBaseWidget(
    BuildContext context, Map<String, dynamic> w, bool isEdit) {
  final size = w['size'] as Size? ?? const Size(120, 50);
  final type = w['type']?.toString().toLowerCase() ?? 'unknown';
  Widget base;

  switch (type) {
    case 'appbar':
      base = PreferredSize(
        preferredSize: Size(size.width, size.height),
        child: AppBar(
          title: Text(w['label']?.toString() ?? 'AppBar'),
          automaticallyImplyLeading: false,
        ),
      );
      break;
    case 'floatingactionbutton':
      base = SizedBox(
        width: size.width,
        height: size.height,
        child: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Save',
          child: const Icon(Icons.save),
        ),
      );
      break;
    case 'button':
      base = SizedBox(
        width: size.width,
        height: size.height,
        child: TBUtton(
            label: (Provider.of<GlobalProvider>(context, listen: false)
                            .currentNode['label'])?.toString() ?? 'Click Me',
            variant: (Provider.of<GlobalProvider>(context, listen: false)
                            .currentNode['nodeProperty']?['elementInfo']
                        ?['props'] as List?)
                    ?.firstWhere((p) => p is Map && p['name'] == 'variant',
                        orElse: () => null)?['value']
                    ?.toString() ??
                'secondary',
            type: (Provider.of<GlobalProvider>(context, listen: false)
                            .currentNode['nodeProperty']?['elementInfo']
                        ?['props'] as List?)
                    ?.firstWhere((p) => p is Map && p['name'] == 'appearance',
                        orElse: () => null)?['value']
                    ?.toString() ??
                'elevated-circle',
            isDisabled: (() {
              final value = (Provider.of<GlobalProvider>(context, listen: false)
                          .currentNode['nodeProperty']?['elementInfo']?['props']
                      as List?)
                  ?.firstWhere((p) => p is Map && p['name'] == 'isDisabled',
                      orElse: () => null)?['value'];
              return value is bool
                  ? value
                  : bool.tryParse(value?.toString() ?? '') ?? false;
            })(),
            
          ));
      break;
    case 'textinput':
      base = SizedBox(
        child: TTextField(
          type: () {
            final provider =
                Provider.of<GlobalProvider>(context, listen: false);
            final props = provider.currentNode['nodeProperty']?['elementInfo']
                ?['props'] as List?;
            if (props == null || props.isEmpty) {
              return 'outlined-circle';
            }
            final typeProp = props.firstWhere(
              (prop) => prop is Map && prop['name'] == 'appearance',
              orElse: () => null,
            );
            return typeProp?['value'] ?? 'outlined-circle';
          }(),

          hintText: w['label'] ?? 'Enter here',
          //   isDisabled : () {
          //   final provider =
          //       Provider.of<GlobalProvider>(context, listen: false);
          //   final props = provider.currentNode['nodeProperty']?['elementInfo']
          //       ?['props'] as List?;
          //   if (props == null || props.isEmpty) {
          //     return 'false';
          //   }
          //   final isDisabledProp = props.firstWhere(
          //     (prop) => prop is Map && prop['name'] == 'isDisabled',
          //     orElse: () => null,
          //   );
          //   return isDisabledProp?['value'] ?? 'false';
          // }() ,
//             keyboardType: () {
//   final provider = Provider.of<GlobalProvider>(context, listen: false);
//   final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;

//   if (props == null || props.isEmpty) {
//     return TextInputType.name;
//   }

//   final keyboardTypeProp = props.firstWhere(
//     (prop) => prop is Map && prop['name'] == 'keyboardType',
//     orElse: () => null,
//   );
//   final keyboardTypeValue = keyboardTypeProp?['value']?.toString();
//   switch (keyboardTypeValue) {
//     case 'text':
//       return TextInputType.text;
//     case 'number':
//       return TextInputType.number;
//     case 'email':
//       return TextInputType.emailAddress;
//     case 'phone':
//       return TextInputType.phone;
//     case 'url':
//       return TextInputType.url;
//     case 'multiline':
//       return TextInputType.multiline;
//     default:
//       return TextInputType.name;
//   }
// }(),
//             textAlign: () {
//   final provider = Provider.of<GlobalProvider>(context, listen: false);
//   final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;

//   if (props == null || props.isEmpty) {
//     return TextAlign.start; // Default textAlign
//   }

//   final textAlignProp = props.firstWhere(
//     (prop) => prop is Map && prop['name'] == 'textAlign',
//     orElse: () => null,
//   );

//   final textAlignValue = textAlignProp?['value']?.toString();
//   switch (textAlignValue) {
//     case 'start':
//       return TextAlign.start;
//     case 'end':
//       return TextAlign.end;
//     case 'left':
//       return TextAlign.left;
//     case 'right':
//       return TextAlign.right;
//     case 'center':
//       return TextAlign.center;
//     case 'justify':
//       return TextAlign.justify;
//     default:
//       return TextAlign.start; // Default textAlign
//   }
// }(),
//             textAlignVertical: () {
//   final provider = Provider.of<GlobalProvider>(context, listen: false);
//   final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;

//   if (props == null || props.isEmpty) {
//     return TextAlignVertical.center; // Default textAlignVertical
//   }

//   final textAlignVerticalProp = props.firstWhere(
//     (prop) => prop is Map && prop['name'] == 'textAlignVertical',
//     orElse: () => null,
//   );

//   final textAlignVerticalValue = textAlignVerticalProp?['value']?.toString();
//   switch (textAlignVerticalValue) {
//     case 'top':
//       return TextAlignVertical.top;
//     case 'center':
//       return TextAlignVertical.center;
//     case 'bottom':
//       return TextAlignVertical.bottom;
//     default:
//       return TextAlignVertical.center; // Default textAlignVertical
//   }
// }(),
//             showCursor: () {
//               final provider =
//                   Provider.of<GlobalProvider>(context, listen: false);
//               final props = provider.currentNode['nodeProperty']?['elementInfo']
//                   ?['props'] as List?;
//               if (props == null || props.isEmpty) {
//                 return 'false';
//               }
//               final showCursorProp = props.firstWhere(
//                 (prop) => prop is Map && prop['name'] == 'showCursor',
//                 orElse: () => null,
//               );
//               return showCursorProp?['value'] ?? 'false';
//             }() ,
//               helperText: () {
//               final provider =
//                   Provider.of<GlobalProvider>(context, listen: false);
//               final props = provider.currentNode['nodeProperty']?['elementInfo']
//                   ?['props'] as List?;
//               if (props == null || props.isEmpty) {
//                 return '';
//               }
//               final helperTextProp = props.firstWhere(
//                 (prop) => prop is Map && prop['name'] == 'helperText',
//                 orElse: () => null,
//               );
//               return helperTextProp?['value'] ?? '';
//             }() ,
//               prefix: () {
//   final provider = Provider.of<GlobalProvider>(context, listen: false);
//   final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
//   if (props == null || props.isEmpty) {
//     return null; // Default to null for Widget?
//   }
//   final prefixProp = props.firstWhere(
//     (prop) => prop is Map && prop['name'] == 'prefix',
//     orElse: () => null,
//   );
//   final prefixValue = prefixProp?['value']?.toString();
//   if (prefixValue != null && prefixValue.isNotEmpty) {
//     return Text(prefixValue); // Convert string to Text widget
//   }
//   return null;
// }(),
//               suffix: () {
//   final provider = Provider.of<GlobalProvider>(context, listen: false);
//   final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;
//   if (props == null || props.isEmpty) {
//     return null; // Default to null for Widget?
//   }
//   final suffixProp = props.firstWhere(
//     (prop) => prop is Map && prop['name'] == 'suffix',
//     orElse: () => null,
//   );
//   final suffixValue = suffixProp?['value']?.toString();
//   if (suffixValue != null && suffixValue.isNotEmpty) {
//     return Text(suffixValue);
//   }
//   return null;
// }(),
//               needClear: () {
//               final provider =
//                   Provider.of<GlobalProvider>(context, listen: false);
//               final props = provider.currentNode['nodeProperty']?['elementInfo']
//                   ?['props'] as List?;
//               if (props == null || props.isEmpty) {
//                 return 'false';
//               }
//               final needClearProp = props.firstWhere(
//                 (prop) => prop is Map && prop['name'] == 'needClear',
//                 orElse: () => null,
//               );
//               return needClearProp?['value'] ?? 'false';
//             }()  ,
//               label: w['label'] ?? 'Enter here' ,
//               isFloatLabel: () {
//               final provider =
//                   Provider.of<GlobalProvider>(context, listen: false);
//               final props = provider.currentNode['nodeProperty']?['elementInfo']
//                   ?['props'] as List?;
//               if (props == null || props.isEmpty) {
//                 return 'true';
//               }
//               final isFloatLabelProp = props.firstWhere(
//                 (prop) => prop is Map && prop['name'] == 'isFloatLabel',
//                 orElse: () => null,
//               );
//               return isFloatLabelProp?['value'] ?? 'false';
//             }() ,
//               fillColor: () {

//  final provider = Provider.of<GlobalProvider>(context, listen: false);
//   final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;

//   if (props == null || props.isEmpty) {
//     return 'greyShade'; // Default fillColor
//   }

//   final fillColorProp = props.firstWhere(
//     (prop) => prop is Map && prop['name'] == 'fillColor',
//     orElse: () => null,
//   );

//   final fillColorValue = fillColorProp?['value']?.toString();
//   return fillColorValue ?? 'greyShade';
// }(),
//               animationConfig: [],
//               floatingLabelPosition: () {
//   final provider = Provider.of<GlobalProvider>(context, listen: false);
//   final props = provider.currentNode['nodeProperty']?['elementInfo']?['props'] as List?;

//   if (props == null || props.isEmpty) {
//     return MainAxisAlignment.start; // Default floatingLabelPosition
//   }

//   final floatingLabelProp = props.firstWhere(
//     (prop) => prop is Map && prop['name'] == 'floatingLabelPosition',
//     orElse: () => null,
//   );

//   final floatingLabelValue = floatingLabelProp?['value']?.toString();
//   switch (floatingLabelValue) {
//     case 'start':
//       return MainAxisAlignment.start;
//     case 'end':
//       return MainAxisAlignment.end;
//     case 'center':
//       return MainAxisAlignment.center;
//     case 'spaceBetween':
//       return MainAxisAlignment.spaceBetween;
//     case 'spaceAround':
//       return MainAxisAlignment.spaceAround;
//     case 'spaceEvenly':
//       return MainAxisAlignment.spaceEvenly;
//     default:
//       return MainAxisAlignment.start; // Default floatingLabelPosition
//   }
// }(),
        ),
      );
      break;
    case 'group':
      base = SizedBox(
        width: size.width,
        height: size.height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 2.0),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: Center(
              child: Text(w['label']?.toString() ?? 'group',
                  style: const TextStyle(fontSize: 16))),
        ),
      );
      break;
    default:
      base = const SizedBox.shrink();
  }

  return base;
}
