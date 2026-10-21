import 'package:flutter/material.dart';
import 'app_manager.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this.manager) {
    manager.addListener(notifyListeners);
  }

  final AppManager manager;
  bool get isLoading => manager.isLoading;
  bool get isLoggedIn => manager.isLoggedIn;

  @override
  void dispose() {
    manager.removeListener(notifyListeners);
    super.dispose();
  }
}
