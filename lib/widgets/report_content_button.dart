import 'package:flutter/material.dart';
import '../services/content_reporting_service.dart';
import 'content_report_dialog.dart';

enum ReportButtonStyle {
  icon,
  text,
  chip,
  floating,
}

class ReportContentButton extends StatefulWidget {
  final String contentId;
  final String contentType;
  final String contentTitle;
  final String contentText;
  final ReportButtonStyle style;
  final String? customLabel;
  final Color? color;

  const ReportContentButton({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.contentTitle,
    required this.contentText,
    this.style = ReportButtonStyle.icon,
    this.customLabel,
    this.color,
  });

  @override
  State<ReportContentButton> createState() => _ReportContentButtonState();
}

class _ReportContentButtonState extends State<ReportContentButton> {
  final ContentReportingService _reportingService = ContentReportingService();
  bool _isReported = false;

  @override
  void initState() {
    super.initState();
    _checkReportStatus();
  }

  Future<void> _checkReportStatus() async {
    final isReported = await _reportingService.hasContentBeenReported(widget.contentId);
    if (mounted) {
      setState(() {
        _isReported = isReported;
      });
    }
  }

  Color _resolveColor(BuildContext context) {
    if (_isReported) return Colors.red;
    if (widget.color != null) return widget.color!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case ReportButtonStyle.icon:
        return _buildIconButton(context);
      case ReportButtonStyle.text:
        return _buildTextButton(context);
      case ReportButtonStyle.chip:
        return _buildChipButton(context);
      case ReportButtonStyle.floating:
        return _buildFloatingButton(context);
    }
  }

  Widget _buildIconButton(BuildContext context) {
    final color = _resolveColor(context);
    return IconButton(
      onPressed: _showReportDialog,
      icon: Icon(
        _isReported ? Icons.flag : Icons.flag_outlined,
        color: color,
        size: 20,
      ),
      tooltip: 'Report content',
    );
  }

  Widget _buildTextButton(BuildContext context) {
    final color = _resolveColor(context);
    return TextButton.icon(
      onPressed: _showReportDialog,
      icon: Icon(
        _isReported ? Icons.flag : Icons.flag_outlined,
        color: color,
        size: 16,
      ),
      label: Text(
        widget.customLabel ?? (_isReported ? 'Reported' : 'Report'),
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildChipButton(BuildContext context) {
    final color = _resolveColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      onPressed: _showReportDialog,
      avatar: Icon(
        _isReported ? Icons.flag : Icons.flag_outlined,
        color: color,
        size: 16,
      ),
      label: Text(
        widget.customLabel ?? (_isReported ? 'Reported' : 'Report'),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
      side: BorderSide(
        color: _isReported ? Colors.red : (isDark ? Colors.white24 : Colors.black12),
      ),
    );
  }

  Widget _buildFloatingButton(BuildContext context) {
    final color = _resolveColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FloatingActionButton.small(
      onPressed: _showReportDialog,
      backgroundColor: _isReported ? Colors.red : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white),
      elevation: 2,
      child: Icon(
        _isReported ? Icons.flag : Icons.flag_outlined,
        color: color,
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => ContentReportDialog(
        contentId: widget.contentId,
        contentType: widget.contentType,
        contentTitle: widget.contentTitle,
        contentText: widget.contentText,
      ),
    ).then((_) {
      _checkReportStatus();
    });
  }
}

// AI Content Disclaimer Widget
class AIContentDisclaimer extends StatelessWidget {
  final String contentType;
  final bool showReportButton;
  final String? contentId;
  final String? contentTitle;
  final String? contentText;

  const AIContentDisclaimer({
    super.key,
    required this.contentType,
    this.showReportButton = true,
    this.contentId,
    this.contentTitle,
    this.contentText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-adaptive palettes for AI banner
    final cardBg = isDark ? const Color(0xFF0F1E2E) : const Color(0xFFF0F7FF);
    final borderColor = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBAE6FD);
    final iconColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
    final titleColor = isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1);
    final textColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final badgeBg = isDark ? const Color(0xFF162E47) : const Color(0xFFE0F2FE);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0284C7)).withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI-Generated Content',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7)).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Verified Model',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'This $contentType was formulated by NutriScan AI. Please verify with healthcare or dietary professionals.',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showReportButton && contentId != null) ...[
            const SizedBox(width: 6),
            ReportContentButton(
              contentId: contentId!,
              contentType: contentType,
              contentTitle: contentTitle ?? 'AI Content',
              contentText: contentText ?? '',
              style: ReportButtonStyle.icon,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ],
        ],
      ),
    );
  }
}

// Content Moderation Banner
class ContentModerationBanner extends StatelessWidget {
  const ContentModerationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E170A) : const Color(0xFFFFFBEB);
    final borderColor = isDark ? const Color(0xFF452B09) : const Color(0xFFFDE68A);
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Content Safety',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We use AI to provide nutrition information. Help us improve by reporting inappropriate, inaccurate, or harmful content.',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildInfoChip(context, 'AI-Generated', Icons.auto_awesome),
              _buildInfoChip(context, 'User Reports', Icons.flag),
              _buildInfoChip(context, 'Moderated', Icons.verified_user),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.orange),
      label: Text(
        label,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF92400E), fontSize: 12),
      ),
      backgroundColor: isDark ? Colors.orange.withValues(alpha: 0.2) : const Color(0xFFFEF3C7),
      side: BorderSide(color: isDark ? Colors.orange.withValues(alpha: 0.3) : const Color(0xFFFDE68A)),
    );
  }
}
