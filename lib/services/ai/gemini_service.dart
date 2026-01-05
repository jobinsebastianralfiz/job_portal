import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  // IMPORTANT: Replace with your actual Gemini API key
  // Get your key from: https://makersuite.google.com/app/apikey
  static const String _apiKey = 'AIzaSyBsBnwiPcb7twvGi0qgcBEuU4uw846IlPs';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1';

  /// Parse resume text and extract structured information
  Future<ResumeParseResult?> parseResume(String resumeText) async {
    try {
      final prompt = '''
Analyze the following resume text and extract structured information. Return ONLY a valid JSON object with the following structure (no markdown, no extra text):

{
  "personalInfo": {
    "fullName": "string",
    "email": "string",
    "phone": "string",
    "location": "string",
    "linkedIn": "string or null",
    "website": "string or null"
  },
  "summary": "string - professional summary or objective",
  "skills": ["array of skill strings"],
  "experience": [
    {
      "company": "string",
      "title": "string",
      "location": "string",
      "startDate": "string (MM/YYYY)",
      "endDate": "string (MM/YYYY) or 'Present'",
      "description": "string",
      "achievements": ["array of achievement strings"]
    }
  ],
  "education": [
    {
      "institution": "string",
      "degree": "string",
      "field": "string",
      "graduationDate": "string (MM/YYYY)",
      "gpa": "string or null"
    }
  ],
  "certifications": [
    {
      "name": "string",
      "issuer": "string",
      "date": "string or null"
    }
  ],
  "languages": ["array of language strings"],
  "suggestedJobTitles": ["array of 3-5 job titles this person might be suitable for"]
}

Resume Text:
$resumeText
''';

      final response = await _makeRequest(prompt);

      if (response != null) {
        // Try to parse JSON from response
        final jsonStr = _extractJson(response);
        final jsonData = json.decode(jsonStr);
        return ResumeParseResult.fromJson(jsonData);
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing resume: $e');
      return null;
    }
  }

  /// Analyze job fit between a resume and job description
  Future<JobFitAnalysis?> analyzeJobFit({
    required String resumeText,
    required String jobDescription,
  }) async {
    try {
      final prompt = '''
Analyze how well the candidate's resume matches the job description. Return ONLY a valid JSON object with the following structure (no markdown, no extra text):

{
  "overallScore": number (0-100),
  "matchingSkills": ["array of skills from resume that match job requirements"],
  "missingSkills": ["array of required skills not found in resume"],
  "experienceMatch": {
    "score": number (0-100),
    "feedback": "string explaining experience relevance"
  },
  "educationMatch": {
    "score": number (0-100),
    "feedback": "string explaining education relevance"
  },
  "strengths": ["array of 3-5 candidate strengths for this role"],
  "concerns": ["array of potential concerns or gaps"],
  "recommendation": "string - brief hiring recommendation",
  "interviewQuestions": ["array of 3-5 suggested interview questions based on gaps or areas to explore"]
}

Resume:
$resumeText

Job Description:
$jobDescription
''';

      final response = await _makeRequest(prompt);

      if (response != null) {
        final jsonStr = _extractJson(response);
        final jsonData = json.decode(jsonStr);
        return JobFitAnalysis.fromJson(jsonData);
      }

      return null;
    } catch (e) {
      debugPrint('Error analyzing job fit: $e');
      return null;
    }
  }

  /// Generate cover letter based on user profile and job details
  Future<String?> generateCoverLetter({
    required String jobTitle,
    required String companyName,
    String? jobDescription,
    String? resumeText,
    String? userName,
    String? userSummary,
    List<String>? userSkills,
    String? userExperience,
    String? userEducation,
  }) async {
    try {
      final prompt = '''
Generate a professional cover letter for a job application. The letter should be personalized, engaging, and highlight relevant qualifications. Return ONLY the cover letter text, properly formatted with paragraphs.

Job Details:
- Position: $jobTitle
- Company: $companyName
${jobDescription != null ? '- Job Description: $jobDescription' : ''}

Applicant Profile:
${userName != null ? '- Name: $userName' : ''}
${resumeText != null ? '- Resume: $resumeText' : ''}
${userSummary != null ? '- Professional Summary: $userSummary' : ''}
${userSkills != null && userSkills.isNotEmpty ? '- Skills: ${userSkills.join(', ')}' : ''}
${userExperience != null ? '- Experience: $userExperience' : ''}
${userEducation != null ? '- Education: $userEducation' : ''}

Write a compelling cover letter that:
1. Opens with enthusiasm for the specific role and company
2. Highlights relevant skills and experience that match the job
3. Shows understanding of what the company might need
4. Closes with a call to action
5. Maintains a professional but personable tone
''';

      final response = await _makeRequest(prompt);
      return response?.trim();
    } catch (e) {
      debugPrint('Error generating cover letter: $e');
      return null;
    }
  }

  /// Improve resume content with AI suggestions
  Future<ResumeImprovement?> improveResume(String resumeText) async {
    try {
      final prompt = '''
Analyze the following resume and provide improvement suggestions. Return ONLY a valid JSON object with the following structure (no markdown, no extra text):

{
  "overallScore": number (0-100),
  "summaryImprovement": {
    "original": "string - current summary",
    "improved": "string - enhanced summary",
    "feedback": "string - why this is better"
  },
  "experienceImprovements": [
    {
      "original": "string - original bullet point or description",
      "improved": "string - enhanced version with action verbs and metrics",
      "feedback": "string - explanation"
    }
  ],
  "skillsToAdd": ["array of recommended skills to add based on experience"],
  "formattingTips": ["array of formatting improvement suggestions"],
  "generalFeedback": ["array of general improvement tips"],
  "atsScore": number (0-100, how well it would perform in ATS systems),
  "atsTips": ["array of tips to improve ATS compatibility"]
}

Resume:
$resumeText
''';

      final response = await _makeRequest(prompt);

      if (response != null) {
        final jsonStr = _extractJson(response);
        final jsonData = json.decode(jsonStr);
        return ResumeImprovement.fromJson(jsonData);
      }

      return null;
    } catch (e) {
      debugPrint('Error improving resume: $e');
      return null;
    }
  }

  /// Generate a job description based on job title and other details
  Future<String?> generateJobDescription({
    required String jobTitle,
    String? category,
    String? employmentType,
    String? experienceLevel,
    String? workLocation,
  }) async {
    try {
      final prompt = '''
Generate a professional and compelling job description for the following position. The description should be 3-4 paragraphs covering:
1. Role overview and company culture fit
2. Key responsibilities
3. What success looks like in this role

Return ONLY the description text, no headers or extra formatting. Make it engaging and appealing to candidates.

Job Details:
Title: $jobTitle
${category != null ? 'Category: $category' : ''}
${employmentType != null ? 'Employment Type: $employmentType' : ''}
${experienceLevel != null ? 'Experience Level: $experienceLevel' : ''}
${workLocation != null ? 'Work Location: $workLocation' : ''}
''';

      final response = await _makeRequest(prompt);
      return response?.trim();
    } catch (e) {
      debugPrint('Error generating job description: $e');
      return null;
    }
  }

  /// Generate required skills for a job
  Future<List<String>?> generateJobSkills({
    required String jobTitle,
    String? category,
    String? experienceLevel,
  }) async {
    try {
      final prompt = '''
Generate a list of 8-12 relevant skills required for this job position. Include both technical and soft skills as appropriate. Return ONLY a valid JSON array of strings (no markdown, no extra text):

["skill1", "skill2", "skill3", ...]

Job Details:
Title: $jobTitle
${category != null ? 'Category: $category' : ''}
${experienceLevel != null ? 'Experience Level: $experienceLevel' : ''}
''';

      final response = await _makeRequest(prompt);
      if (response != null) {
        final jsonStr = _extractJson(response);
        final List<dynamic> skills = json.decode(jsonStr);
        return skills.cast<String>();
      }
      return null;
    } catch (e) {
      debugPrint('Error generating job skills: $e');
      return null;
    }
  }

  /// Generate job requirements
  Future<List<String>?> generateJobRequirements({
    required String jobTitle,
    String? category,
    String? experienceLevel,
    String? employmentType,
  }) async {
    try {
      final prompt = '''
Generate a list of 5-8 job requirements/qualifications for this position. Include education, experience, certifications, and other qualifications. Each requirement should be a complete sentence. Return ONLY a valid JSON array of strings (no markdown, no extra text):

["requirement1", "requirement2", "requirement3", ...]

Job Details:
Title: $jobTitle
${category != null ? 'Category: $category' : ''}
${experienceLevel != null ? 'Experience Level: $experienceLevel' : ''}
${employmentType != null ? 'Employment Type: $employmentType' : ''}
''';

      final response = await _makeRequest(prompt);
      if (response != null) {
        final jsonStr = _extractJson(response);
        final List<dynamic> requirements = json.decode(jsonStr);
        return requirements.cast<String>();
      }
      return null;
    } catch (e) {
      debugPrint('Error generating job requirements: $e');
      return null;
    }
  }

  /// Generate screening questions for job application
  Future<List<Map<String, String>>?> generateJobScreeningQuestions({
    required String jobTitle,
    String? category,
    String? experienceLevel,
    int count = 5,
  }) async {
    try {
      final prompt = '''
Generate $count effective screening questions for job applicants. Mix of question types: some yes/no, some text, some number-based. Return ONLY a valid JSON array (no markdown, no extra text):

[
  {"question": "question text", "type": "yes_no"},
  {"question": "question text", "type": "text"},
  {"question": "question text", "type": "number"}
]

Types can be: "text", "yes_no", "number"

Job Details:
Title: $jobTitle
${category != null ? 'Category: $category' : ''}
${experienceLevel != null ? 'Experience Level: $experienceLevel' : ''}
''';

      final response = await _makeRequest(prompt);
      if (response != null) {
        final jsonStr = _extractJson(response);
        final List<dynamic> questions = json.decode(jsonStr);
        return questions.map((q) => Map<String, String>.from(q)).toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error generating screening questions: $e');
      return null;
    }
  }

  /// Analyze job match and provide recommendation
  Future<JobMatchResult?> analyzeJobMatch({
    required String jobTitle,
    required String jobDescription,
    required List<String> jobSkills,
    required List<String> jobRequirements,
    String? experienceLevel,
    String? userSummary,
    List<String>? userSkills,
    String? userExperience,
    String? userEducation,
  }) async {
    try {
      final prompt = '''
Analyze how well this candidate matches the job and provide a recommendation. Return ONLY a valid JSON object (no markdown, no extra text):

{
  "matchScore": number (0-100),
  "recommendation": "highly_recommended" | "recommended" | "consider" | "not_recommended",
  "summary": "Brief 1-2 sentence summary of the match",
  "matchingSkills": ["skill1", "skill2"],
  "missingSkills": ["skill1", "skill2"],
  "strengths": ["strength1", "strength2"],
  "improvements": ["area1", "area2"],
  "tips": ["tip1", "tip2"]
}

Job Details:
- Title: $jobTitle
- Description: $jobDescription
- Required Skills: ${jobSkills.join(', ')}
- Requirements: ${jobRequirements.join(', ')}
${experienceLevel != null ? '- Experience Level: $experienceLevel' : ''}

Candidate Profile:
${userSummary != null ? '- Summary: $userSummary' : ''}
${userSkills != null && userSkills.isNotEmpty ? '- Skills: ${userSkills.join(', ')}' : ''}
${userExperience != null ? '- Experience: $userExperience' : ''}
${userEducation != null ? '- Education: $userEducation' : ''}
''';

      final response = await _makeRequest(prompt);
      if (response != null) {
        final jsonStr = _extractJson(response);
        final Map<String, dynamic> data = json.decode(jsonStr);
        return JobMatchResult.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error analyzing job match: $e');
      return null;
    }
  }

  /// Generate a professional summary based on user profile data
  Future<String?> generateProfessionalSummary({
    String? currentJobTitle,
    List<String>? skills,
    String? experience,
    String? education,
  }) async {
    try {
      final prompt = '''
Generate a compelling professional summary for a job seeker's profile. The summary should be 2-3 sentences, highlight key strengths, and be written in first person. Return ONLY the summary text, no quotes or extra formatting.

Profile Information:
${currentJobTitle != null ? 'Current/Desired Role: $currentJobTitle' : ''}
${skills != null && skills.isNotEmpty ? 'Skills: ${skills.join(', ')}' : ''}
${experience != null && experience.isNotEmpty ? 'Experience: $experience' : ''}
${education != null && education.isNotEmpty ? 'Education: $education' : ''}

Generate a professional, engaging summary that would appeal to recruiters and hiring managers. Focus on value the person can bring to a company.
''';

      final response = await _makeRequest(prompt);
      return response?.trim();
    } catch (e) {
      debugPrint('Error generating professional summary: $e');
      return null;
    }
  }

  /// Generate screening questions for a job posting
  Future<List<String>?> generateScreeningQuestions({
    required String jobTitle,
    required String jobDescription,
    int count = 5,
  }) async {
    try {
      final prompt = '''
Generate $count effective screening questions for the following job posting. The questions should help identify qualified candidates and assess both technical skills and cultural fit. Return ONLY a valid JSON array of strings (no markdown, no extra text):

["question 1", "question 2", "question 3", ...]

Job Title: $jobTitle
Job Description:
$jobDescription
''';

      final response = await _makeRequest(prompt);

      if (response != null) {
        final jsonStr = _extractJson(response);
        final List<dynamic> questions = json.decode(jsonStr);
        return questions.cast<String>();
      }

      return null;
    } catch (e) {
      debugPrint('Error generating screening questions: $e');
      return null;
    }
  }

  /// Main API request method
  Future<String?> _makeRequest(String prompt) async {
    try {
      // Use gemini-2.0-flash model
      final url = Uri.parse('$_baseUrl/models/gemini-2.0-flash:generateContent?key=$_apiKey');

      debugPrint('Making Gemini API request...');
      debugPrint('URL: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 8192,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      debugPrint('Gemini API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            debugPrint('Gemini API returned valid response');
            return parts[0]['text'] as String?;
          }
        }
        debugPrint('Gemini API response had no valid candidates');
      } else {
        debugPrint('Gemini API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }

      return null;
    } catch (e) {
      debugPrint('Error making Gemini request: $e');
      return null;
    }
  }

  /// Extract JSON from response that might have markdown code blocks
  String _extractJson(String response) {
    // Remove markdown code blocks if present
    var cleaned = response.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    return cleaned.trim();
  }
}

// ==================== Data Models ====================

class ResumeParseResult {
  final PersonalInfo personalInfo;
  final String summary;
  final List<String> skills;
  final List<Experience> experience;
  final List<Education> education;
  final List<Certification> certifications;
  final List<String> languages;
  final List<String> suggestedJobTitles;

  ResumeParseResult({
    required this.personalInfo,
    required this.summary,
    required this.skills,
    required this.experience,
    required this.education,
    required this.certifications,
    required this.languages,
    required this.suggestedJobTitles,
  });

  factory ResumeParseResult.fromJson(Map<String, dynamic> json) {
    return ResumeParseResult(
      personalInfo: PersonalInfo.fromJson(json['personalInfo'] ?? {}),
      summary: json['summary'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      experience: (json['experience'] as List?)
              ?.map((e) => Experience.fromJson(e))
              .toList() ??
          [],
      education: (json['education'] as List?)
              ?.map((e) => Education.fromJson(e))
              .toList() ??
          [],
      certifications: (json['certifications'] as List?)
              ?.map((e) => Certification.fromJson(e))
              .toList() ??
          [],
      languages: List<String>.from(json['languages'] ?? []),
      suggestedJobTitles: List<String>.from(json['suggestedJobTitles'] ?? []),
    );
  }
}

class PersonalInfo {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? location;
  final String? linkedIn;
  final String? website;

  PersonalInfo({
    this.fullName,
    this.email,
    this.phone,
    this.location,
    this.linkedIn,
    this.website,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      location: json['location'],
      linkedIn: json['linkedIn'],
      website: json['website'],
    );
  }
}

class Experience {
  final String company;
  final String title;
  final String? location;
  final String? startDate;
  final String? endDate;
  final String? description;
  final List<String> achievements;

  Experience({
    required this.company,
    required this.title,
    this.location,
    this.startDate,
    this.endDate,
    this.description,
    this.achievements = const [],
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      company: json['company'] ?? '',
      title: json['title'] ?? '',
      location: json['location'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      description: json['description'],
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }
}

class Education {
  final String institution;
  final String? degree;
  final String? field;
  final String? graduationDate;
  final String? gpa;

  Education({
    required this.institution,
    this.degree,
    this.field,
    this.graduationDate,
    this.gpa,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      institution: json['institution'] ?? '',
      degree: json['degree'],
      field: json['field'],
      graduationDate: json['graduationDate'],
      gpa: json['gpa'],
    );
  }
}

class Certification {
  final String name;
  final String? issuer;
  final String? date;

  Certification({
    required this.name,
    this.issuer,
    this.date,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    return Certification(
      name: json['name'] ?? '',
      issuer: json['issuer'],
      date: json['date'],
    );
  }
}

class JobFitAnalysis {
  final int overallScore;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final MatchSection experienceMatch;
  final MatchSection educationMatch;
  final List<String> strengths;
  final List<String> concerns;
  final String recommendation;
  final List<String> interviewQuestions;

  JobFitAnalysis({
    required this.overallScore,
    required this.matchingSkills,
    required this.missingSkills,
    required this.experienceMatch,
    required this.educationMatch,
    required this.strengths,
    required this.concerns,
    required this.recommendation,
    required this.interviewQuestions,
  });

  factory JobFitAnalysis.fromJson(Map<String, dynamic> json) {
    return JobFitAnalysis(
      overallScore: json['overallScore'] ?? 0,
      matchingSkills: List<String>.from(json['matchingSkills'] ?? []),
      missingSkills: List<String>.from(json['missingSkills'] ?? []),
      experienceMatch: MatchSection.fromJson(json['experienceMatch'] ?? {}),
      educationMatch: MatchSection.fromJson(json['educationMatch'] ?? {}),
      strengths: List<String>.from(json['strengths'] ?? []),
      concerns: List<String>.from(json['concerns'] ?? []),
      recommendation: json['recommendation'] ?? '',
      interviewQuestions: List<String>.from(json['interviewQuestions'] ?? []),
    );
  }
}

class MatchSection {
  final int score;
  final String feedback;

  MatchSection({required this.score, required this.feedback});

  factory MatchSection.fromJson(Map<String, dynamic> json) {
    return MatchSection(
      score: json['score'] ?? 0,
      feedback: json['feedback'] ?? '',
    );
  }
}

class ResumeImprovement {
  final int overallScore;
  final SummaryImprovement? summaryImprovement;
  final List<ExperienceImprovement> experienceImprovements;
  final List<String> skillsToAdd;
  final List<String> formattingTips;
  final List<String> generalFeedback;
  final int atsScore;
  final List<String> atsTips;

  ResumeImprovement({
    required this.overallScore,
    this.summaryImprovement,
    required this.experienceImprovements,
    required this.skillsToAdd,
    required this.formattingTips,
    required this.generalFeedback,
    required this.atsScore,
    required this.atsTips,
  });

  factory ResumeImprovement.fromJson(Map<String, dynamic> json) {
    return ResumeImprovement(
      overallScore: json['overallScore'] ?? 0,
      summaryImprovement: json['summaryImprovement'] != null
          ? SummaryImprovement.fromJson(json['summaryImprovement'])
          : null,
      experienceImprovements: (json['experienceImprovements'] as List?)
              ?.map((e) => ExperienceImprovement.fromJson(e))
              .toList() ??
          [],
      skillsToAdd: List<String>.from(json['skillsToAdd'] ?? []),
      formattingTips: List<String>.from(json['formattingTips'] ?? []),
      generalFeedback: List<String>.from(json['generalFeedback'] ?? []),
      atsScore: json['atsScore'] ?? 0,
      atsTips: List<String>.from(json['atsTips'] ?? []),
    );
  }
}

class SummaryImprovement {
  final String original;
  final String improved;
  final String feedback;

  SummaryImprovement({
    required this.original,
    required this.improved,
    required this.feedback,
  });

  factory SummaryImprovement.fromJson(Map<String, dynamic> json) {
    return SummaryImprovement(
      original: json['original'] ?? '',
      improved: json['improved'] ?? '',
      feedback: json['feedback'] ?? '',
    );
  }
}

class ExperienceImprovement {
  final String original;
  final String improved;
  final String feedback;

  ExperienceImprovement({
    required this.original,
    required this.improved,
    required this.feedback,
  });

  factory ExperienceImprovement.fromJson(Map<String, dynamic> json) {
    return ExperienceImprovement(
      original: json['original'] ?? '',
      improved: json['improved'] ?? '',
      feedback: json['feedback'] ?? '',
    );
  }
}

class JobMatchResult {
  final int matchScore;
  final String recommendation;
  final String summary;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> tips;

  JobMatchResult({
    required this.matchScore,
    required this.recommendation,
    required this.summary,
    required this.matchingSkills,
    required this.missingSkills,
    required this.strengths,
    required this.improvements,
    required this.tips,
  });

  factory JobMatchResult.fromJson(Map<String, dynamic> json) {
    return JobMatchResult(
      matchScore: json['matchScore'] ?? 0,
      recommendation: json['recommendation'] ?? 'consider',
      summary: json['summary'] ?? '',
      matchingSkills: List<String>.from(json['matchingSkills'] ?? []),
      missingSkills: List<String>.from(json['missingSkills'] ?? []),
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
    );
  }

  bool get isHighlyRecommended => recommendation == 'highly_recommended';
  bool get isRecommended => recommendation == 'recommended';
  bool get shouldConsider => recommendation == 'consider';
  bool get isNotRecommended => recommendation == 'not_recommended';

  String get recommendationText {
    switch (recommendation) {
      case 'highly_recommended':
        return 'Highly Recommended';
      case 'recommended':
        return 'Recommended';
      case 'consider':
        return 'Worth Considering';
      case 'not_recommended':
        return 'Not a Strong Match';
      default:
        return 'Unknown';
    }
  }
}
