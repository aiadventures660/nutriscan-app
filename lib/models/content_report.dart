class ContentReport {
  final String id;
  final String contentId;
  final String contentType; // 'nutrition_tip', 'scan_result', 'alternative_food'
  final String contentTitle;
  final String contentText;
  final String reportReason;
  final String customReason;
  final DateTime timestamp;
  final String? userEmail;
  final ContentReportStatus status;

  ContentReport({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.contentTitle,
    required this.contentText,
    required this.reportReason,
    this.customReason = '',
    required this.timestamp,
    this.userEmail,
    this.status = ContentReportStatus.pending,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contentId': contentId,
      'contentType': contentType,
      'contentTitle': contentTitle,
      'contentText': contentText,
      'reportReason': reportReason,
      'customReason': customReason,
      'timestamp': timestamp.toIso8601String(),
      'userEmail': userEmail,
      'status': status.toString(),
    };
  }

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    return ContentReport(
      id: json['id'],
      contentId: json['contentId'],
      contentType: json['contentType'],
      contentTitle: json['contentTitle'],
      contentText: json['contentText'],
      reportReason: json['reportReason'],
      customReason: json['customReason'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      userEmail: json['userEmail'],
      status: ContentReportStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
        orElse: () => ContentReportStatus.pending,
      ),
    );
  }
}

enum ContentReportStatus {
  pending,
  reviewing,
  resolved,
  dismissed,
}

enum ReportReason {
  inappropriate,
  inaccurate,
  harmful,
  spam,
  misinformation,
  offensive,
  other,
}

extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Inappropriate Content';
      case ReportReason.inaccurate:
        return 'Inaccurate Information';
      case ReportReason.harmful:
        return 'Potentially Harmful';
      case ReportReason.spam:
        return 'Spam or Repetitive';
      case ReportReason.misinformation:
        return 'Misinformation';
      case ReportReason.offensive:
        return 'Offensive Language';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.inappropriate:
        return 'Content that violates community guidelines';
      case ReportReason.inaccurate:
        return 'Information that appears to be factually incorrect';
      case ReportReason.harmful:
        return 'Content that could cause harm if followed';
      case ReportReason.spam:
        return 'Repetitive or irrelevant content';
      case ReportReason.misinformation:
        return 'False or misleading health information';
      case ReportReason.offensive:
        return 'Contains offensive or inappropriate language';
      case ReportReason.other:
        return 'Other reason not listed above';
    }
  }
}
