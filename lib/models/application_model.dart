import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String applicantId;
  final String applicantName;
  final String? applicantImage;
  final String providerId;
  final String companyId;
  final String companyName;
  final String? coverLetter;
  final String? resume;
  final List<String>? documents;
  final List<ScreeningAnswer>? answers;
  final String status;
  final List<StatusHistory> statusHistory;
  final InterviewDetails? interview;
  final String? providerNotes;
  final int? rating;
  final DateTime appliedAt;
  final DateTime updatedAt;

  ApplicationModel({
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.applicantId,
    required this.applicantName,
    this.applicantImage,
    required this.providerId,
    required this.companyId,
    required this.companyName,
    this.coverLetter,
    this.resume,
    this.documents,
    this.answers,
    required this.status,
    required this.statusHistory,
    this.interview,
    this.providerNotes,
    this.rating,
    required this.appliedAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'applicationId': applicationId,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantImage': applicantImage,
      'providerId': providerId,
      'companyId': companyId,
      'companyName': companyName,
      'coverLetter': coverLetter,
      'resume': resume,
      'documents': documents,
      'answers': answers?.map((a) => a.toJson()).toList(),
      'status': status,
      'statusHistory': statusHistory.map((s) => s.toJson()).toList(),
      'interview': interview?.toJson(),
      'providerNotes': providerNotes,
      'rating': rating,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      applicationId: json['applicationId'] as String? ?? '',
      jobId: json['jobId'] as String? ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      applicantId: json['applicantId'] as String? ?? '',
      applicantName: json['applicantName'] as String? ?? '',
      applicantImage: json['applicantImage'] as String?,
      providerId: json['providerId'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      coverLetter: json['coverLetter'] as String?,
      resume: json['resume'] as String?,
      documents: (json['documents'] as List<dynamic>?)?.cast<String>(),
      answers: (json['answers'] as List<dynamic>?)
          ?.map((a) => ScreeningAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? 'pending',
      statusHistory: (json['statusHistory'] as List<dynamic>?)
              ?.map((s) => StatusHistory.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      interview: json['interview'] != null
          ? InterviewDetails.fromJson(json['interview'] as Map<String, dynamic>)
          : null,
      providerNotes: json['providerNotes'] as String?,
      rating: json['rating'] as int?,
      appliedAt: json['appliedAt'] != null
          ? (json['appliedAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  ApplicationModel copyWith({
    String? applicationId,
    String? jobId,
    String? jobTitle,
    String? applicantId,
    String? applicantName,
    String? applicantImage,
    String? providerId,
    String? companyId,
    String? companyName,
    String? coverLetter,
    String? resume,
    List<String>? documents,
    List<ScreeningAnswer>? answers,
    String? status,
    List<StatusHistory>? statusHistory,
    InterviewDetails? interview,
    String? providerNotes,
    int? rating,
    DateTime? appliedAt,
    DateTime? updatedAt,
  }) {
    return ApplicationModel(
      applicationId: applicationId ?? this.applicationId,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      applicantImage: applicantImage ?? this.applicantImage,
      providerId: providerId ?? this.providerId,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      coverLetter: coverLetter ?? this.coverLetter,
      resume: resume ?? this.resume,
      documents: documents ?? this.documents,
      answers: answers ?? this.answers,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      interview: interview ?? this.interview,
      providerNotes: providerNotes ?? this.providerNotes,
      rating: rating ?? this.rating,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isReviewed => status == 'reviewed';
  bool get isShortlisted => status == 'shortlisted';
  bool get isInterview => status == 'interview';
  bool get isOffered => status == 'offered';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isWithdrawn => status == 'withdrawn';

  bool get hasInterview => interview != null && interview!.scheduledAt != null;

  // Compatibility getters for admin/provider views
  DateTime? get interviewDate => interview?.scheduledAt;
  String? get interviewType => interview?.type;
  String? get interviewLocation => interview?.location;
  List<ScreeningAnswer>? get screeningAnswers => answers;
  String? get notes => providerNotes;
  double? get expectedSalary => null; // Not tracked in current model
  DateTime? get availableFrom => null; // Not tracked in current model

  // Status timestamps from history
  DateTime? get reviewedAt => _getStatusTimestamp('reviewed');
  DateTime? get shortlistedAt => _getStatusTimestamp('shortlisted');
  DateTime? get offeredAt => _getStatusTimestamp('offered');
  DateTime? get acceptedAt => _getStatusTimestamp('accepted');
  DateTime? get rejectedAt => _getStatusTimestamp('rejected');

  DateTime? _getStatusTimestamp(String statusName) {
    try {
      return statusHistory
          .firstWhere((h) => h.status == statusName)
          .timestamp;
    } catch (_) {
      return null;
    }
  }
}

class ScreeningAnswer {
  final String questionId;
  final String question;
  final String answer;

  ScreeningAnswer({
    required this.questionId,
    required this.question,
    required this.answer,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'question': question,
      'answer': answer,
    };
  }

  factory ScreeningAnswer.fromJson(Map<String, dynamic> json) {
    return ScreeningAnswer(
      questionId: json['questionId'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class StatusHistory {
  final String status;
  final DateTime timestamp;
  final String? note;
  final String? updatedBy;

  StatusHistory({
    required this.status,
    required this.timestamp,
    this.note,
    this.updatedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
      'updatedBy': updatedBy,
    };
  }

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: json['status'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      note: json['note'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }
}

class InterviewDetails {
  final DateTime? scheduledAt;
  final String? type;
  final String? meetingLink;
  final String? location;
  final String? notes;
  final int? duration;
  final String? status;

  InterviewDetails({
    this.scheduledAt,
    this.type,
    this.meetingLink,
    this.location,
    this.notes,
    this.duration,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
      'type': type,
      'meetingLink': meetingLink,
      'location': location,
      'notes': notes,
      'duration': duration,
      'status': status,
    };
  }

  factory InterviewDetails.fromJson(Map<String, dynamic> json) {
    return InterviewDetails(
      scheduledAt: json['scheduledAt'] != null
          ? (json['scheduledAt'] as Timestamp).toDate()
          : null,
      type: json['type'] as String?,
      meetingLink: json['meetingLink'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      duration: json['duration'] as int?,
      status: json['status'] as String?,
    );
  }

  bool get isScheduled => scheduledAt != null;
  bool get isPast => scheduledAt != null && scheduledAt!.isBefore(DateTime.now());
  bool get isUpcoming => scheduledAt != null && scheduledAt!.isAfter(DateTime.now());
}
