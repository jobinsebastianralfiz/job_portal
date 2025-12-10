class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// Server Exceptions
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error occurred',
    super.code,
    super.details,
  });
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code,
    super.details,
  });
}

class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.code,
    super.details,
  });
}

// Authentication Exceptions
class AuthException extends AppException {
  const AuthException({
    super.message = 'Authentication error',
    super.code,
    super.details,
  });
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Unauthorized access',
    super.code,
    super.details,
  });
}

class SessionExpiredException extends AppException {
  const SessionExpiredException({
    super.message = 'Session expired',
    super.code,
    super.details,
  });
}

// Firebase Exceptions
class FirebaseException extends AppException {
  const FirebaseException({
    super.message = 'Firebase error',
    super.code,
    super.details,
  });
}

class DocumentNotFoundException extends AppException {
  const DocumentNotFoundException({
    super.message = 'Document not found',
    super.code,
    super.details,
  });
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException({
    super.message = 'Permission denied',
    super.code,
    super.details,
  });
}

// Storage Exceptions
class StorageException extends AppException {
  const StorageException({
    super.message = 'Storage error',
    super.code,
    super.details,
  });
}

class FileUploadException extends AppException {
  const FileUploadException({
    super.message = 'File upload failed',
    super.code,
    super.details,
  });
}

// Cache Exceptions
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error',
    super.code,
    super.details,
  });
}

// Validation Exceptions
class ValidationException extends AppException {
  const ValidationException({
    super.message = 'Validation error',
    super.code,
    super.details,
  });
}

// Payment Exceptions
class PaymentException extends AppException {
  const PaymentException({
    super.message = 'Payment error',
    super.code,
    super.details,
  });
}

// Parsing Exceptions
class ParsingException extends AppException {
  const ParsingException({
    super.message = 'Parsing error',
    super.code,
    super.details,
  });
}
