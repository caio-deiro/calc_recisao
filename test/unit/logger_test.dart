import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/core/utils/logger.dart';
import 'package:calc_recisao/core/exceptions/app_exceptions.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AppLogger', () {
    test('deve logar mensagem de debug', () {
      // Não deve lançar exceção
      expect(() => AppLogger.debug('Mensagem de debug'), returnsNormally);
    });

    test('deve logar mensagem de info', () {
      expect(() => AppLogger.info('Mensagem de informação'), returnsNormally);
    });

    test('deve logar warning', () {
      expect(() => AppLogger.warning('Aviso'), returnsNormally);
    });

    test('deve logar warning com erro', () {
      final error = Exception('Erro de teste');
      // Logger não deve lançar exceção mesmo sem Firebase
      expect(() => AppLogger.warning('Aviso', error), returnsNormally);
    });

    test('deve logar erro', () {
      // Logger não deve lançar exceção mesmo sem Firebase
      expect(() => AppLogger.error('Erro'), returnsNormally);
    });

    test('deve logar erro com stack trace', () {
      final error = Exception('Erro de teste');
      final stackTrace = StackTrace.current;
      // Logger não deve lançar exceção mesmo sem Firebase
      expect(() => AppLogger.error('Erro', error, stackTrace), returnsNormally);
    });

    test('deve logar exceção customizada', () {
      final exception = ValidationException('Erro de validação');
      // Logger não deve lançar exceção mesmo sem Firebase
      expect(() => AppLogger.exception(exception), returnsNormally);
    });

    test('deve logar evento', () {
      expect(() => AppLogger.event('test_event', {'param': 'value'}), returnsNormally);
    });

    test('deve logar evento sem parâmetros', () {
      expect(() => AppLogger.event('test_event', null), returnsNormally);
    });
  });
}

