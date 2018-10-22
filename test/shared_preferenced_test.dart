import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main(){
  const MethodChannel('plugins.flutter.io/shared_preferences')
  .setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, dynamic>{}; // set initial values here if desired
    }
    return null;
  });
  SharedPreferences.setMockInitialValues(<String, dynamic>{});
}