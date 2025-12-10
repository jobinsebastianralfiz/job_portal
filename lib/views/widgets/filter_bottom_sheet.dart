import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'custom_button.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  final Function(Map<String, dynamic>) onApply;
  final VoidCallback onClear;

  const FilterBottomSheet({
    super.key,
    this.initialFilters,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedCategory;
  String? _selectedEmploymentType;
  String? _selectedWorkLocation;
  String? _selectedExperienceLevel;
  RangeValues _salaryRange = const RangeValues(0, 200000);

  final List<String> _categories = [
    'Technology',
    'Design',
    'Marketing',
    'Finance',
    'Healthcare',
    'Education',
    'Sales',
    'Engineering',
    'Other',
  ];

  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
  ];

  final List<String> _workLocations = [
    'On-site',
    'Remote',
    'Hybrid',
  ];

  final List<String> _experienceLevels = [
    'Entry Level',
    'Mid Level',
    'Senior Level',
    'Lead',
    'Manager',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters != null) {
      _selectedCategory = widget.initialFilters!['category'];
      _selectedEmploymentType = widget.initialFilters!['employmentType'];
      _selectedWorkLocation = widget.initialFilters!['workLocation'];
      _selectedExperienceLevel = widget.initialFilters!['experienceLevel'];
    }
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    if (_selectedCategory != null) filters['category'] = _selectedCategory;
    if (_selectedEmploymentType != null) filters['employmentType'] = _selectedEmploymentType;
    if (_selectedWorkLocation != null) filters['workLocation'] = _selectedWorkLocation;
    if (_selectedExperienceLevel != null) filters['experienceLevel'] = _selectedExperienceLevel;

    widget.onApply(filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedEmploymentType = null;
      _selectedWorkLocation = null;
      _selectedExperienceLevel = null;
      _salaryRange = const RangeValues(0, 200000);
    });
    widget.onClear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters', style: AppTextStyles.h5),
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear All',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  _buildSectionTitle('Category'),
                  const SizedBox(height: 12),
                  _buildChipGroup(
                    options: _categories,
                    selectedValue: _selectedCategory,
                    onSelected: (value) {
                      setState(() {
                        _selectedCategory = value == _selectedCategory ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Employment Type
                  _buildSectionTitle('Employment Type'),
                  const SizedBox(height: 12),
                  _buildChipGroup(
                    options: _employmentTypes,
                    selectedValue: _selectedEmploymentType,
                    onSelected: (value) {
                      setState(() {
                        _selectedEmploymentType = value == _selectedEmploymentType ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Work Location
                  _buildSectionTitle('Work Location'),
                  const SizedBox(height: 12),
                  _buildChipGroup(
                    options: _workLocations,
                    selectedValue: _selectedWorkLocation,
                    onSelected: (value) {
                      setState(() {
                        _selectedWorkLocation = value == _selectedWorkLocation ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Experience Level
                  _buildSectionTitle('Experience Level'),
                  const SizedBox(height: 12),
                  _buildChipGroup(
                    options: _experienceLevels,
                    selectedValue: _selectedExperienceLevel,
                    onSelected: (value) {
                      setState(() {
                        _selectedExperienceLevel = value == _selectedExperienceLevel ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Salary Range
                  _buildSectionTitle('Salary Range'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${_salaryRange.start.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text(
                        '\$${_salaryRange.end.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}+',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _salaryRange,
                    min: 0,
                    max: 200000,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.grey200,
                    onChanged: (values) {
                      setState(() {
                        _salaryRange = values;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: CustomButton(
                text: 'Apply Filters',
                onPressed: _applyFilters,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h6,
    );
  }

  Widget _buildChipGroup({
    required List<String> options,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selectedValue;
        return FilterChip(
          label: Text(
            option,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? Colors.white : AppColors.grey700,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          backgroundColor: AppColors.grey100,
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.grey300,
            ),
          ),
        );
      }).toList(),
    );
  }
}
