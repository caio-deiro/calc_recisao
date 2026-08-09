import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/core/validators/termination_input_validator.dart';
import 'package:calc_recisao/core/exceptions/app_exceptions.dart';

void main() {
  group('TerminationInputValidator', () {
    test('deve validar input válido', () {
      final input = TerminationInput(
        admissionDate: DateTime(2023, 1, 1),
        terminationDate: DateTime(2024, 1, 1),
        baseSalary: 3000.0,
        averageAdditions: 500.0,
      );

      final result = TerminationInputValidator.validate(input);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.fieldErrors, isEmpty);
    });

    test('deve rejeitar data de admissão no futuro', () {
      final input = TerminationInput(
        admissionDate: DateTime(2025, 12, 31),
        terminationDate: DateTime(2024, 1, 1),
        baseSalary: 3000.0,
      );

      final result = TerminationInputValidator.validate(input);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('Data de admissão não pode ser no futuro'));
      expect(result.fieldErrors['admissionDate'], isNotNull);
    });

    test('deve rejeitar data de rescisão antes da admissão', () {
      final input = TerminationInput(
        admissionDate: DateTime(2024, 1, 1),
        terminationDate: DateTime(2023, 1, 1),
        baseSalary: 3000.0,
      );

      final result = TerminationInputValidator.validate(input);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('Data de rescisão deve ser posterior à data de admissão'));
      expect(result.fieldErrors['terminationDate'], isNotNull);
    });

    test('deve rejeitar salário zero ou negativo', () {
      final input = TerminationInput(
        admissionDate: DateTime(2023, 1, 1),
        terminationDate: DateTime(2024, 1, 1),
        baseSalary: 0.0,
      );

      final result = TerminationInputValidator.validate(input);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('Salário base deve ser maior que zero'));
      expect(result.fieldErrors['baseSalary'], isNotNull);
    });

    test('deve rejeitar salário muito alto', () {
      final input = TerminationInput(
        admissionDate: DateTime(2023, 1, 1),
        terminationDate: DateTime(2024, 1, 1),
        baseSalary: 2000000.0, // R$ 2.000.000
      );

      final result = TerminationInputValidator.validate(input);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Salário base muito alto')), isTrue);
      expect(result.fieldErrors['baseSalary'], isNotNull);
    });

    test('deve rejeitar adições médias negativas', () {
      final input = TerminationInput(
        admissionDate: DateTime(2023, 1, 1),
        terminationDate: DateTime(2024, 1, 1),
        baseSalary: 3000.0,
        averageAdditions: -100.0,
      );

      final result = TerminationInputValidator.validate(input);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('Adições médias não podem ser negativas'));
      expect(result.fieldErrors['averageAdditions'], isNotNull);
    });

    test('deve rejeitar dependentes negativos', () {
      final input = TerminationInput(
        admissionDate: DateTime(2023, 1, 1),
        terminationDate: DateTime(2024, 1, 1),
        baseSalary: 3000.0,
        dependents: -1,
      );

      final result = TerminationInputValidator.validate(input);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('Número de dependentes não pode ser negativo'));
      expect(result.fieldErrors['dependents'], isNotNull);
    });

    test('deve rejeitar dependentes muito altos', () {
      final input = TerminationInput(
        admissionDate: DateTime(2023, 1, 1),
        terminationDate: DateTime(2024, 1, 1),
        baseSalary: 3000.0,
        dependents: 25,
      );

      final result = TerminationInputValidator.validate(input);

      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Número de dependentes muito alto')), isTrue);
      expect(result.fieldErrors['dependents'], isNotNull);
    });

    test('deve rejeitar dias trabalhados inválidos', () {
      final input = TerminationInput(
        admissionDate: DateTime(2023, 1, 1),
        terminationDate: DateTime(2024, 1, 1),
        baseSalary: 3000.0,
        workedDaysInMonth: 35, // Mais que 31 dias
      );

      final result = TerminationInputValidator.validate(input);

      expect(result.isValid, isFalse);
      expect(result.errors, contains('Dias trabalhados no mês devem estar entre 0 e 31'));
      expect(result.fieldErrors['workedDaysInMonth'], isNotNull);
    });

    test('deve lançar exceção quando validateAndThrow é chamado com dados inválidos', () {
      final input = TerminationInput(
        admissionDate: DateTime(2024, 1, 1),
        terminationDate: DateTime(2023, 1, 1), // Data inválida
        baseSalary: 3000.0,
      );

      expect(
        () => TerminationInputValidator.validateAndThrow(input),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

