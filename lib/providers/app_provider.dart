import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  String _currentAgent = '';
  bool _isLoading = false;

  String get currentAgent => _currentAgent;
  bool get isLoading => _isLoading;

  void setCurrentAgent(String agent) {
    _currentAgent = agent;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
