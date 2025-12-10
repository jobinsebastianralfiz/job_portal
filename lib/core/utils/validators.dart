import 'package:email_validator/email_validator.dart';

class Validators {
  Validators._();

  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  // Confirm Password Validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Name Validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters';
    }
    return null;
  }

  // Phone Number Validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    // Remove spaces, dashes, and parentheses
    final cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(cleanNumber)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // Optional Phone Validation
  static String? validatePhoneOptional(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return validatePhone(value);
  }

  // Required Field Validation
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Min Length Validation
  static String? validateMinLength(String? value, int minLength, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  // Max Length Validation
  static String? validateMaxLength(String? value, int maxLength, [String fieldName = 'This field']) {
    if (value != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  // URL Validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    if (!urlPattern.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  // Number Validation
  static String? validateNumber(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  // Positive Number Validation
  static String? validatePositiveNumber(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  // Salary Range Validation
  static String? validateSalaryRange(String? minSalary, String? maxSalary) {
    if (minSalary == null || minSalary.isEmpty) return null;
    if (maxSalary == null || maxSalary.isEmpty) return null;

    final min = double.tryParse(minSalary);
    final max = double.tryParse(maxSalary);

    if (min == null || max == null) {
      return 'Please enter valid salary amounts';
    }
    if (min > max) {
      return 'Minimum salary cannot be greater than maximum';
    }
    return null;
  }

  // Skills Validation
  static String? validateSkills(List<String>? skills, {int minCount = 1}) {
    if (skills == null || skills.isEmpty) {
      return 'Please add at least $minCount skill${minCount > 1 ? 's' : ''}';
    }
    if (skills.length < minCount) {
      return 'Please add at least $minCount skill${minCount > 1 ? 's' : ''}';
    }
    return null;
  }

  // Zip Code Validation
  static String? validateZipCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Zip code is required';
    }
    if (!RegExp(r'^[0-9]{5,10}$').hasMatch(value)) {
      return 'Please enter a valid zip code';
    }
    return null;
  }

  // Date Validation (not in past)
  static String? validateFutureDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }
    if (date.isBefore(DateTime.now())) {
      return 'Date cannot be in the past';
    }
    return null;
  }

  // File Size Validation
  static String? validateFileSize(int sizeInBytes, int maxSizeInBytes) {
    if (sizeInBytes > maxSizeInBytes) {
      final maxSizeMB = (maxSizeInBytes / (1024 * 1024)).toStringAsFixed(0);
      return 'File size cannot exceed ${maxSizeMB}MB';
    }
    return null;
  }

  // File Extension Validation
  static String? validateFileExtension(String fileName, List<String> allowedExtensions) {
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Allowed formats: ${allowedExtensions.join(', ')}';
    }
    return null;
  }
}
