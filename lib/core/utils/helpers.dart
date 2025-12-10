import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../../main.dart' show scaffoldMessengerKey;

class Helpers {
  Helpers._();

  // Show Snackbar (context-based - use when context is guaranteed valid)
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.error
            : isSuccess
                ? AppColors.success
                : null,
        duration: duration,
        action: action,
      ),
    );
  }

  // Show Snackbar safely (without context - use for async operations)
  static void showSnackBarSafe(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppColors.error
            : isSuccess
                ? AppColors.success
                : null,
        duration: duration,
      ),
    );
  }

  // Show Loading Dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message ?? 'Please wait...'),
            ],
          ),
        ),
      ),
    );
  }

  // Hide Loading Dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Show Confirmation Dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Copy to Clipboard
  static Future<void> copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showSnackBar(context, 'Copied to clipboard', isSuccess: true);
    }
  }

  // Get Status Color
  static Color getApplicationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.statusPending:
        return AppColors.statusPending;
      case AppConstants.statusReviewed:
        return AppColors.statusReviewed;
      case AppConstants.statusShortlisted:
        return AppColors.statusShortlisted;
      case AppConstants.statusInterview:
        return AppColors.statusInterview;
      case AppConstants.statusOffered:
        return AppColors.statusOffered;
      case AppConstants.statusAccepted:
        return AppColors.statusAccepted;
      case AppConstants.statusRejected:
        return AppColors.statusRejected;
      case AppConstants.statusWithdrawn:
        return AppColors.statusWithdrawn;
      default:
        return AppColors.grey500;
    }
  }

  // Get Job Status Color
  static Color getJobStatusColor(String status) {
    switch (status.toLowerCase()) {
      case AppConstants.jobStatusDraft:
        return AppColors.jobDraft;
      case AppConstants.jobStatusActive:
        return AppColors.jobActive;
      case AppConstants.jobStatusClosed:
        return AppColors.jobClosed;
      case AppConstants.jobStatusExpired:
        return AppColors.jobExpired;
      default:
        return AppColors.grey500;
    }
  }

  // Get Role Color
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case AppConstants.roleJobSeeker:
        return AppColors.jobSeekerColor;
      case AppConstants.roleJobProvider:
        return AppColors.jobProviderColor;
      case AppConstants.roleAdmin:
        return AppColors.adminColor;
      default:
        return AppColors.grey500;
    }
  }

  // Format Status Text
  static String formatStatusText(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }

  // Get File Icon
  static IconData getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Dismiss Keyboard
  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // Check Internet Connection
  static Future<bool> hasInternetConnection() async {
    // Note: In production, use connectivity_plus package
    // This is a simple placeholder
    return true;
  }

  // Generate Unique ID
  static String generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Debounce
  static Function(Function) debounce(Duration duration) {
    DateTime? lastCall;
    return (Function callback) {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) > duration) {
        lastCall = now;
        callback();
      }
    };
  }

  // Get Greeting
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Calculate Age
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Validate File
  static bool isValidFile(String fileName, List<String> allowedExtensions, int maxSizeBytes, int fileSizeBytes) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension) && fileSizeBytes <= maxSizeBytes;
  }
}
