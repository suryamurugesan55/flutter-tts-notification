import 'package:flutter/foundation.dart';

class PrintUtils {
  static void printValue(String title, String value) {
    if (kDebugMode) {
      print('$title $value');
    }
  }
}
