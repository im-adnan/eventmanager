import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext get currentContext => navigatorKey.currentContext!;

  static Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  static Future<dynamic> navigateReplacementTo(String routeName) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName);
  }

  static void goBack() {
    navigatorKey.currentState!.pop();
  }
}
