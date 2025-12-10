import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// Server Failures
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred', super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection', super.code});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'Request timed out', super.code});
}

// Authentication Failures
class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication failed', super.code});
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({super.message = 'Invalid email or password', super.code});
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure({super.message = 'User not found', super.code});
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure({super.message = 'Email is already registered', super.code});
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure({super.message = 'Password is too weak', super.code});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Unauthorized access', super.code});
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({super.message = 'Session expired. Please login again', super.code});
}

// Firebase Failures
class FirebaseFailure extends Failure {
  const FirebaseFailure({super.message = 'Firebase error occurred', super.code});
}

class DocumentNotFoundFailure extends Failure {
  const DocumentNotFoundFailure({super.message = 'Document not found', super.code});
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure({super.message = 'Permission denied', super.code});
}

// Storage Failures
class StorageFailure extends Failure {
  const StorageFailure({super.message = 'Storage error occurred', super.code});
}

class FileUploadFailure extends Failure {
  const FileUploadFailure({super.message = 'Failed to upload file', super.code});
}

class FileSizeLimitFailure extends Failure {
  const FileSizeLimitFailure({super.message = 'File size exceeds limit', super.code});
}

class InvalidFileTypeFailure extends Failure {
  const InvalidFileTypeFailure({super.message = 'Invalid file type', super.code});
}

// Cache Failures
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred', super.code});
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure({super.message = 'Validation error', super.code});
}

// Payment Failures
class PaymentFailure extends Failure {
  const PaymentFailure({super.message = 'Payment failed', super.code});
}

class PaymentCancelledFailure extends Failure {
  const PaymentCancelledFailure({super.message = 'Payment was cancelled', super.code});
}

class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure({super.message = 'Insufficient funds', super.code});
}

// General Failures
class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unknown error occurred', super.code});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Resource not found', super.code});
}

class AlreadyExistsFailure extends Failure {
  const AlreadyExistsFailure({super.message = 'Resource already exists', super.code});
}

class OperationCancelledFailure extends Failure {
  const OperationCancelledFailure({super.message = 'Operation was cancelled', super.code});
}
