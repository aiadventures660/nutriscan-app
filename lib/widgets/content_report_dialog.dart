import 'package:flutter/material.dart';
import '../models/content_report.dart';
import '../services/content_reporting_service.dart';

class ContentReportDialog extends StatefulWidget {
  final String contentId;
  final String contentType;
  final String contentTitle;
  final String contentText;

  const ContentReportDialog({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.contentTitle,
    required this.contentText,
  });

  @override
  State<ContentReportDialog> createState() => _ContentReportDialogState();
}

class _ContentReportDialogState extends State<ContentReportDialog> {
  final ContentReportingService _reportingService = ContentReportingService();
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  ReportReason? _selectedReason;
  bool _isSubmitting = false;
  bool _showCustomReason = false;
  bool _includeEmail = false;

  @override
  void dispose() {
    _customReasonController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  color: Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Report Content',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Content info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content: ${widget.contentTitle}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${widget.contentType.replaceAll('_', ' ').toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Reason selection
            const Text(
              'Why are you reporting this content?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: ReportReason.values.map((reason) {
                    return _buildReasonOption(reason);
                  }).toList(),
                ),
              ),
            ),
            
            // Custom reason input
            if (_showCustomReason) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _customReasonController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please provide additional details...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF38e07b)),
                  ),
                ),
              ),
            ],
            
            // Email option
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _includeEmail,
              onChanged: (value) {
                setState(() {
                  _includeEmail = value ?? false;
                });
              },
              title: const Text(
                'Include my email for follow-up (optional)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              activeColor: const Color(0xFF38e07b),
              checkColor: Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            
            if (_includeEmail) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white30),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF38e07b)),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedReason == null || _isSubmitting
                        ? null
                        : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption(ReportReason reason) {
    final isSelected = _selectedReason == reason;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF38e07b) : Colors.white30,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          reason.displayName,
          style: TextStyle(
            color: isSelected ? const Color(0xFF38e07b) : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          reason.description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        leading: Radio<ReportReason>(
          value: reason,
          groupValue: _selectedReason,
          onChanged: (value) {
            setState(() {
              _selectedReason = value;
              _showCustomReason = value == ReportReason.other;
            });
          },
          activeColor: const Color(0xFF38e07b),
        ),
        onTap: () {
          setState(() {
            _selectedReason = reason;
            _showCustomReason = reason == ReportReason.other;
          });
        },
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final canReport = await _reportingService.canUserReport(
        widget.contentId,
        userEmail: _includeEmail ? _emailController.text.trim() : null,
      );

      if (!canReport) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already reported this content or it has been reported recently.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final reportId = await _reportingService.submitReport(
        contentId: widget.contentId,
        contentType: widget.contentType,
        contentTitle: widget.contentTitle,
        contentText: widget.contentText,
        reason: _selectedReason!,
        customReason: _customReasonController.text.trim(),
        userEmail: _includeEmail ? _emailController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ Report submitted successfully',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Report ID: $reportId'),
                const Text('Our team will review this content shortly.'),
              ],
            ),
            backgroundColor: const Color(0xFF38e07b),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
