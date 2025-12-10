import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/company_model.dart';
import '../services/firebase/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  // Dashboard Stats
  Map<String, dynamic> _dashboardStats = {};
  Map<String, List<int>> _weeklyStats = {};
  List<Map<String, dynamic>> _recentActivity = [];

  // Users
  List<UserModel> _users = [];
  String _userFilter = 'all';
  String _userStatusFilter = 'all';
  String _userSearchQuery = '';

  // Jobs
  List<JobModel> _jobs = [];
  List<JobModel> _pendingJobs = [];
  List<JobModel> _reportedJobs = [];
  String _jobFilter = 'all';
  String _jobSearchQuery = '';

  // Companies
  List<CompanyModel> _pendingVerifications = [];

  // Loading states
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  bool _isLoadingJobs = false;
  String? _error;

  // Getters
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  Map<String, List<int>> get weeklyStats => _weeklyStats;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;

  List<UserModel> get users => _users;
  String get userFilter => _userFilter;
  String get userStatusFilter => _userStatusFilter;
  String get userSearchQuery => _userSearchQuery;

  List<JobModel> get jobs => _jobs;
  List<JobModel> get pendingJobs => _pendingJobs;
  List<JobModel> get reportedJobs => _reportedJobs;
  String get jobFilter => _jobFilter;
  String get jobSearchQuery => _jobSearchQuery;

  List<CompanyModel> get pendingVerifications => _pendingVerifications;

  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingJobs => _isLoadingJobs;
  String? get error => _error;

  // ==================== Dashboard ====================

  Future<void> loadDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    _dashboardStats = await _adminService.getDashboardStats();
    _weeklyStats = await _adminService.getWeeklyStats();
    _recentActivity = await _adminService.getRecentActivity();

    _isLoading = false;
    notifyListeners();
  }

  // ==================== User Management ====================

  Future<void> loadUsers() async {
    _isLoadingUsers = true;
    notifyListeners();

    _users = await _adminService.getAllUsers(
      role: _userFilter == 'all' ? null : _userFilter,
      status: _userStatusFilter == 'all' ? null : _userStatusFilter,
      searchQuery: _userSearchQuery.isNotEmpty ? _userSearchQuery : null,
    );

    _isLoadingUsers = false;
    notifyListeners();
  }

  void setUserFilter(String filter) {
    _userFilter = filter;
    loadUsers();
  }

  void setUserStatusFilter(String filter) {
    _userStatusFilter = filter;
    loadUsers();
  }

  void setUserSearchQuery(String query) {
    _userSearchQuery = query;
    loadUsers();
  }

  Future<bool> suspendUser(String userId, String reason) async {
    final success = await _adminService.suspendUser(userId, reason);
    if (success) {
      loadUsers();
      loadDashboardStats();
    }
    return success;
  }

  Future<bool> activateUser(String userId) async {
    final success = await _adminService.activateUser(userId);
    if (success) {
      loadUsers();
      loadDashboardStats();
    }
    return success;
  }

  Future<bool> deleteUser(String userId) async {
    final success = await _adminService.deleteUser(userId);
    if (success) {
      loadUsers();
      loadDashboardStats();
    }
    return success;
  }

  // ==================== Job Moderation ====================

  Future<void> loadJobs() async {
    _isLoadingJobs = true;
    notifyListeners();

    _jobs = await _adminService.getAllJobs(
      status: _jobFilter == 'all' ? null : _jobFilter,
      searchQuery: _jobSearchQuery.isNotEmpty ? _jobSearchQuery : null,
    );

    _isLoadingJobs = false;
    notifyListeners();
  }

  Future<void> loadPendingJobs() async {
    _pendingJobs = await _adminService.getPendingJobs();
    notifyListeners();
  }

  Future<void> loadReportedJobs() async {
    _reportedJobs = await _adminService.getReportedJobs();
    notifyListeners();
  }

  void setJobFilter(String filter) {
    _jobFilter = filter;
    loadJobs();
  }

  void setJobSearchQuery(String query) {
    _jobSearchQuery = query;
    loadJobs();
  }

  Future<bool> approveJob(String jobId) async {
    final success = await _adminService.approveJob(jobId);
    if (success) {
      loadJobs();
      loadPendingJobs();
      loadDashboardStats();
    }
    return success;
  }

  Future<bool> rejectJob(String jobId, String reason) async {
    final success = await _adminService.rejectJob(jobId, reason);
    if (success) {
      loadJobs();
      loadPendingJobs();
      loadDashboardStats();
    }
    return success;
  }

  Future<bool> flagJob(String jobId, String reason) async {
    final success = await _adminService.flagJob(jobId, reason);
    if (success) {
      loadJobs();
    }
    return success;
  }

  Future<bool> removeJob(String jobId) async {
    final success = await _adminService.removeJob(jobId);
    if (success) {
      loadJobs();
      loadDashboardStats();
    }
    return success;
  }

  Future<bool> clearJobReport(String jobId) async {
    final success = await _adminService.clearJobReport(jobId);
    if (success) {
      loadReportedJobs();
    }
    return success;
  }

  // ==================== Company Verification ====================

  Future<void> loadPendingVerifications() async {
    _pendingVerifications = await _adminService.getPendingCompanyVerifications();
    notifyListeners();
  }

  Future<bool> verifyCompany(String companyId) async {
    final success = await _adminService.verifyCompany(companyId);
    if (success) {
      loadPendingVerifications();
      loadDashboardStats();
    }
    return success;
  }

  Future<bool> rejectCompanyVerification(String companyId, String reason) async {
    final success = await _adminService.rejectCompanyVerification(companyId, reason);
    if (success) {
      loadPendingVerifications();
    }
    return success;
  }

  // ==================== System Settings ====================

  Future<Map<String, dynamic>?> getSystemSettings() async {
    return await _adminService.getSystemSettings();
  }

  Future<bool> updateSystemSettings(Map<String, dynamic> settings) async {
    return await _adminService.updateSystemSettings(settings);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
