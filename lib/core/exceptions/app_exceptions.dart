/// Exceções customizadas da aplicação
/// 
/// Hierarquia de exceções para tratamento específico de erros
library;

/// Exceção base para todos os erros da aplicação
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Exceção relacionada a cálculos
class CalculationException extends AppException {
  const CalculationException(super.message, {super.code, super.originalError});
}

/// Exceção relacionada a validação de dados
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    super.code,
    super.originalError,
    this.fieldErrors,
  });
}

/// Exceção relacionada a armazenamento de dados
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

/// Exceção relacionada a serviços externos (compras, ads, etc)
class ServiceException extends AppException {
  const ServiceException(super.message, {super.code, super.originalError});
}

/// Exceção relacionada a dados não encontrados
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.originalError});
}

/// Exceção relacionada a permissões ou acesso negado
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError});
}

