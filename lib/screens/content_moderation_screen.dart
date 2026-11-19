import 'package:flutter/material.dart';
import '../models/content_report.dart';
import '../services/content_reporting_service.dart';
import '../widgets/report_content_button.dart';

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() => _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen> {
  final ContentReportingService _reportingService = ContentReportingService();
  List<ContentReport> _userReports = [];
  Map<String, int> _reportingStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _reportingService.getAllReports();
      final stats = await _reportingService.getReportingStats();

      setState(() {
        _userReports = reports;
        _reportingStats = stats;
      });
    } catch (e) {
      debugPrint('Failed to load moderation data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF122118),
        title: const Text(
          'Content Safety',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF38e07b),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content Safety Banner
                  const ContentModerationBanner(),
                  
                  const SizedBox(height: 24),
                  
                  // AI Content Information
                  _buildAIContentSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Reporting Statistics
                  if (_reportingStats.isNotEmpty) ...[
                    _buildReportingStatsSection(),
                    const SizedBox(height: 24),
                  ],
                  
                  // User Reports
                  _buildUserReportsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Content Guidelines
                  _buildGuidelinesSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildAIContentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFF38e07b),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'AI-Generated Content',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'This app uses Gemini AI to generate personalized nutrition tips based on your scanned foods. While we strive for accuracy, AI-generated content should be verified with healthcare professionals.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Always consult healthcare professionals for medical advice. AI content is for informational purposes only.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportingStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.analytics,
                color: Color(0xFF38e07b),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Community Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Total reports submitted: ${_reportingStats['total'] ?? 0}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reportingStats.entries
                .where((entry) => entry.key != 'total')
                .map((entry) => _buildStatChip(entry.key, entry.value))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String reason, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF38e07b).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38e07b).withOpacity(0.3)),
      ),
      child: Text(
        '$reason: $count',
        style: const TextStyle(
          color: Color(0xFF38e07b),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUserReportsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flag,
                color: Color(0xFF38e07b),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Your Reports',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_userReports.length} reports',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_userReports.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No reports submitted yet',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Help improve our content by reporting inappropriate or inaccurate information.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _userReports.map((report) => _buildReportCard(report)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ContentReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.contentTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(report.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(report.status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Reason: ${report.reportReason}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          
          if (report.customReason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Details: ${report.customReason}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Colors.white54,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTimestamp(report.timestamp),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${report.id.substring(report.id.length - 8)}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelinesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.gavel,
                color: Color(0xFF38e07b),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Content Guidelines',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Please report content that:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 12),
          
          ...[
            'Contains inaccurate nutrition information',
            'Promotes harmful dietary practices',
            'Includes inappropriate or offensive language',
            'Provides misleading health claims',
            'Violates community standards',
          ].map((guideline) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF38e07b),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guideline,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your reports help us maintain quality and safety standards for all users.',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ContentReportStatus status) {
    switch (status) {
      case ContentReportStatus.pending:
        return Colors.orange;
      case ContentReportStatus.reviewing:
        return Colors.blue;
      case ContentReportStatus.resolved:
        return Colors.green;
      case ContentReportStatus.dismissed:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
