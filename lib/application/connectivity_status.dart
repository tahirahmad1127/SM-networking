import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class InternetConnectivityHelper extends ChangeNotifier {
  static Future<bool> checkConnectivity() async {
    if (kIsWeb) {
      return true;
    } else {
      try {
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(const Duration(seconds: 50));
//         return true;
        return response.statusCode == 200;
      } on SocketException catch (e) {
        return false;
      } on TimeoutException catch (e) {
        return false;
      }
    }
  }
}
