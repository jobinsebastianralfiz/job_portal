import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ai/gemini_service.dart';
import '../services/ai/resume_parser_service.dart';

class AIProvider extends ChangeNotifier {
  final ResumeParserService _resumeParserService = ResumeParserService();

  // State
  bool _isLoading = false;
  String? _error;

  // Parsed data
  ResumeParseResult? _parsedResume;
  JobFitAnalysis? _jobFitAnalysis;
  ResumeImprovement? _resumeImprovement;
  String? _generatedCoverLetter;
  List<String>? _screeningQuestions;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  ResumeParseResult? get parsedResume => _parsedResume;
  JobFitAnalysis? get jobFitAnalysis => _jobFitAnalysis;
  ResumeImprovement? get resumeImprovement => _resumeImprovement;
  String? get generatedCoverLetter => _generatedCoverLetter;
  List<String>? get screeningQuestions => _screeningQuestions;

  /// Parse a resume file
  Future<bool> parseResume(File file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _parsedResume = await _resumeParserService.parseResumeFile(file);

      _isLoading = false;
      notifyListeners();

      return _parsedResume != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Parse resume from text
  Future<bool> parseResumeFromText(String text) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _parsedResume = await _resumeParserService.parseResumeText(text);

      _isLoading = false;
      notifyListeners();

      return _parsedResume != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Parse resume from URL
  Future<bool> parseResumeFromUrl(String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _parsedResume = await _resumeParserService.parseResumeFromUrl(url);

      _isLoading = false;
      notifyListeners();

      return _parsedResume != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Analyze job fit
  Future<bool> analyzeJobFit({
    required File resumeFile,
    required String jobDescription,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobFitAnalysis = await _resumeParserService.analyzeJobFit(
        resumeFile: resumeFile,
        jobDescription: jobDescription,
      );

      _isLoading = false;
      notifyListeners();

      return _jobFitAnalysis != null;
    } catch (e) {


      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Analyze job fit from text
  Future<bool> analyzeJobFitFromText({
    required String resumeText,
    required String jobDescription,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobFitAnalysis = await _resumeParserService.analyzeJobFitFromText(
        resumeText: resumeText,
        jobDescription: jobDescription,
      );

      _isLoading = false;
      notifyListeners();

      return _jobFitAnalysis != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Analyze job fit from URL
  Future<bool> analyzeJobFitFromUrl({
    required String resumeUrl,
    required String jobDescription,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobFitAnalysis = await _resumeParserService.analyzeJobFitFromUrl(
        resumeUrl: resumeUrl,
        jobDescription: jobDescription,
      );

      _isLoading = false;
      notifyListeners();

      return _jobFitAnalysis != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Generate cover letter
  Future<bool> generateCoverLetter({
    required File resumeFile,
    required String jobTitle,
    required String companyName,
    required String jobDescription,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _generatedCoverLetter = await _resumeParserService.generateCoverLetter(
        resumeFile: resumeFile,
        jobTitle: jobTitle,
        companyName: companyName,
        jobDescription: jobDescription,
      );

      _isLoading = false;
      notifyListeners();

      return _generatedCoverLetter != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Generate cover letter from text
  Future<bool> generateCoverLetterFromText({
    required String jobTitle,
    required String companyName,
    required String jobDescription,
    String? userName,
    String? userSummary,
    List<String>? userSkills,
    String? userExperience,
    String? userEducation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _generatedCoverLetter = await _resumeParserService.generateCoverLetterFromText(
        jobTitle: jobTitle,
        companyName: companyName,
        jobDescription: jobDescription,
        userName: userName,
        userSummary: userSummary,
        userSkills: userSkills,
        userExperience: userExperience,
        userEducation: userEducation,
      );

      _isLoading = false;
      notifyListeners();

      return _generatedCoverLetter != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get resume improvement suggestions
  Future<bool> getResumeImprovements(File file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _resumeImprovement = await _resumeParserService.getResumeImprovements(file);

      _isLoading = false;
      notifyListeners();

      return _resumeImprovement != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get improvements from text
  Future<bool> getResumeImprovementsFromText(String text) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _resumeImprovement = await _resumeParserService.getResumeImprovementsFromText(text);

      _isLoading = false;
      notifyListeners();

      return _resumeImprovement != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get improvements from URL
  Future<bool> getResumeImprovementsFromUrl(String url) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _resumeImprovement = await _resumeParserService.getResumeImprovementsFromUrl(url);

      _isLoading = false;
      notifyListeners();

      return _resumeImprovement != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Generate screening questions
  Future<bool> generateScreeningQuestions({
    required String jobTitle,
    required String jobDescription,
    int count = 5,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _screeningQuestions = await _resumeParserService.generateScreeningQuestions(
        jobTitle: jobTitle,
        jobDescription: jobDescription,
        count: count,
      );

      _isLoading = false;
      notifyListeners();

      return _screeningQuestions != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear all data
  void clearAll() {
    _parsedResume = null;
    _jobFitAnalysis = null;
    _resumeImprovement = null;
    _generatedCoverLetter = null;
    _screeningQuestions = null;
    _error = null;
    notifyListeners();
  }

  /// Clear specific data
  void clearParsedResume() {
    _parsedResume = null;
    notifyListeners();
  }

  void clearJobFitAnalysis() {
    _jobFitAnalysis = null;
    notifyListeners();
  }

  void clearResumeImprovement() {
    _resumeImprovement = null;
    notifyListeners();
  }

  void clearGeneratedCoverLetter() {
    _generatedCoverLetter = null;
    notifyListeners();
  }

  void clearScreeningQuestions() {
    _screeningQuestions = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
