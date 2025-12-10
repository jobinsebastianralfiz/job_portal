import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/application_model.dart';
import '../services/firebase/application_service.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApplicationService _applicationService = ApplicationService();

  List<ApplicationModel> _applications = [];
  List<ApplicationModel> _jobApplications = [];
  ApplicationModel? _selectedApplication;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _applicationsSubscription;

  List<ApplicationModel> get applications => _applications;
  List<ApplicationModel> get jobApplications => _jobApplications;
  ApplicationModel? get selectedApplication => _selectedApplication;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Stats
  int get pendingCount => _applications.where((a) => a.isPending).length;
  int get reviewedCount => _applications.where((a) => a.isReviewed).length;
  int get shortlistedCount => _applications.where((a) => a.isShortlisted).length;
  int get interviewCount => _applications.where((a) => a.isInterview).length;
  int get offeredCount => _applications.where((a) => a.isOffered).length;

  // Submit Application (Job Seeker)
  Future<bool> submitApplication(ApplicationModel application) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newApplication = await _applicationService.submitApplication(application);
      _applications.insert(0, newApplication);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to submit application: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load My Applications (Job Seeker) - with real-time updates
  Future<void> loadMyApplications(String applicantId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Cancel existing subscription
      await _applicationsSubscription?.cancel();

      // Set up real-time listener
      _applicationsSubscription = _applicationService
          .streamApplicationsByApplicant(applicantId)
          .listen((applications) {
        _applications = applications;
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        _error = 'Failed to load applications: $e';
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load applications: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Dispose subscriptions
  @override
  void dispose() {
    _applicationsSubscription?.cancel();
    super.dispose();
  }

  // Load Applications for Job (Provider)
  Future<void> loadJobApplications(String jobId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _jobApplications = await _applicationService.getApplicationsForJob(jobId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load applications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Applications by Provider
  Future<void> loadProviderApplications(String providerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _applications = await _applicationService.getApplicationsByProvider(providerId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load applications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get Application by ID
  Future<ApplicationModel?> getApplication(String applicationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedApplication = await _applicationService.getApplication(applicationId);
      notifyListeners();
      return _selectedApplication;
    } catch (e) {
      _error = 'Failed to load application: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Application Status (Provider)
  Future<bool> updateStatus(String applicationId, String status, {String? note}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _applicationService.updateApplicationStatus(applicationId, status, note: note);

      // Update local list
      final index = _applications.indexWhere((a) => a.applicationId == applicationId);
      if (index != -1) {
        final updated = await _applicationService.getApplication(applicationId);
        if (updated != null) {
          _applications[index] = updated;
        }
      }

      final jobIndex = _jobApplications.indexWhere((a) => a.applicationId == applicationId);
      if (jobIndex != -1) {
        final updated = await _applicationService.getApplication(applicationId);
        if (updated != null) {
          _jobApplications[jobIndex] = updated;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update status: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Shortlist Application
  Future<bool> shortlistApplication(String applicationId, {String? note}) async {
    return updateStatus(applicationId, 'shortlisted', note: note);
  }

  // Reject Application
  Future<bool> rejectApplication(String applicationId, {String? note}) async {
    return updateStatus(applicationId, 'rejected', note: note);
  }

  // Schedule Interview
  Future<bool> scheduleInterview(
    String applicationId,
    DateTime scheduledAt,
    String type, {
    String? location,
    String? notes,
    String? meetingLink,
    int? duration,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final interview = InterviewDetails(
        scheduledAt: scheduledAt,
        type: type,
        location: location,
        notes: notes,
        meetingLink: meetingLink,
        duration: duration ?? 60,
        status: 'scheduled',
      );

      await _applicationService.scheduleInterview(applicationId, interview);

      // Update local list
      final index = _applications.indexWhere((a) => a.applicationId == applicationId);
      if (index != -1) {
        final updated = await _applicationService.getApplication(applicationId);
        if (updated != null) {
          _applications[index] = updated;
        }
      }

      final jobIndex = _jobApplications.indexWhere((a) => a.applicationId == applicationId);
      if (jobIndex != -1) {
        final updated = await _applicationService.getApplication(applicationId);
        if (updated != null) {
          _jobApplications[jobIndex] = updated;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to schedule interview: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Make Offer
  Future<bool> makeOffer(
    String applicationId, {
    int? offeredSalary,
    DateTime? startDate,
    String? message,
  }) async {
    // Include offer details in the note
    String? note;
    if (offeredSalary != null || startDate != null || message != null) {
      final parts = <String>[];
      if (offeredSalary != null) parts.add('Salary: \$${offeredSalary}');
      if (startDate != null) parts.add('Start: ${startDate.toIso8601String().split('T')[0]}');
      if (message != null && message.isNotEmpty) parts.add('Message: $message');
      note = parts.join(' | ');
    }
    return updateStatus(applicationId, 'offered', note: note);
  }

  // Add Notes
  Future<bool> addNotes(String applicationId, String notes) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _applicationService.addProviderNotes(applicationId, notes);

      // Update local list
      final index = _applications.indexWhere((a) => a.applicationId == applicationId);
      if (index != -1) {
        _applications[index] = _applications[index].copyWith(providerNotes: notes);
      }

      final jobIndex = _jobApplications.indexWhere((a) => a.applicationId == applicationId);
      if (jobIndex != -1) {
        _jobApplications[jobIndex] = _jobApplications[jobIndex].copyWith(providerNotes: notes);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add notes: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Withdraw Application (Job Seeker)
  Future<bool> withdrawApplication(String applicationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _applicationService.withdrawApplication(applicationId);
      _applications.removeWhere((a) => a.applicationId == applicationId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to withdraw application: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Accept Offer (Job Seeker)
  Future<bool> acceptOffer(String applicationId) async {
    return updateStatus(applicationId, 'accepted');
  }

  // Check if Already Applied
  Future<bool> hasApplied(String jobId, String applicantId) async {
    try {
      return await _applicationService.hasApplied(jobId, applicantId);
    } catch (e) {
      return false;
    }
  }

  // Get Application Stats for Provider
  Future<Map<String, int>> getProviderStats(String providerId) async {
    try {
      return await _applicationService.getProviderApplicationStats(providerId);
    } catch (e) {
      return {};
    }
  }

  // Get Upcoming Interviews
  Future<List<ApplicationModel>> getUpcomingInterviews(String providerId) async {
    try {
      return await _applicationService.getUpcomingInterviews(providerId);
    } catch (e) {
      return [];
    }
  }

  // Filter Applications by Status
  List<ApplicationModel> filterByStatus(String status) {
    return _applications.where((a) => a.status == status).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedApplication = null;
    notifyListeners();
  }
}
