import 'package:flutter/foundation.dart';

/// API Debugger utility untuk membantu debugging API calls
class ApiDebugger {
  static bool get isDebugMode => kDebugMode;

  /// Log API request
  static void logRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!isDebugMode) return;

    print('\n' + '=' * 60);
    print('🚀 API REQUEST');
    print('=' * 60);
    print('Method: $method');
    print('URL: $url');
    if (headers != null && headers.isNotEmpty) {
      print('Headers:');
      headers.forEach((key, value) {
        if (key.toLowerCase() == 'authorization') {
          print(
            '  $key: ${value.length > 20 ? "${value.substring(0, 20)}..." : value}',
          );
        } else {
          print('  $key: $value');
        }
      });
    }
    if (body != null) {
      print('Body: $body');
    }
    print('=' * 60 + '\n');
  }

  /// Log API response
  static void logResponse(int statusCode, String body, {String? endpoint}) {
    if (!isDebugMode) return;

    print('\n' + '=' * 60);
    print('📡 API RESPONSE${endpoint != null ? ' - $endpoint' : ''}');
    print('=' * 60);
    print('Status Code: $statusCode');
    print('Body Length: ${body.length} characters');

    // Try to parse and pretty print JSON
    try {
      print('Response Body (truncated):');
      if (body.length > 500) {
        print(body.substring(0, 500) + '...');
      } else {
        print(body);
      }
    } catch (e) {
      print('Body: $body');
    }
    print('=' * 60 + '\n');
  }

  /// Log error
  static void logError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
  }) {
    if (!isDebugMode) return;

    print('\n' + '=' * 60);
    print('❌ ERROR - $context');
    print('=' * 60);
    print('Error: $error');
    if (stackTrace != null) {
      print('Stack Trace:');
      print(stackTrace.toString().split('\n').take(5).join('\n'));
    }
    print('=' * 60 + '\n');
  }

  /// Log data processing
  static void logData(String label, dynamic data) {
    if (!isDebugMode) return;

    print('\n' + '-' * 40);
    print('📊 DATA - $label');
    print('-' * 40);
    print('Type: ${data.runtimeType}');
    if (data is List) {
      print('Length: ${data.length}');
      if (data.isNotEmpty) {
        print('First item: ${data.first}');
      }
    } else if (data is Map) {
      print('Keys: ${data.keys.toList()}');
    } else {
      print('Value: $data');
    }
    print('-' * 40 + '\n');
  }

  /// Log success
  static void logSuccess(String message) {
    if (!isDebugMode) return;

    print('✅ SUCCESS: $message');
  }

  /// Log warning
  static void logWarning(String message) {
    if (!isDebugMode) return;

    print('⚠️  WARNING: $message');
  }

  /// Log info
  static void logInfo(String message) {
    if (!isDebugMode) return;

    print('ℹ️  INFO: $message');
  }
}
