import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/subscription_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionPlansView extends StatefulWidget {
  const SubscriptionPlansView({super.key});

  @override
  State<SubscriptionPlansView> createState() => _SubscriptionPlansViewState();
}

class _SubscriptionPlansViewState extends State<SubscriptionPlansView> {
  bool _isYearly = false;
  SubscriptionProvider? _subscriptionProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPayment();
    });
  }

  void _initPayment() {
    _subscriptionProvider = context.read<SubscriptionProvider>();
    _subscriptionProvider!.initPayment(
      onSuccess: (paymentId) => _onPaymentSuccess(paymentId),
      onError: (error) => _onPaymentError(error),
    );
  }

  @override
  void dispose() {
    _subscriptionProvider?.disposePayment();
    super.dispose();
  }

  Future<void> _onPaymentSuccess(String paymentId) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final subscriptionProvider = context.read<SubscriptionProvider>();
    final success = await subscriptionProvider.completeSubscription(
      userId: user.userId,
      paymentId: paymentId,
    );

    if (mounted) {
      if (success) {
        // Refresh user data
        await context.read<AuthProvider>().refreshUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subscriptionProvider.error ?? 'Failed to activate subscription'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _onPaymentError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _selectPlan(SubscriptionPlan plan) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    // For free plan, just activate it
    if (plan.tier == SubscriptionTier.free) {
      _activateFreePlan();
      return;
    }

    // Show confirmation dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentConfirmationSheet(
        plan: plan,
        isYearly: _isYearly,
        onConfirm: () {
          Navigator.pop(context);
          _startPayment(plan);
        },
      ),
    );
  }

  Future<void> _activateFreePlan() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final subscriptionProvider = context.read<SubscriptionProvider>();

    // Select the free plan first
    subscriptionProvider.selectPlan(SubscriptionPlans.free);
    subscriptionProvider.setBillingCycle(false);

    final success = await subscriptionProvider.completeSubscription(
      userId: user.userId,
      paymentId: 'free_plan_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (mounted) {
      if (success) {
        await context.read<AuthProvider>().refreshUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Free plan activated!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subscriptionProvider.error ?? 'Failed to activate free plan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _startPayment(SubscriptionPlan plan) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final subscriptionProvider = context.read<SubscriptionProvider>();
    subscriptionProvider.selectPlan(plan);
    subscriptionProvider.setBillingCycle(_isYearly);

    subscriptionProvider.purchaseSubscription(
      userId: user.userId,
      userEmail: user.email,
      userName: user.fullName,
      userPhone: user.phoneNumber ?? '',
      plan: plan,
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final currentSubscription = subscriptionProvider.currentSubscription;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
      ),
      body: subscriptionProvider.isProcessingPayment
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing payment...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current plan banner
                  if (currentSubscription != null) ...[
                    _CurrentPlanBanner(subscription: currentSubscription),
                    const SizedBox(height: 24),
                  ],

                  // Header
                  Text(
                    'Choose Your Plan',
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a plan that fits your hiring needs',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Billing toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isYearly = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isYearly ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !_isYearly
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  'Monthly',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: !_isYearly
                                        ? AppColors.primary
                                        : AppColors.grey600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isYearly = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isYearly ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isYearly
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Yearly',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: _isYearly
                                            ? AppColors.primary
                                            : AppColors.grey600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '2 months free',
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Plan cards
                  ...SubscriptionPlans.allPlans.map((plan) {
                    final isCurrentPlan =
                        currentSubscription?.tier == plan.tier;
                    final currentTierIndex = currentSubscription != null
                        ? SubscriptionTier.values.indexOf(currentSubscription.tier)
                        : -1;
                    final planTierIndex = SubscriptionTier.values.indexOf(plan.tier);
                    final isDowngrade = currentSubscription != null &&
                        currentSubscription.isValid &&
                        planTierIndex < currentTierIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PlanCard(
                        plan: plan,
                        isYearly: _isYearly,
                        isCurrentPlan: isCurrentPlan,
                        isDowngrade: isDowngrade,
                        isPopular: plan.tier == SubscriptionTier.pro && currentSubscription == null,
                        onSelect: (isCurrentPlan || isDowngrade) ? null : () => _selectPlan(plan),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // FAQ or support
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.help_outline, color: AppColors.grey600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need help choosing?',
                                style: AppTextStyles.labelLarge,
                              ),
                              Text(
                                'Contact our sales team for custom plans',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Open support chat or email
                          },
                          child: const Text('Contact Us'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  final UserSubscription subscription;

  const _CurrentPlanBanner({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan: ${subscription.plan.name}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subscription.isValid
                      ? 'Expires in ${subscription.daysRemaining} days'
                      : 'Expired',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isYearly;
  final bool isCurrentPlan;
  final bool isDowngrade;
  final bool isPopular;
  final VoidCallback? onSelect;

  const _PlanCard({
    required this.plan,
    required this.isYearly,
    this.isCurrentPlan = false,
    this.isDowngrade = false,
    this.isPopular = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final price = isYearly ? plan.priceYearly : plan.priceMonthly;
    final pricePerMonth = isYearly ? (plan.priceYearly / 12).round() : plan.priceMonthly;

    return Container(
      decoration: BoxDecoration(
        color: isDowngrade ? AppColors.grey50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.success
              : isPopular
                  ? AppColors.primary
                  : AppColors.grey200,
          width: isCurrentPlan || isPopular ? 2 : 1,
        ),
        boxShadow: isCurrentPlan
            ? [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : isPopular
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
      ),
      child: Column(
        children: [
          // Current plan badge
          if (isCurrentPlan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'YOUR CURRENT PLAN',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            )
          // Popular badge
          else if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: AppTextStyles.h5),
                        const SizedBox(height: 4),
                        Text(
                          plan.description,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (price == 0)
                          Text('Free', style: AppTextStyles.h4)
                        else ...[
                          Text(
                            '₹${pricePerMonth ~/ 100}',
                            style: AppTextStyles.h4,
                          ),
                          Text(
                            '/month',
                            style: AppTextStyles.caption,
                          ),
                          if (isYearly && price > 0)
                            Text(
                              'Billed ₹${price ~/ 100}/year',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Features
                ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: plan.hasAIFeatures
                                ? AppColors.primary
                                : AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? AppColors.success.withOpacity(0.2)
                          : isDowngrade
                              ? AppColors.grey200
                              : isPopular
                                  ? AppColors.primary
                                  : AppColors.grey100,
                      foregroundColor: isCurrentPlan
                          ? AppColors.success
                          : isDowngrade
                              ? AppColors.grey500
                              : isPopular
                                  ? Colors.white
                                  : AppColors.textPrimaryLight,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCurrentPlan)
                          const Icon(Icons.check_circle, size: 18),
                        if (isCurrentPlan)
                          const SizedBox(width: 8),
                        Text(
                          isCurrentPlan
                              ? 'Current Plan'
                              : isDowngrade
                                  ? 'Downgrade not available'
                                  : price == 0
                                      ? 'Get Started'
                                      : 'Subscribe',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentConfirmationSheet extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isYearly;
  final VoidCallback onConfirm;

  const _PaymentConfirmationSheet({
    required this.plan,
    required this.isYearly,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final price = isYearly ? plan.priceYearly : plan.priceMonthly;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text('Confirm Subscription', style: AppTextStyles.h5),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Plan'),
                    Text(plan.name, style: AppTextStyles.labelLarge),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Billing'),
                    Text(
                      isYearly ? 'Yearly' : 'Monthly',
                      style: AppTextStyles.labelLarge,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount'),
                    Text(
                      '₹${price ~/ 100}',
                      style: AppTextStyles.h5.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Pay Now'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 14, color: AppColors.grey500),
              const SizedBox(width: 4),
              Text(
                'Secured by Razorpay',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
