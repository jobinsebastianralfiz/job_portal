import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'gemini_service.dart';

/// Service for parsing resumes from various file formats
class ResumeParserService {
  final GeminiService _geminiService = GeminiService();

  /// Parse a resume file and extract structured data
  Future<ResumeParseResult?> parseResumeFile(File file) async {
    try {
      final text = await _extractTextFromFile(file);
      if (text == null || text.isEmpty) {
        debugPrint('Failed to extract text from resume file');
        return null;
      }

      return await _geminiService.parseResume(text);
    } catch (e) {
      debugPrint('Error parsing resume file: $e');
      return null;
    }
  }

  /// Parse resume from text content
  Future<ResumeParseResult?> parseResumeText(String text) async {
    return await _geminiService.parseResume(text);
  }

  /// Parse resume from URL (download and parse)
  Future<ResumeParseResult?> parseResumeFromUrl(String url) async {
    try {
      // Download the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('Failed to download resume: ${response.statusCode}');
        return null;
      }

      // Determine file extension from URL or content-type
      String extension = 'pdf';
      if (url.contains('.pdf')) {
        extension = 'pdf';
      } else if (url.contains('.doc')) {
        extension = url.contains('.docx') ? 'docx' : 'doc';
      } else if (url.contains('.txt')) {
        extension = 'txt';
      }

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_resume.$extension');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Parse the downloaded file
      final result = await parseResumeFile(tempFile);

      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (_) {}

      return result;
    } catch (e) {
      debugPrint('Error parsing resume from URL: $e');
      return null;
    }
  }

  /// Analyze how well a resume matches a job description
  Future<JobFitAnalysis?> analyzeJobFit({
    required File resumeFile,
    required String jobDescription,
  }) async {
    try {
      final text = await _extractTextFromFile(resumeFile);
      if (text == null || text.isEmpty) {
        return null;
      }

      return await _geminiService.analyzeJobFit(
        resumeText: text,
        jobDescription: jobDescription,
      );
    } catch (e) {
      debugPrint('Error analyzing job fit: $e');
      return null;
    }
  }

  /// Analyze job fit from text
  Future<JobFitAnalysis?> analyzeJobFitFromText({
    required String resumeText,
    required String jobDescription,
  }) async {
    return await _geminiService.analyzeJobFit(
      resumeText: resumeText,
      jobDescription: jobDescription,
    );
  }

  /// Analyze job fit from URL
  Future<JobFitAnalysis?> analyzeJobFitFromUrl({
    required String resumeUrl,
    required String jobDescription,
  }) async {
    try {
      // Download and parse the resume first
      final parsed = await parseResumeFromUrl(resumeUrl);
      if (parsed == null) return null;

      // Build resume text from parsed data
      final resumeText = _buildResumeTextFromParsed(parsed);

      return await _geminiService.analyzeJobFit(
        resumeText: resumeText,
        jobDescription: jobDescription,
      );
    } catch (e) {
      debugPrint('Error analyzing job fit from URL: $e');
      return null;
    }
  }

  /// Helper to build text representation from parsed resume
  String _buildResumeTextFromParsed(ResumeParseResult parsed) {
    final buffer = StringBuffer();

    if (parsed.personalInfo.fullName != null) {
      buffer.writeln('Name: ${parsed.personalInfo.fullName}');
    }
    if (parsed.personalInfo.email != null) {
      buffer.writeln('Email: ${parsed.personalInfo.email}');
    }
    if (parsed.summary.isNotEmpty) {
      buffer.writeln('\nSummary:\n${parsed.summary}');
    }
    if (parsed.skills.isNotEmpty) {
      buffer.writeln('\nSkills: ${parsed.skills.join(', ')}');
    }
    if (parsed.experience.isNotEmpty) {
      buffer.writeln('\nExperience:');
      for (final exp in parsed.experience) {
        buffer.writeln('- ${exp.title} at ${exp.company}');
        if (exp.description != null) buffer.writeln('  ${exp.description}');
      }
    }
    if (parsed.education.isNotEmpty) {
      buffer.writeln('\nEducation:');
      for (final edu in parsed.education) {
        buffer.writeln('- ${edu.degree ?? edu.institution}');
      }
    }

    return buffer.toString();
  }

  /// Generate a cover letter based on resume and job
  Future<String?> generateCoverLetter({
    required File resumeFile,
    required String jobTitle,
    required String companyName,
    required String jobDescription,
  }) async {
    try {
      final text = await _extractTextFromFile(resumeFile);
      if (text == null || text.isEmpty) {
        return null;
      }

      return await _geminiService.generateCoverLetter(
        jobTitle: jobTitle,
        companyName: companyName,
        jobDescription: jobDescription,
        resumeText: text,
      );
    } catch (e) {
      debugPrint('Error generating cover letter: $e');
      return null;
    }
  }

  /// Generate cover letter from text
  Future<String?> generateCoverLetterFromText({
    required String jobTitle,
    required String companyName,
    required String jobDescription,
    String? userName,
    String? userSummary,
    List<String>? userSkills,
    String? userExperience,
    String? userEducation,
  }) async {
    return await _geminiService.generateCoverLetter(
      jobTitle: jobTitle,
      companyName: companyName,
      jobDescription: jobDescription,
      userName: userName,
      userSummary: userSummary,
      userSkills: userSkills,
      userExperience: userExperience,
      userEducation: userEducation,
    );
  }

  /// Get AI-powered resume improvement suggestions
  Future<ResumeImprovement?> getResumeImprovements(File resumeFile) async {
    try {
      final text = await _extractTextFromFile(resumeFile);
      if (text == null || text.isEmpty) {
        return null;
      }

      return await _geminiService.improveResume(text);
    } catch (e) {
      debugPrint('Error getting resume improvements: $e');
      return null;
    }
  }

  /// Get improvements from text
  Future<ResumeImprovement?> getResumeImprovementsFromText(String text) async {
    return await _geminiService.improveResume(text);
  }

  /// Get improvements from URL
  Future<ResumeImprovement?> getResumeImprovementsFromUrl(String url) async {
    try {
      final parsed = await parseResumeFromUrl(url);
      if (parsed == null) return null;

      final resumeText = _buildResumeTextFromParsed(parsed);
      return await _geminiService.improveResume(resumeText);
    } catch (e) {
      debugPrint('Error getting improvements from URL: $e');
      return null;
    }
  }

  /// Generate screening questions for a job posting
  Future<List<String>?> generateScreeningQuestions({
    required String jobTitle,
    required String jobDescription,
    int count = 5,
  }) async {
    return await _geminiService.generateScreeningQuestions(
      jobTitle: jobTitle,
      jobDescription: jobDescription,
      count: count,
    );
  }

  /// Extract text from various file formats
  Future<String?> _extractTextFromFile(File file) async {
    try {
      final extension = file.path.split('.').last.toLowerCase();

      switch (extension) {
        case 'pdf':
          return await _extractTextFromPdf(file);
        case 'txt':
          return await file.readAsString();
        case 'doc':
        case 'docx':
          // For Word documents, you might need a different library
          // For now, return a message indicating this
          debugPrint('Word document parsing requires additional setup');
          return null;
        default:
          debugPrint('Unsupported file format: $extension');
          return null;
      }
    } catch (e) {
      debugPrint('Error extracting text from file: $e');
      return null;
    }
  }

  /// Extract text from PDF file using Syncfusion PDF
  Future<String?> _extractTextFromPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      final StringBuffer textBuffer = StringBuffer();

      // Extract text from each page
      for (int i = 0; i < document.pages.count; i++) {
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        final String text = extractor.extractText(startPageIndex: i, endPageIndex: i);
        textBuffer.write(text);
        textBuffer.write('\n');
      }

      document.dispose();
      return textBuffer.toString().trim();
    } catch (e) {
      debugPrint('Error extracting text from PDF: $e');
      return null;
    }
  }
}
