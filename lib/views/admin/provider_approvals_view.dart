import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../services/payment/subscription_service.dart';
import '../../models/subscription_model.dart';

class ProviderApprovalsView extends StatefulWidget {
  const ProviderApprovalsView({super.key});

  @override
  State<ProviderApprovalsView> createState() => _ProviderApprovalsViewState();
}

class _ProviderApprovalsViewState extends State<ProviderApprovalsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<UserModel> _pendingProviders = [];
  List<UserModel> _approvedProviders = [];
  List<UserModel> _rejectedProviders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProviders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Load pending
      final pendingSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'job_provider')
          .where('providerStatus', isEqualTo: 'pending_approval')
          .orderBy('createdAt', descending: true)
          .get();

      // Load approved (approved but not yet subscribed, or active)
      final approvedSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'job_provider')
          .where('providerStatus', whereIn: ['approved', 'active'])
          .orderBy('createdAt', descending: true)
          .get();

      // Load rejected
      final rejectedSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'job_provider')
          .where('providerStatus', isEqualTo: 'rejected')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _pendingProviders = pendingSnapshot.docs
            .map((doc) => UserModel.fromJson({...doc.data(), 'userId': doc.id}))
            .toList();
        _approvedProviders = approvedSnapshot.docs
            .map((doc) => UserModel.fromJson({...doc.data(), 'userId': doc.id}))
            .toList();
        _rejectedProviders = rejectedSnapshot.docs
            .map((doc) => UserModel.fromJson({...doc.data(), 'userId': doc.id}))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading providers: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveProvider(UserModel provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Provider'),
        content: Text(
          'Approve ${provider.fullName} (${provider.email}) as a job provider?\n\nThey will be able to select a subscription plan and start posting jobs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _subscriptionService.updateProviderStatus(
        provider.userId,
        ProviderStatus.approved,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider approved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadProviders();
      }
    }
  }

  Future<void> _rejectProvider(UserModel provider) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject ${provider.fullName} (${provider.email})?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _subscriptionService.updateProviderStatus(
        provider.userId,
        ProviderStatus.rejected,
        reason: reasonController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider rejected'),
            backgroundColor: AppColors.error,
          ),
        );
        _loadProviders();
      }
    }
  }

  Future<void> _suspendProvider(UserModel provider) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suspend ${provider.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for suspension',
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _subscriptionService.updateProviderStatus(
        provider.userId,
        ProviderStatus.suspended,
        reason: reasonController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider suspended'),
            backgroundColor: AppColors.warning,
          ),
        );
        _loadProviders();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Approvals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  if (_pendingProviders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_pendingProviders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Approved (${_approvedProviders.length})'),
            Tab(text: 'Rejected (${_rejectedProviders.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProviders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProviderList(_pendingProviders, 'pending'),
                _buildProviderList(_approvedProviders, 'approved'),
                _buildProviderList(_rejectedProviders, 'rejected'),
              ],
            ),
    );
  }

  Widget _buildProviderList(List<UserModel> providers, String type) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pending'
                  ? Icons.pending_actions
                  : type == 'approved'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'pending'
                  ? 'No pending approvals'
                  : type == 'approved'
                      ? 'No approved providers'
                      : 'No rejected providers',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProviders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: providers.length,
        itemBuilder: (context, index) {
          final provider = providers[index];
          return _ProviderCard(
            provider: provider,
            type: type,
            onApprove: () => _approveProvider(provider),
            onReject: () => _rejectProvider(provider),
            onSuspend: () => _suspendProvider(provider),
          );
        },
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final UserModel provider;
  final String type;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;

  const _ProviderCard({
    required this.provider,
    required this.type,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: provider.profileImage != null
                    ? NetworkImage(provider.profileImage!)
                    : null,
                child: provider.profileImage == null
                    ? Text(
                        provider.initials,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.fullName, style: AppTextStyles.labelLarge),
                    Text(
                      provider.email,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.grey500),
              const SizedBox(width: 4),
              Text(
                'Registered: ${_formatDate(provider.createdAt)}',
                style: AppTextStyles.caption,
              ),
              if (provider.phoneNumber != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.phone, size: 14, color: AppColors.grey500),
                const SizedBox(width: 4),
                Text(
                  provider.phoneNumber!,
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),

          // Rejection reason
          if (type == 'rejected' && provider.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${provider.rejectionReason}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Subscription info for approved
          if (type == 'approved' && provider.subscriptionTier != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.card_membership, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Plan: ${provider.subscriptionTier?.toUpperCase() ?? 'None'}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  if (provider.subscriptionExpiresAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• Expires: ${_formatDate(provider.subscriptionExpiresAt!)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Action buttons
          if (type == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            )
          else if (type == 'approved')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSuspend,
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Suspend'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                    ),
                  ),
                ),
              ],
            )
          else if (type == 'rejected')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Re-approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (type) {
      case 'pending':
        color = AppColors.warning;
        text = 'Pending';
        break;
      case 'approved':
        color = provider.providerStatus == 'active'
            ? AppColors.success
            : AppColors.primary;
        text = provider.providerStatus == 'active' ? 'Active' : 'Approved';
        break;
      case 'rejected':
        color = AppColors.error;
        text = 'Rejected';
        break;
      default:
        color = AppColors.grey500;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
