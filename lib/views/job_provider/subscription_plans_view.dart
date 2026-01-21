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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePayment();
    });
  }

  void _initializePayment() {
    final provider = context.read<SubscriptionProvider>();
    provider.initializePayment(
      onSuccess: () {
        if (mounted) {
          _onPaymentSuccess();
        }
      },
      onError: (error) {
        if (mounted) {
          _onPaymentError(error);
        }
      },
    );
  }

  @override
  void dispose() {
    context.read<SubscriptionProvider>().disposePayment();
    super.dispose();
  }

  void _onPaymentSuccess() async {
    // Refresh user data
    await context.read<AuthProvider>().refreshUserData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription activated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _onPaymentError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _selectPlan(SubscriptionPlan plan) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    // Free plan - activate directly
    if (plan.tier == SubscriptionTier.free) {
      _activateFreePlan();
      return;
    }

    // Paid plan - show confirmation
    _showPaymentConfirmation(plan);
  }

  Future<void> _activateFreePlan() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final provider = context.read<SubscriptionProvider>();
    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await provider.activateFreePlan(user.userId);

    if (mounted) {
      if (success) {
        await authProvider.refreshUserData();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Free plan activated!'),
            backgroundColor: AppColors.success,
          ),
        );
        navigator.pop(true);
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to activate'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPaymentConfirmation(SubscriptionPlan plan) {
    final price = _isYearly ? plan.priceYearly : plan.priceMonthly;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            _buildConfirmationRow('Plan', plan.name),
            const Divider(height: 24),
            _buildConfirmationRow('Billing', _isYearly ? 'Yearly' : 'Monthly'),
            const Divider(height: 24),
            _buildConfirmationRow(
              'Amount',
              '₹${price ~/ 100}',
              isHighlighted: true,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startPayment(plan);
                    },
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
                Text('Secured by Razorpay', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: isHighlighted
              ? AppTextStyles.h5.copyWith(color: AppColors.primary)
              : AppTextStyles.labelLarge,
        ),
      ],
    );
  }

  void _startPayment(SubscriptionPlan plan) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final provider = context.read<SubscriptionProvider>();
    provider.setBillingCycle(_isYearly);
    provider.startPurchase(
      userId: user.userId,
      userEmail: user.email,
      userName: user.fullName,
      userPhone: user.phoneNumber ?? '9999999999',
      plan: plan,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final currentSubscription = provider.currentSubscription;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
      ),
      body: provider.isPaymentInProgress
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
                    _buildCurrentPlanBanner(currentSubscription),
                    const SizedBox(height: 24),
                  ],

                  // Header
                  Text('Choose Your Plan', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Select a plan that fits your hiring needs',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Billing toggle
                  _buildBillingToggle(),
                  const SizedBox(height: 24),

                  // Plan cards
                  ...SubscriptionPlans.allPlans.map((plan) {
                    final isCurrentPlan = currentSubscription?.tier == plan.tier;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPlanCard(
                        plan: plan,
                        isCurrentPlan: isCurrentPlan,
                        isPopular: plan.tier == SubscriptionTier.pro && currentSubscription == null,
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentPlanBanner(UserSubscription subscription) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: ${subscription.plan.name}',
                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subscription.isValid
                      ? 'Expires in ${subscription.daysRemaining} days'
                      : 'Expired',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleOption('Monthly', !_isYearly, () => setState(() => _isYearly = false)),
          _buildToggleOption('Yearly', _isYearly, () => setState(() => _isYearly = true), showBadge: true),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap, {bool showBadge = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black12, blurRadius: 4)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.grey600,
                ),
              ),
              if (showBadge) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required bool isCurrentPlan,
    required bool isPopular,
  }) {
    final price = _isYearly ? plan.priceYearly : plan.priceMonthly;
    final pricePerMonth = _isYearly ? (plan.priceYearly / 12).round() : plan.priceMonthly;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.success
              : isPopular
                  ? AppColors.primary
                  : AppColors.grey200,
          width: isCurrentPlan || isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Badge
          if (isCurrentPlan)
            _buildBadge('YOUR CURRENT PLAN', AppColors.success)
          else if (isPopular)
            _buildBadge('MOST POPULAR', AppColors.primary),

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
                        Text(plan.description, style: AppTextStyles.caption),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (price == 0)
                          Text('Free', style: AppTextStyles.h4)
                        else ...[
                          Text('₹${pricePerMonth ~/ 100}', style: AppTextStyles.h4),
                          Text('/month', style: AppTextStyles.caption),
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
                          Icon(Icons.check_circle, color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(feature, style: AppTextStyles.bodySmall)),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : () => _selectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? AppColors.grey200
                          : isPopular
                              ? AppColors.primary
                              : AppColors.grey100,
                      foregroundColor: isCurrentPlan
                          ? AppColors.grey500
                          : isPopular
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Current Plan'
                          : price == 0
                              ? 'Get Started'
                              : 'Subscribe',
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
