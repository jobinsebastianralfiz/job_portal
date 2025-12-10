class ApiConstants {
  ApiConstants._();

  // Gemini AI
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  // Note: Store API key securely, not in code
  // Use environment variables or secure storage
  static const String geminiModel = 'gemini-1.5-flash';

  // Google Maps
  static const String googleMapsBaseUrl = 'https://maps.googleapis.com/maps/api';
  // Note: Store API key securely

  // Stripe
  static const String stripeBaseUrl = 'https://api.stripe.com/v1';
  // Note: Store API keys securely

  // Agora
  static const String agoraAppId = ''; // Set in environment
  // Note: Store credentials securely

  // API Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Retry Configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
}
