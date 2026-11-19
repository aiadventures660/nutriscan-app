import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_report.dart';

class ContentReportingService {
  static const String _reportsKey = 'content_reports';
  static const String _reportStatsKey = 'reporting_stats';

  // Submit a content report
  Future<String> submitReport({
    required String contentId,
    required String contentType,
    required String contentTitle,
    required String contentText,
    required ReportReason reason,
    String customReason = '',
    String? userEmail,
  }) async {
    try {
      final reportId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final report = ContentReport(
        id: reportId,
        contentId: contentId,
        contentType: contentType,
        contentTitle: contentTitle,
        contentText: contentText,
        reportReason: reason.displayName,
        customReason: customReason,
        timestamp: DateTime.now(),
        userEmail: userEmail,
        status: ContentReportStatus.pending,
      );

      await _saveReport(report);
      await _updateReportingStats(reason);
      
      // In a real app, this would send to your backend
      await _simulateServerSubmission(report);
      
      debugPrint('✅ Content report submitted: ${report.id}');
      return reportId;
    } catch (e) {
      debugPrint('⚠️ Failed to submit report: $e');
      throw Exception('Failed to submit report: $e');
    }
  }

  // Get all reports (for admin/debugging purposes)
  Future<List<ContentReport>> getAllReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList(_reportsKey) ?? [];
      
      return reportsJson.map((reportJson) {
        final reportMap = json.decode(reportJson) as Map<String, dynamic>;
        return ContentReport.fromJson(reportMap);
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to load reports: $e');
      return [];
    }
  }

  // Get reporting statistics
  Future<Map<String, int>> getReportingStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_reportStatsKey);
      
      if (statsJson != null) {
        final statsMap = json.decode(statsJson) as Map<String, dynamic>;
        return Map<String, int>.from(statsMap);
      }
      
      return <String, int>{};
    } catch (e) {
      debugPrint('⚠️ Failed to load reporting stats: $e');
      return <String, int>{};
    }
  }

  // Check if content has been reported
  Future<bool> hasContentBeenReported(String contentId) async {
    try {
      final reports = await getAllReports();
      return reports.any((report) => report.contentId == contentId);
    } catch (e) {
      debugPrint('⚠️ Failed to check report status: $e');
      return false;
    }
  }

  // Get reports for specific content
  Future<List<ContentReport>> getReportsForContent(String contentId) async {
    try {
      final reports = await getAllReports();
      return reports.where((report) => report.contentId == contentId).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to get content reports: $e');
      return [];
    }
  }

  // Save report locally
  Future<void> _saveReport(ContentReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList(_reportsKey) ?? [];
    
    reports.add(json.encode(report.toJson()));
    await prefs.setStringList(_reportsKey, reports);
  }

  // Update reporting statistics
  Future<void> _updateReportingStats(ReportReason reason) async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_reportStatsKey);
    
    Map<String, int> stats = {};
    if (statsJson != null) {
      stats = Map<String, int>.from(json.decode(statsJson));
    }
    
    final reasonKey = reason.displayName;
    stats[reasonKey] = (stats[reasonKey] ?? 0) + 1;
    stats['total'] = (stats['total'] ?? 0) + 1;
    
    await prefs.setString(_reportStatsKey, json.encode(stats));
  }

  // Simulate sending report to server
  Future<void> _simulateServerSubmission(ContentReport report) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // In a real app, you would:
    // 1. Send the report to your backend API
    // 2. Store it in a database
    // 3. Trigger content moderation workflows
    // 4. Send notifications to moderators
    
    debugPrint('🔄 Report sent to moderation team: ${report.id}');
    debugPrint('📧 Content: "${report.contentTitle}"');
    debugPrint('⚠️ Reason: ${report.reportReason}');
    
    if (report.customReason.isNotEmpty) {
      debugPrint('💬 Additional details: ${report.customReason}');
    }
  }

  // Clear all reports (for testing/debugging)
  Future<void> clearAllReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_reportsKey);
      await prefs.remove(_reportStatsKey);
      debugPrint('✅ All reports cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear reports: $e');
    }
  }

  // Get user-friendly status message
  String getStatusMessage(ContentReportStatus status) {
    switch (status) {
      case ContentReportStatus.pending:
        return 'Report submitted and pending review';
      case ContentReportStatus.reviewing:
        return 'Report is being reviewed by our team';
      case ContentReportStatus.resolved:
        return 'Report has been resolved';
      case ContentReportStatus.dismissed:
        return 'Report was reviewed and dismissed';
    }
  }

  // Check if user can report (prevent spam)
  Future<bool> canUserReport(String contentId, {String? userEmail}) async {
    try {
      final reports = await getReportsForContent(contentId);
      
      if (userEmail != null) {
        // Check if user already reported this content
        final userReports = reports.where((r) => r.userEmail == userEmail);
        if (userReports.isNotEmpty) {
          return false; // User already reported this content
        }
      }
      
      // Check if content has too many recent reports (spam protection)
      final recentReports = reports.where((r) {
        final hoursSinceReport = DateTime.now().difference(r.timestamp).inHours;
        return hoursSinceReport < 24; // Reports in last 24 hours
      });
      
      return recentReports.length < 10; // Max 10 reports per content per day
    } catch (e) {
      debugPrint('⚠️ Failed to check reporting eligibility: $e');
      return true; // Allow reporting on error
    }
  }
}
