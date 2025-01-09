import 'package:flutter/material.dart';

class ModeNotifier with ChangeNotifier {
  String _label = '';
  int? _bytesValue;

  String get label => _label;

  void setLabel(String value) {
    _label = value;
    notifyListeners();
  }

  int? get bytesValue => _bytesValue;

  void setBytesValue(int? value) {
    _bytesValue = value;
    notifyListeners();
  }
}
