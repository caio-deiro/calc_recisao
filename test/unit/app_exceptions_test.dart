import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/core/exceptions/app_exceptions.dart';

void main() {
  group('AppException', () {
    test('deve criar CalculationException corretamente', () {
      final exception = CalculationException('Erro no cálculo', code: 'CALC_001');

      expect(exception.message, 'Erro no cálculo');
      expect(exception.code, 'CALC_001');
      expect(exception.toString(), 'Erro no cálculo');
    });

    test('deve criar ValidationException com fieldErrors', () {
      final fieldErrors = {'field1': 'Erro 1', 'field2': 'Erro 2'};
      final exception = ValidationException(
        'Dados inválidos',
        fieldErrors: fieldErrors,
      );

      expect(exception.message, 'Dados inválidos');
      expect(exception.fieldErrors, fieldErrors);
    });

    test('deve criar StorageException corretamente', () {
      final originalError = Exception('Erro original');
      final exception = StorageException(
        'Erro ao salvar',
        originalError: originalError,
      );

      expect(exception.message, 'Erro ao salvar');
      expect(exception.originalError, originalError);
    });

    test('deve criar ServiceException corretamente', () {
      final exception = ServiceException('Erro no serviço', code: 'SVC_001');

      expect(exception.message, 'Erro no serviço');
      expect(exception.code, 'SVC_001');
    });

    test('deve criar NotFoundException corretamente', () {
      final exception = NotFoundException('Item não encontrado');

      expect(exception.message, 'Item não encontrado');
    });

    test('deve criar PermissionException corretamente', () {
      final exception = PermissionException('Permissão negada');

      expect(exception.message, 'Permissão negada');
    });
  });
}

