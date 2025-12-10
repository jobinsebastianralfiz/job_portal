import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/company_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/company_service.dart';
import '../../services/firebase/storage_service.dart';

class CompanyProfileView extends StatefulWidget {
  const CompanyProfileView({super.key});

  @override
  State<CompanyProfileView> createState() => _CompanyProfileViewState();
}

class _CompanyProfileViewState extends State<CompanyProfileView> {
  final _companyService = CompanyService();
  final _storageService = StorageService();
  CompanyModel? _company;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyProfile();
  }

  void _loadCompanyProfile() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      final company = await _companyService.getCompanyByUserId(
        authProvider.currentUser!.userId,
      );
      setState(() {
        _company = company;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Profile'),
        actions: [
          if (_company != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditSheet(),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _company == null
              ? _buildSetupPrompt()
              : RefreshIndicator(
                  onRefresh: () async => _loadCompanyProfile(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _company!.logo != null
                                        ? NetworkImage(_company!.logo!)
                                        : null,
                                    child: _company!.logo == null
                                        ? Text(
                                            _company!.name.isNotEmpty
                                                ? _company!.name[0].toUpperCase()
                                                : 'C',
                                            style: AppTextStyles.h2.copyWith(
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: InkWell(
                                      onTap: () => _uploadLogo(),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _company!.name,
                                    style: AppTextStyles.h4.copyWith(color: Colors.white),
                                  ),
                                  if (_company!.isVerified) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                              if (_company!.industry != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _company!.industry!,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _StatItem(
                                    value: _company!.totalJobs.toString(),
                                    label: 'Jobs Posted',
                                  ),
                                  const SizedBox(width: 32),
                                  _StatItem(
                                    value: _company!.totalHires.toString(),
                                    label: 'Hired',
                                  ),
                                  const SizedBox(width: 32),
                                  _StatItem(
                                    value: _company!.rating?.toStringAsFixed(1) ?? 'N/A',
                                    label: 'Rating',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Verification Status
                        if (!_company!.isVerified)
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Profile Under Review',
                                        style: AppTextStyles.labelLarge.copyWith(
                                          color: AppColors.warning,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Complete your profile to get verified and attract more candidates.',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // About Section
                              _SectionCard(
                                title: 'About Company',
                                icon: Icons.business,
                                onEdit: () => _showEditSheet(section: 'about'),
                                child: Text(
                                  _company!.description ?? 'No description added yet.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: _company!.description != null
                                        ? AppColors.grey700
                                        : AppColors.grey500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Company Details
                              _SectionCard(
                                title: 'Company Details',
                                icon: Icons.info_outline,
                                onEdit: () => _showEditSheet(section: 'details'),
                                child: Column(
                                  children: [
                                    _DetailRow(
                                      icon: Icons.people,
                                      label: 'Company Size',
                                      value: _company!.size ?? 'Not specified',
                                    ),
                                    const SizedBox(height: 12),
                                    _DetailRow(
                                      icon: Icons.calendar_today,
                                      label: 'Founded',
                                      value: _company!.founded != null
                                          ? _company!.founded.toString()
                                          : 'Not specified',
                                    ),
                                    const SizedBox(height: 12),
                                    _DetailRow(
                                      icon: Icons.category,
                                      label: 'Industry',
                                      value: _company!.industry ?? 'Not specified',
                                    ),
                                    const SizedBox(height: 12),
                                    _DetailRow(
                                      icon: Icons.business_center,
                                      label: 'Type',
                                      value: _company!.type ?? 'Not specified',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Contact & Location
                              _SectionCard(
                                title: 'Contact & Location',
                                icon: Icons.location_on,
                                onEdit: () => _showEditSheet(section: 'contact'),
                                child: Column(
                                  children: [
                                    _DetailRow(
                                      icon: Icons.location_city,
                                      label: 'Headquarters',
                                      value: _company!.headquarters ?? 'Not specified',
                                    ),
                                    const SizedBox(height: 12),
                                    _DetailRow(
                                      icon: Icons.email,
                                      label: 'Email',
                                      value: _company!.email ?? 'Not specified',
                                    ),
                                    const SizedBox(height: 12),
                                    _DetailRow(
                                      icon: Icons.phone,
                                      label: 'Phone',
                                      value: _company!.phone ?? 'Not specified',
                                    ),
                                    const SizedBox(height: 12),
                                    _DetailRow(
                                      icon: Icons.language,
                                      label: 'Website',
                                      value: _company!.website ?? 'Not specified',
                                      isLink: _company!.website != null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Social Links
                              _SectionCard(
                                title: 'Social Media',
                                icon: Icons.share,
                                onEdit: () => _showEditSheet(section: 'social'),
                                child: Column(
                                  children: [
                                    if (_company!.linkedin != null)
                                      _SocialLink(
                                        icon: Icons.link,
                                        label: 'LinkedIn',
                                        value: _company!.linkedin!,
                                      ),
                                    if (_company!.twitter != null) ...[
                                      const SizedBox(height: 12),
                                      _SocialLink(
                                        icon: Icons.link,
                                        label: 'Twitter',
                                        value: _company!.twitter!,
                                      ),
                                    ],
                                    if (_company!.linkedin == null &&
                                        _company!.twitter == null)
                                      Text(
                                        'No social links added',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Benefits & Perks
                              _SectionCard(
                                title: 'Benefits & Perks',
                                icon: Icons.card_giftcard,
                                onEdit: () => _showEditSheet(section: 'benefits'),
                                child: _company!.benefits != null &&
                                        _company!.benefits!.isNotEmpty
                                    ? Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _company!.benefits!.map((benefit) {
                                          return Chip(
                                            label: Text(benefit),
                                            backgroundColor:
                                                AppColors.primary.withOpacity(0.1),
                                            labelStyle: AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.primary,
                                            ),
                                          );
                                        }).toList(),
                                      )
                                    : Text(
                                        'No benefits listed',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.grey500,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // Gallery
                              _SectionCard(
                                title: 'Company Gallery',
                                icon: Icons.photo_library,
                                onEdit: () => _uploadGalleryImages(),
                                child: _company!.gallery != null &&
                                        _company!.gallery!.isNotEmpty
                                    ? SizedBox(
                                        height: 120,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _company!.gallery!.length,
                                          itemBuilder: (context, index) {
                                            return Container(
                                              width: 160,
                                              margin: EdgeInsets.only(
                                                right: index < _company!.gallery!.length - 1
                                                    ? 12
                                                    : 0,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                    _company!.gallery![index],
                                                  ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Column(
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 48,
                                            color: AppColors.grey400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add photos of your workplace',
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              color: AppColors.grey500,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 32),

                              // Account Actions
                              Text('Account', style: AppTextStyles.h6),
                              const SizedBox(height: 12),
                              ListTile(
                                leading: const Icon(Icons.logout, color: AppColors.error),
                                title: Text(
                                  'Sign Out',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                                onTap: () => _signOut(authProvider),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: AppColors.grey200),
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 80,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 24),
            Text(
              'Set Up Your Company Profile',
              style: AppTextStyles.h5,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create your company profile to start posting jobs and attracting top talent.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateCompanySheet(),
              icon: const Icon(Icons.add_business),
              label: const Text('Create Company Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCompanySheet() {
    final nameController = TextEditingController();
    final industryController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Company Profile', style: AppTextStyles.h5),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                hintText: 'Enter your company name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: industryController,
              decoration: const InputDecoration(
                labelText: 'Industry',
                hintText: 'e.g., Technology, Healthcare',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Tell us about your company',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Company name is required')),
                    );
                    return;
                  }

                  final authProvider = context.read<AuthProvider>();
                  final company = CompanyModel(
                    companyId: '',
                    ownerId: authProvider.currentUser!.userId,
                    name: nameController.text,
                    email: authProvider.currentUser!.email,
                    industry: industryController.text.isNotEmpty
                        ? industryController.text
                        : 'Other',
                    size: '1-10',
                    description: descriptionController.text.isNotEmpty
                        ? descriptionController.text
                        : 'No description provided',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  final createdCompany = await _companyService.createCompany(company);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadCompanyProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Company profile created'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Create Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet({String? section}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditCompanySheet(
        company: _company!,
        section: section,
        onSaved: () {
          Navigator.pop(context);
          _loadCompanyProfile();
        },
      ),
    );
  }

  void _uploadLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final file = File(image.path);
      final url = await _storageService.uploadCompanyLogo(
        file,
        _company!.companyId,
      );

      if (url != null) {
        await _companyService.updateLogo(_company!.companyId, url);
        _loadCompanyProfile();
      }
    }
  }

  void _uploadGalleryImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      final urls = <String>[];
      for (final image in images) {
        final file = File(image.path);
        final url = await _storageService.uploadCompanyGalleryImage(
          _company!.companyId,
          file,
        );
        if (url != null) {
          urls.add(url);
        }
      }

      if (urls.isNotEmpty && _company != null) {
        // Gallery is not tracked in the model currently
        // Would need to extend CompanyModel or use a separate collection
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery images uploaded')),
        );
        _loadCompanyProfile();
      }
    }
  }

  void _signOut(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h4.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onEdit;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: AppTextStyles.labelLarge),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onEdit,
                  color: AppColors.grey500,
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isLink ? AppColors.primary : null,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SocialLink({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditCompanySheet extends StatefulWidget {
  final CompanyModel company;
  final String? section;
  final VoidCallback onSaved;

  const _EditCompanySheet({
    required this.company,
    this.section,
    required this.onSaved,
  });

  @override
  State<_EditCompanySheet> createState() => _EditCompanySheetState();
}

class _EditCompanySheetState extends State<_EditCompanySheet> {
  final _companyService = CompanyService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _industryController;
  late TextEditingController _sizeController;
  late TextEditingController _foundedController;
  late TextEditingController _typeController;
  late TextEditingController _headquartersController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _linkedinController;
  late TextEditingController _twitterController;
  late TextEditingController _benefitsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company.name);
    _descriptionController = TextEditingController(text: widget.company.description);
    _industryController = TextEditingController(text: widget.company.industry);
    _sizeController = TextEditingController(text: widget.company.size);
    _foundedController = TextEditingController(
      text: widget.company.founded?.toString(),
    );
    _typeController = TextEditingController(text: widget.company.type);
    _headquartersController = TextEditingController(text: widget.company.headquarters);
    _emailController = TextEditingController(text: widget.company.email);
    _phoneController = TextEditingController(text: widget.company.phone);
    _websiteController = TextEditingController(text: widget.company.website);
    _linkedinController = TextEditingController(text: widget.company.linkedin);
    _twitterController = TextEditingController(text: widget.company.twitter);
    _benefitsController = TextEditingController(
      text: widget.company.benefits?.join(', '),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _industryController.dispose();
    _sizeController.dispose();
    _foundedController.dispose();
    _typeController.dispose();
    _headquartersController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.grey200)),
            ),
            child: Row(
              children: [
                Text('Edit Company Profile', style: AppTextStyles.h5),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Basic Info
                Text('Basic Information', style: AppTextStyles.h6),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Tell candidates about your company',
                  ),
                ),
                const SizedBox(height: 24),

                // Company Details
                Text('Company Details', style: AppTextStyles.h6),
                const SizedBox(height: 16),
                TextField(
                  controller: _industryController,
                  decoration: const InputDecoration(
                    labelText: 'Industry',
                    hintText: 'e.g., Technology, Healthcare',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _sizeController.text.isNotEmpty ? _sizeController.text : null,
                  decoration: const InputDecoration(labelText: 'Company Size'),
                  items: const [
                    DropdownMenuItem(value: '1-10', child: Text('1-10 employees')),
                    DropdownMenuItem(value: '11-50', child: Text('11-50 employees')),
                    DropdownMenuItem(value: '51-200', child: Text('51-200 employees')),
                    DropdownMenuItem(value: '201-500', child: Text('201-500 employees')),
                    DropdownMenuItem(value: '501-1000', child: Text('501-1000 employees')),
                    DropdownMenuItem(value: '1000+', child: Text('1000+ employees')),
                  ],
                  onChanged: (value) => _sizeController.text = value ?? '',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _foundedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Founded Year',
                    hintText: 'e.g., 2010',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _typeController.text.isNotEmpty ? _typeController.text : null,
                  decoration: const InputDecoration(labelText: 'Company Type'),
                  items: const [
                    DropdownMenuItem(value: 'Private', child: Text('Private')),
                    DropdownMenuItem(value: 'Public', child: Text('Public')),
                    DropdownMenuItem(value: 'Startup', child: Text('Startup')),
                    DropdownMenuItem(value: 'Non-profit', child: Text('Non-profit')),
                    DropdownMenuItem(value: 'Government', child: Text('Government')),
                  ],
                  onChanged: (value) => _typeController.text = value ?? '',
                ),
                const SizedBox(height: 24),

                // Contact Info
                Text('Contact Information', style: AppTextStyles.h6),
                const SizedBox(height: 16),
                TextField(
                  controller: _headquartersController,
                  decoration: const InputDecoration(
                    labelText: 'Headquarters',
                    hintText: 'City, Country',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Website',
                    hintText: 'https://example.com',
                  ),
                ),
                const SizedBox(height: 24),

                // Social Media
                Text('Social Media', style: AppTextStyles.h6),
                const SizedBox(height: 16),
                TextField(
                  controller: _linkedinController,
                  decoration: const InputDecoration(
                    labelText: 'LinkedIn',
                    hintText: 'https://linkedin.com/company/...',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _twitterController,
                  decoration: const InputDecoration(
                    labelText: 'Twitter',
                    hintText: 'https://twitter.com/...',
                  ),
                ),
                const SizedBox(height: 24),

                // Benefits
                Text('Benefits & Perks', style: AppTextStyles.h6),
                const SizedBox(height: 8),
                Text(
                  'Separate multiple benefits with commas',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _benefitsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Health Insurance, Remote Work, Gym Membership...',
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company name is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedCompany = widget.company.copyWith(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : widget.company.description,
        industry: _industryController.text.isNotEmpty
            ? _industryController.text
            : widget.company.industry,
        size: _sizeController.text.isNotEmpty
            ? _sizeController.text
            : widget.company.size,
        email: _emailController.text.isNotEmpty
            ? _emailController.text
            : widget.company.email,
        phone: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : widget.company.phone,
        website: _websiteController.text.isNotEmpty
            ? _websiteController.text
            : widget.company.website,
        socialLinks: SocialLinks(
          linkedin: _linkedinController.text.isNotEmpty
              ? _linkedinController.text
              : widget.company.socialLinks?.linkedin,
          twitter: _twitterController.text.isNotEmpty
              ? _twitterController.text
              : widget.company.socialLinks?.twitter,
        ),
        updatedAt: DateTime.now(),
      );

      await _companyService.updateCompany(updatedCompany);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }
}
