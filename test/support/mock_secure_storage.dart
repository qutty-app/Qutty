// Secure storage is disabled. Tokens are stored in shared_preferences now, so
// this mock and its channel are no longer registered by the test suite.
// Uncomment to restore the previous secure storage test harness.
//
// import 'package:flutter/services.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// final _secureValues = <String, String>{};
//
// void resetMockSecureStorage([Map<String, String> values = const {}]) {
//   _secureValues
//     ..clear()
//     ..addAll(values);
// }
//
// void setupMockSecureStorage() {
//   TestWidgetsFlutterBinding.ensureInitialized();
//
//   const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
//   TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//       .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         switch (methodCall.method) {
//           case 'read':
//             return _secureValues[methodCall.arguments['key'] as String];
//           case 'write':
//             _secureValues[methodCall.arguments['key'] as String] =
//                 methodCall.arguments['value'] as String;
//             return null;
//           case 'delete':
//             _secureValues.remove(methodCall.arguments['key'] as String);
//             return null;
//           case 'deleteAll':
//             _secureValues.clear();
//             return null;
//           case 'readAll':
//             return Map<String, String>.from(_secureValues);
//           case 'containsKey':
//             return _secureValues.containsKey(
//               methodCall.arguments['key'] as String,
//             );
//           default:
//             return null;
//         }
//       });
// }
