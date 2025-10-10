import 'package:flutter/material.dart';

class GlobalProvider with ChangeNotifier{
  Map<String, dynamic> _canvasNodes = {};
  Map<String, dynamic> _currentNode = {};
  Map<String, dynamic> get canvasNodes => _canvasNodes;
  Map<String, dynamic> get currentNode => _currentNode;

  void setCanvasNodes(Map<String, dynamic> value){
    _canvasNodes = value;
    notifyListeners();
  }

  void setCurrentNode(Map<String, dynamic> value){
    _currentNode = value;
    notifyListeners();
  }  
}