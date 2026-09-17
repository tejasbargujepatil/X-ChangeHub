import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/learning_issue_model.dart';
import '../../services/learning_issue_service.dart';

class ReportLearningIssueDialog extends StatefulWidget {
  final String exchangeId;
  final String moduleId;
  final String topicId;
  final String topicTitle;
  final LearningIssueService? issueService;

  const ReportLearningIssueDialog({
    super.key,
    required this.exchangeId,
    required this.moduleId,
    required this.topicId,
    required this.topicTitle,
    this.issueService,
  });

  @override
  State<ReportLearningIssueDialog> createState() => _ReportLearningIssueDialogState();
}

class _ReportLearningIssueDialogState extends State<ReportLearningIssueDialog> {
  late final LearningIssueService _issueService;
  LearningIssueType _selectedType = LearningIssueType.topicNotTaught;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _issueService = widget.issueService ?? LearningIssueService();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitIssue() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the learning issue.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _issueService.createLearningIssue(
        exchangeId: widget.exchangeId,
        moduleId: widget.moduleId,
        topicId: widget.topicId,
        issueType: _selectedType,
        description: description,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Learning Issue reported. Our team will review the evidence.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit issue: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report a Learning Issue',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Topic: ${widget.topicTitle}',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What issue did you encounter with this topic?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),

            ...LearningIssueType.values.where((t) => t != LearningIssueType.repeatedLearningIssue).map((type) {
              return RadioListTile<LearningIssueType>(
                title: Text(type.displayName, style: const TextStyle(fontSize: 13)),
                value: type,
                groupValue: _selectedType,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: _isSubmitting
                    ? null
                    : (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
              );
            }),

            const SizedBox(height: 12),
            const Text(
              'Additional Details & Context:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe what happened or what additional help is needed...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitIssue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit Issue'),
        ),
      ],
    );
  }
}
