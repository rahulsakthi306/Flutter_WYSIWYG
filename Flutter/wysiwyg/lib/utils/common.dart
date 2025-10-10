import 'dart:convert';

import 'package:flutter/material.dart';

TextOverflow _mapTextOverflow(String value) {
  const map = {
    'clip': TextOverflow.clip,
    'ellipsis': TextOverflow.ellipsis,
    'fade': TextOverflow.fade,
  };
  return map[value] ?? TextOverflow.fade;
}

TextAlign _mapTextAlign(String value) {
  switch (value) {
    case 'start':
      return TextAlign.start;
    case 'end':
      return TextAlign.end;
    case 'left':
      return TextAlign.left;
    case 'right':
      return TextAlign.right;
    case 'center':
      return TextAlign.center;
    case 'justify':
      return TextAlign.justify;
    default:
      return TextAlign.start;
  }
}

TextAlignVertical _mapTextAlignVertical(String value) {
  switch (value) {
    case 'top':
      return TextAlignVertical.top;
    case 'center':
      return TextAlignVertical.center;
    case 'bottom':
      return TextAlignVertical.bottom;
    default:
      return TextAlignVertical.center;
  }
}

MainAxisAlignment _mapMainAxisAlignment(String value) {
  switch (value) {
    case 'start':
      return MainAxisAlignment.start;
    case 'end':
      return MainAxisAlignment.end;
    case 'center':
      return MainAxisAlignment.center;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return MainAxisAlignment.start;
  }
}

TextInputType _mapKeyboardType(String value) {
  switch (value) {
    case 'text':
      return TextInputType.text;
    case 'number':
      return TextInputType.number;
    case 'email':
      return TextInputType.emailAddress;
    case 'phone':
      return TextInputType.phone;
    case 'url':
      return TextInputType.url;
    case 'multiline':
      return TextInputType.multiline;
    default:
      return TextInputType.text;
  }
}

FontWeight _mapFontWeight(String value) {
  const map = {
    'w100': FontWeight.w100,
    'w200': FontWeight.w200,
    'w300': FontWeight.w300,
    'w400': FontWeight.w400,
    'w500': FontWeight.w500,
    'w600': FontWeight.w600,
    'w700': FontWeight.w700,
    'w800': FontWeight.w800,
    'w900': FontWeight.w900,
    'normal': FontWeight.w400,
    'bold': FontWeight.w700,
  };
  return map[value] ?? FontWeight.normal;
}

Widget? _buildPrefixSuffix(String value) {
  if (value.isEmpty) return null;
  return Text(value);
}

Map<String, dynamic> deepCopy(Map<String, dynamic> source) {
  return json.decode(json.encode(source)) as Map<String, dynamic>;
}
