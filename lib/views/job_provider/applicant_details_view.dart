import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/application_model.dart';
import '../../providers/application_provider.dart';

class ApplicantDetailsView extends StatefulWidget {
  final ApplicationModel application;

  const ApplicantDetailsView({super.key, required this.application});

  @override
  State<ApplicantDetailsView> createState() => _ApplicantDetailsViewState();
}

class _ApplicantDetailsViewState extends State<ApplicantDetailsView> {
  late ApplicationModel _application;

  @override
  void initState() {
    super.initState();
    _application = widget.application;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicant Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'message',
                child: Row(
                  children: [
                    Icon(Icons.message, size: 20),
                    SizedBox(width: 8),
                    Text('Send Message'),
                  ],
                ),
              ),
              if (_application.resume != null)
                const PopupMenuItem(
                  value: 'resume',
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 20),
                      SizedBox(width: 8),
                      Text('View Resume'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'notes',
                child: Row(
                  children: [
                    Icon(Icons.note_add, size: 20),
                    SizedBox(width: 8),
                    Text('Add Notes'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _application.applicantImage != null
                        ? NetworkImage(_application.applicantImage!)
                        : null,
                    child: _application.applicantImage == null
                        ? Text(
                            _application.applicantName.isNotEmpty
                                ? _application.applicantName[0].toUpperCase()
                                : 'A',
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _application.applicantName,
                    style: AppTextStyles.h4.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Applied for ${_application.jobTitle}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusBadge(status: _application.status, large: true),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Application Timeline
                  _SectionTitle(title: 'Application Timeline'),
                  const SizedBox(height: 12),
                  _TimelineCard(application: _application),
                  const SizedBox(height: 24),

                  // Interview Details
                  if (_application.interviewDate != null) ...[
                    _SectionTitle(title: 'Interview Details'),
                    const SizedBox(height: 12),
                    _InterviewCard(application: _application),
                    const SizedBox(height: 24),
                  ],

                  // Cover Letter
                  if (_application.coverLetter != null &&
                      _application.coverLetter!.isNotEmpty) ...[
                    _SectionTitle(title: 'Cover Letter'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Text(
                        _application.coverLetter!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Screening Questions & Answers
                  if (_application.screeningAnswers != null &&
                      _application.screeningAnswers!.isNotEmpty) ...[
                    _SectionTitle(title: 'Screening Answers'),
                    const SizedBox(height: 12),
                    ..._application.screeningAnswers!.map((answer) {
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
                            Text(
                              answer.question,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.grey700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              answer.answer,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Application Info
                  _SectionTitle(title: 'Application Info'),
                  const SizedBox(height: 12),
                  _InfoCard(application: _application),
                  const SizedBox(height: 24),

                  // Notes Section
                  if (_application.notes != null && _application.notes!.isNotEmpty) ...[
                    _SectionTitle(title: 'Internal Notes'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.note, color: AppColors.warning, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _application.notes!,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Resume Section
                  if (_application.resume != null) ...[
                    _SectionTitle(title: 'Resume'),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _openResume(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.description,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resume.pdf',
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to view',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new, color: AppColors.grey500),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
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
        child: _buildActionButtons(),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_application.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus('rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus('shortlisted'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Shortlist'),
              ),
            ),
          ],
        );

      case 'shortlisted':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus('rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showScheduleInterviewSheet(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.event, size: 20),
                label: const Text('Schedule Interview'),
              ),
            ),
          ],
        );

      case 'interview':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus('rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showMakeOfferSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Make Offer'),
              ),
            ),
          ],
        );

      case 'offered':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.statusOffered.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, color: AppColors.statusOffered),
              const SizedBox(width: 8),
              Text(
                'Waiting for candidate response',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.statusOffered,
                ),
              ),
            ],
          ),
        );

      case 'accepted':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Offer Accepted!',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );

      case 'rejected':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Application Rejected',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'message':
        _sendMessage();
        break;
      case 'resume':
        _openResume();
        break;
      case 'notes':
        _showAddNotesSheet();
        break;
    }
  }

  void _sendMessage() {
    // Navigate to chat with applicant
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat feature coming soon')),
    );
  }

  void _openResume() async {
    if (_application.resume != null) {
      final uri = Uri.parse(_application.resume!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showAddNotesSheet() {
    final controller = TextEditingController(text: _application.notes);

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
            Text('Internal Notes', style: AppTextStyles.h5),
            const SizedBox(height: 8),
            Text(
              'These notes are only visible to your team',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add notes about this applicant...',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final provider = context.read<ApplicationProvider>();
                  await provider.addNotes(
                    _application.applicationId,
                    controller.text,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notes saved')),
                    );
                  }
                },
                child: const Text('Save Notes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(String status) async {
    if (status == 'rejected') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reject Applicant?'),
          content: Text(
            'Are you sure you want to reject ${_application.applicantName}\'s application?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reject'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final provider = context.read<ApplicationProvider>();
    bool success = false;

    if (status == 'rejected') {
      success = await provider.rejectApplication(_application.applicationId);
    } else if (status == 'shortlisted') {
      success = await provider.shortlistApplication(_application.applicationId);
    }

    if (success && mounted) {
      setState(() {
        _application = _application.copyWith(status: status);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application ${status == 'rejected' ? 'rejected' : 'shortlisted'}'),
          backgroundColor: status == 'rejected' ? AppColors.error : AppColors.success,
        ),
      );
    }
  }

  void _showScheduleInterviewSheet() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String interviewType = 'video';
    final locationController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              Text('Schedule Interview', style: AppTextStyles.h5),
              const SizedBox(height: 16),

              // Interview Type
              Text('Interview Type', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                selected: {interviewType},
                onSelectionChanged: (value) {
                  setModalState(() => interviewType = value.first);
                },
                segments: const [
                  ButtonSegment(value: 'video', label: Text('Video')),
                  ButtonSegment(value: 'phone', label: Text('Phone')),
                  ButtonSegment(value: 'in_person', label: Text('In Person')),
                ],
              ),
              const SizedBox(height: 16),

              // Date & Time Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (date != null) {
                          setModalState(() => selectedDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setModalState(() => selectedTime = time);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (interviewType == 'in_person') ...[
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes for candidate',
                  hintText: 'Optional',
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final provider = context.read<ApplicationProvider>();
                    final scheduledDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    final success = await provider.scheduleInterview(
                      _application.applicationId,
                      scheduledDateTime,
                      interviewType,
                      location: interviewType == 'in_person'
                          ? locationController.text
                          : null,
                      notes: notesController.text.isNotEmpty
                          ? notesController.text
                          : null,
                    );

                    if (success && mounted) {
                      setState(() {
                        _application = _application.copyWith(
                          status: 'interview',
                          interview: InterviewDetails(
                            scheduledAt: scheduledDateTime,
                            type: interviewType,
                            location: interviewType == 'in_person'
                                ? locationController.text
                                : null,
                            notes: notesController.text.isNotEmpty
                                ? notesController.text
                                : null,
                          ),
                        );
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Interview scheduled'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Schedule Interview'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMakeOfferSheet() {
    final salaryController = TextEditingController();
    final messageController = TextEditingController();
    DateTime startDate = DateTime.now().add(const Duration(days: 14));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
              Text('Make Offer', style: AppTextStyles.h5),
              const SizedBox(height: 8),
              Text(
                'Send a job offer to ${_application.applicantName}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Offered Salary',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Annual salary',
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                  );
                  if (date != null) {
                    setModalState(() => startDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Proposed Start Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${startDate.day}/${startDate.month}/${startDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message to Candidate',
                  hintText: 'Congratulations! We are pleased to offer you...',
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final provider = context.read<ApplicationProvider>();
                    final success = await provider.makeOffer(
                      _application.applicationId,
                      offeredSalary: int.tryParse(salaryController.text),
                      startDate: startDate,
                      message: messageController.text,
                    );

                    if (success && mounted) {
                      setState(() {
                        _application = _application.copyWith(status: 'offered');
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Offer sent to candidate'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text('Send Offer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.h6);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool large;

  const _StatusBadge({required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'pending':
        color = AppColors.statusPending;
        break;
      case 'reviewed':
        color = AppColors.statusReviewed;
        break;
      case 'shortlisted':
        color = AppColors.statusShortlisted;
        break;
      case 'interview':
        color = AppColors.statusInterview;
        break;
      case 'offered':
        color = AppColors.statusOffered;
        break;
      case 'accepted':
        color = AppColors.statusAccepted;
        break;
      case 'rejected':
        color = AppColors.statusRejected;
        break;
      default:
        color = AppColors.grey500;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: (large ? AppTextStyles.labelLarge : AppTextStyles.overline).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final ApplicationModel application;

  const _TimelineCard({required this.application});

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
        children: [
          _TimelineItem(
            title: 'Applied',
            date: application.appliedAt,
            isCompleted: true,
            isFirst: true,
          ),
          if (application.reviewedAt != null)
            _TimelineItem(
              title: 'Reviewed',
              date: application.reviewedAt!,
              isCompleted: true,
            ),
          if (application.status == 'shortlisted' ||
              application.status == 'interview' ||
              application.status == 'offered' ||
              application.status == 'accepted')
            _TimelineItem(
              title: 'Shortlisted',
              date: application.shortlistedAt ?? DateTime.now(),
              isCompleted: true,
            ),
          if (application.interviewDate != null)
            _TimelineItem(
              title: 'Interview',
              date: application.interviewDate!,
              isCompleted: application.status == 'offered' ||
                  application.status == 'accepted',
            ),
          if (application.status == 'offered' || application.status == 'accepted')
            _TimelineItem(
              title: 'Offered',
              date: application.offeredAt ?? DateTime.now(),
              isCompleted: true,
            ),
          if (application.status == 'accepted')
            _TimelineItem(
              title: 'Accepted',
              date: application.acceptedAt ?? DateTime.now(),
              isCompleted: true,
              isLast: true,
            ),
          if (application.status == 'rejected')
            _TimelineItem(
              title: 'Rejected',
              date: application.rejectedAt ?? DateTime.now(),
              isCompleted: true,
              isLast: true,
              isRejected: true,
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final DateTime date;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;
  final bool isRejected;

  const _TimelineItem({
    required this.title,
    required this.date,
    required this.isCompleted,
    this.isFirst = false,
    this.isLast = false,
    this.isRejected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRejected
        ? AppColors.error
        : isCompleted
            ? AppColors.success
            : AppColors.grey400;

    return Row(
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 16,
                color: color,
              ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: isCompleted
                  ? Icon(
                      isRejected ? Icons.close : Icons.check,
                      size: 8,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 16,
                color: AppColors.grey300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isRejected ? AppColors.error : null,
                ),
              ),
              Text(
                _formatDate(date),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InterviewCard extends StatelessWidget {
  final ApplicationModel application;

  const _InterviewCard({required this.application});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusInterview.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.statusInterview.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getInterviewIcon(),
                color: AppColors.statusInterview,
              ),
              const SizedBox(width: 8),
              Text(
                _getInterviewTypeLabel(),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.statusInterview,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: AppColors.grey600),
              const SizedBox(width: 8),
              Text(
                _formatInterviewDate(application.interviewDate!),
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          if (application.interviewLocation != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.grey600),
                const SizedBox(width: 8),
                Text(
                  application.interviewLocation!,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getInterviewIcon() {
    switch (application.interviewType) {
      case 'video':
        return Icons.video_call;
      case 'phone':
        return Icons.phone;
      case 'in_person':
        return Icons.person;
      default:
        return Icons.event;
    }
  }

  String _getInterviewTypeLabel() {
    switch (application.interviewType) {
      case 'video':
        return 'Video Interview';
      case 'phone':
        return 'Phone Interview';
      case 'in_person':
        return 'In-Person Interview';
      default:
        return 'Interview';
    }
  }

  String _formatInterviewDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoCard extends StatelessWidget {
  final ApplicationModel application;

  const _InfoCard({required this.application});

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
        children: [
          _InfoRow(
            label: 'Applied On',
            value: _formatDate(application.appliedAt),
          ),
          const Divider(height: 24),
          if (application.expectedSalary != null) ...[
            _InfoRow(
              label: 'Expected Salary',
              value: '\$${application.expectedSalary}',
            ),
            const Divider(height: 24),
          ],
          if (application.availableFrom != null) ...[
            _InfoRow(
              label: 'Available From',
              value: _formatDate(application.availableFrom!),
            ),
            const Divider(height: 24),
          ],
          _InfoRow(
            label: 'Application ID',
            value: application.applicationId.substring(0, 8).toUpperCase(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey600)),
        Text(value, style: AppTextStyles.labelLarge),
      ],
    );
  }
}
