import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/subscription_model.dart';
import '../services/payment/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  // State
  bool _isLoading = false;
  String? _error;
  UserSubscription? _currentSubscription;
  List<UserSubscription> _subscriptionHistory = [];
  Map<String, dynamic>? _jobPostingEligibility;

  // Payment state
  bool _isProcessingPayment = false;
  SubscriptionPlan? _selectedPlan;
  bool _isYearlyBilling = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserSubscription? get currentSubscription => _currentSubscription;
  List<UserSubscription> get subscriptionHistory => _subscriptionHistory;
  Map<String, dynamic>? get jobPostingEligibility => _jobPostingEligibility;
  bool get isProcessingPayment => _isProcessingPayment;
  SubscriptionPlan? get selectedPlan => _selectedPlan;
  bool get isYearlyBilling => _isYearlyBilling;

  // Derived getters
  bool get hasActiveSubscription => _currentSubscription?.isValid ?? false;
  SubscriptionTier get currentTier => _currentSubscription?.tier ?? SubscriptionTier.free;
  SubscriptionPlan get currentPlan => SubscriptionPlans.getPlan(currentTier);
  bool get hasAIAccess => currentPlan.hasAIFeatures && hasActiveSubscription;
  bool get canPostJobs => _jobPostingEligibility?['canPost'] ?? false;
  int get remainingJobPosts => _jobPostingEligibility?['remaining'] ?? 0;

  /// Initialize Razorpay with callbacks
  void initPayment({
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
  }) {
    _subscriptionService.initRazorpay(
      onSuccess: (response) {
        _handlePaymentSuccess(response, onSuccess);
      },
      onError: (response) {
        _handlePaymentError(response, onError);
      },
    );
  }

  /// Dispose Razorpay
  void disposePayment() {
    _subscriptionService.dispose();
  }

  /// Load current subscription for a user
  Future<void> loadCurrentSubscription(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubscription = await _subscriptionService.getCurrentSubscription(userId);
      await checkJobPostingEligibility(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load subscription history
  Future<void> loadSubscriptionHistory(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _subscriptionHistory = await _subscriptionService.getSubscriptionHistory(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check job posting eligibility
  Future<void> checkJobPostingEligibility(String userId) async {
    try {
      _jobPostingEligibility = await _subscriptionService.checkJobPostingEligibility(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Select a plan for purchase
  void selectPlan(SubscriptionPlan plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  /// Toggle yearly/monthly billing
  void toggleBillingCycle() {
    _isYearlyBilling = !_isYearlyBilling;
    notifyListeners();
  }

  void setBillingCycle(bool isYearly) {
    _isYearlyBilling = isYearly;
    notifyListeners();
  }

  /// Start subscription purchase
  void purchaseSubscription({
    required String userId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required SubscriptionPlan plan,
  }) {
    _selectedPlan = plan;
    _isProcessingPayment = true;
    notifyListeners();

    _subscriptionService.startPayment(
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      userPhone: userPhone,
      plan: plan,
      isYearly: _isYearlyBilling,
    );
  }

  /// Handle successful payment
  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
    Function(String) onSuccess,
  ) async {
    if (_selectedPlan == null) {
      _isProcessingPayment = false;
      notifyListeners();
      return;
    }

    try {
      // Extract user ID from notes (you'd need to store this temporarily)
      // For now, we'll handle this in the UI layer
      onSuccess(response.paymentId ?? '');
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  /// Complete subscription after payment verification
  Future<bool> completeSubscription({
    required String userId,
    required String paymentId,
    String? orderId,
  }) async {
    if (_selectedPlan == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final amount = _isYearlyBilling
          ? _selectedPlan!.priceYearly
          : _selectedPlan!.priceMonthly;

      final subscription = await _subscriptionService.createSubscription(
        userId: userId,
        tier: _selectedPlan!.tier,
        isYearly: _isYearlyBilling,
        paymentId: paymentId,
        orderId: orderId,
        amountPaid: amount,
      );

      if (subscription != null) {
        _currentSubscription = subscription;
        _selectedPlan = null;
        await checkJobPostingEligibility(userId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle payment error
  void _handlePaymentError(
    PaymentFailureResponse response,
    Function(String) onError,
  ) {
    _isProcessingPayment = false;
    _error = response.message ?? 'Payment failed';
    notifyListeners();
    onError(_error!);
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String reason) async {
    if (_currentSubscription == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _subscriptionService.cancelSubscription(
        _currentSubscription!.subscriptionId,
        reason,
      );

      if (success) {
        _currentSubscription = _currentSubscription!.copyWith(
          isActive: false,
          cancelledAt: DateTime.now(),
          cancellationReason: reason,
        );
      }

      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if user has access to a specific feature
  bool hasFeatureAccess(String feature) {
    if (!hasActiveSubscription) return false;
    return currentPlan.hasFeature(feature);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedPlan = null;
    _isYearlyBilling = false;
    notifyListeners();
  }
}
