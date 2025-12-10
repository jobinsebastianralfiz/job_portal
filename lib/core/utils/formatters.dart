import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  // Date Formatters
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateLong(DateTime date) {
    return DateFormat('EEEE, MMMM dd, yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  static String formatDateTimeShort(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  // Relative Time
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Currency Formatters
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
    return formatter.format(amount);
  }

  static String formatCurrencyRange(double min, double max, {String symbol = '\$'}) {
    return '${formatCurrency(min, symbol: symbol)} - ${formatCurrency(max, symbol: symbol)}';
  }

  static String formatSalary(double? min, double? max, String salaryType, {String currency = '\$'}) {
    if (min == null && max == null) {
      return 'Negotiable';
    }

    String suffix;
    switch (salaryType.toLowerCase()) {
      case 'hourly':
        suffix = '/hr';
        break;
      case 'daily':
        suffix = '/day';
        break;
      case 'weekly':
        suffix = '/week';
        break;
      case 'monthly':
        suffix = '/month';
        break;
      default:
        suffix = '';
    }

    if (min != null && max != null) {
      return '${formatCurrency(min, symbol: currency)} - ${formatCurrency(max, symbol: currency)}$suffix';
    } else if (min != null) {
      return 'From ${formatCurrency(min, symbol: currency)}$suffix';
    } else {
      return 'Up to ${formatCurrency(max!, symbol: currency)}$suffix';
    }
  }

  // Number Formatters
  static String formatNumber(int number) {
    return NumberFormat('#,##0').format(number);
  }

  static String formatCompactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  // Phone Number Formatter
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }

  // File Size Formatter
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Name Formatter
  static String formatFullName(String firstName, String lastName) {
    return '${_capitalizeFirst(firstName)} ${_capitalizeFirst(lastName)}';
  }

  static String formatInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0].toUpperCase() : ''}${lastName.isNotEmpty ? lastName[0].toUpperCase() : ''}';
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Experience Formatter
  static String formatExperience(int years) {
    if (years == 0) {
      return 'Fresher';
    } else if (years == 1) {
      return '1 year';
    } else {
      return '$years years';
    }
  }

  // Duration Formatter
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return '${duration.inSeconds} second${duration.inSeconds > 1 ? 's' : ''}';
    }
  }

  // Truncate Text
  static String truncateText(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$ellipsis';
  }

  // Slug Formatter
  static String toSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }
}
