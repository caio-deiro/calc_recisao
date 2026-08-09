import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../exceptions/app_exceptions.dart';

/// Verifica se Firebase está disponível
bool _isFirebaseAvailable() {
  try {
    // Tenta acessar a instância - se não estiver disponível, lança exceção
    final _ = FirebaseCrashlytics.instance;
    return true;
  } catch (e) {
    return false;
  }
}

/// Logger estruturado para a aplicação
/// 
/// Centraliza logging e reporta erros ao Firebase Crashlytics
class AppLogger {
  static const String _tag = '[CalcRescisao]';

  /// Log de debug (apenas em modo debug)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_tag DEBUG: $message');
      if (error != null) {
        debugPrint('$_tag ERROR: $error');
        if (stackTrace != null) {
          debugPrint('$_tag STACK: $stackTrace');
        }
      }
    }
  }

  /// Log de informação
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('$_tag INFO: $message');
    }
  }

  /// Log de aviso
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('$_tag WARNING: $message');
    if (error != null) {
      debugPrint('$_tag ERROR: $error');
    }

    // Reportar ao Crashlytics como não-fatal
    if (error != null && _isFirebaseAvailable()) {
      try {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace ?? StackTrace.current,
          reason: message,
        );
      } catch (e) {
        // Ignorar se Firebase não estiver disponível
      }
    }
  }

  /// Log de erro
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    debugPrint('$_tag ERROR: $message');
    if (error != null) {
      debugPrint('$_tag ERROR DETAILS: $error');
      if (stackTrace != null) {
        debugPrint('$_tag STACK TRACE: $stackTrace');
      }
    }

    // Reportar ao Crashlytics
    if (_isFirebaseAvailable()) {
      try {
        if (error != null) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace ?? StackTrace.current,
            reason: message,
          );
        } else {
          // Se não há erro específico, criar um
          FirebaseCrashlytics.instance.log(message);
        }
      } catch (e) {
        // Ignorar se Firebase não estiver disponível
      }
    }
  }

  /// Log de exceção customizada
  static void exception(AppException exception, [StackTrace? stackTrace]) {
    error(
      exception.message,
      exception.originalError ?? exception,
      stackTrace,
    );

    // Adicionar contexto adicional
    if (exception.code != null && _isFirebaseAvailable()) {
      try {
        FirebaseCrashlytics.instance.setCustomKey('error_code', exception.code!);
      } catch (e) {
        // Ignorar se Firebase não estiver disponível
      }
    }
  }

  /// Log de evento de negócio
  static void event(String eventName, Map<String, dynamic>? parameters) {
    info('Event: $eventName ${parameters != null ? 'with params: $parameters' : ''}');
    
    // Em produção, isso seria enviado ao Firebase Analytics
    // FirebaseAnalytics.instance.logEvent(
    //   name: eventName,
    //   parameters: parameters,
    // );
  }
}

