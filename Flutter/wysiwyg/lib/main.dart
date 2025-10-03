import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wysiwyg/iframe.dart';
import 'package:wysiwyg/provider/global.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GlobalProvider(),
      child: MaterialApp(
        title: 'Provider Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const CanvasWidget(),
      ),
    );
  }
}