import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/learning_plan_model.dart';
import '../services/learning_plan_service.dart';
import '../screens/learning_plan/report_issue_dialog.dart';

class TopicProgressTile extends StatefulWidget {
  final LearningTopic topic;
  final String moduleId;
  final String exchangeId;
  final bool isMentor;
  final bool isLearner;
  final LearningPlanService planService;

  const TopicProgressTile({
    super.key,
    required this.topic,
    required this.moduleId,
    required this.exchangeId,
    required this.isMentor,
    required this.isLearner,
    required this.planService,
  });

  @override
  State<TopicProgressTile> createState() => _TopicProgressTileState();
}

class _TopicProgressTileState extends State<TopicProgressTile> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: _getBorderColor(widget.topic.learnerStatus),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status Badge Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.topic.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(widget.topic.learnerStatus, widget.topic.taughtByMentor),
              ],
            ),

            // Expected Outcome Section
            if (widget.topic.expectedOutcome != null &&
                widget.topic.expectedOutcome!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Outcome:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.topic.expectedOutcome!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimaryColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],

            // Mentor Notes & Learner Feedback display
            if (widget.topic.mentorNotes != null &&
                widget.topic.mentorNotes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mentor Note: "${widget.topic.mentorNotes}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.primaryColor,
                    ),
              ),
            ],
            if (widget.topic.learnerFeedback != null &&
                widget.topic.learnerFeedback!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Learner Feedback: "${widget.topic.learnerFeedback}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action Buttons Layer
            if (_isSubmitting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              // Mentor Action Controls
              if (widget.isMentor) _buildMentorActionControls(),

              // Learner Action Controls
              if (widget.isLearner) _buildLearnerActionControls(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LearnerTopicStatus status, bool taughtByMentor) {
    IconData icon;
    String label;
    Color color;

    switch (status) {
      case LearnerTopicStatus.completed:
        icon = Icons.check_circle;
        label = '✓ Completed';
        color = AppTheme.successColor;
        break;
      case LearnerTopicStatus.partiallyUnderstood:
        icon = Icons.pie_chart_outline;
        label = '◐ Partially Understood';
        color = const Color(0xFFE67E22);
        break;
      case LearnerTopicStatus.needHelp:
        icon = Icons.help_outline;
        label = '? Need Help';
        color = AppTheme.errorColor;
        break;
      case LearnerTopicStatus.taught:
      case LearnerTopicStatus.pending:
        if (taughtByMentor) {
          icon = Icons.adjust;
          label = '◉ Taught';
          color = const Color(0xFF2980B9);
        } else {
          icon = Icons.circle_outlined;
          label = '○ Not Started';
          color = AppTheme.textSecondaryColor;
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor(LearnerTopicStatus status) {
    switch (status) {
      case LearnerTopicStatus.completed:
        return AppTheme.successColor.withValues(alpha: 0.5);
      case LearnerTopicStatus.partiallyUnderstood:
        return const Color(0xFFE67E22).withValues(alpha: 0.5);
      case LearnerTopicStatus.needHelp:
        return AppTheme.errorColor.withValues(alpha: 0.5);
      case LearnerTopicStatus.taught:
      case LearnerTopicStatus.pending:
        return const Color(0xFFE0E0E0);
    }
  }

  Widget _buildMentorActionControls() {
    if (!widget.topic.taughtByMentor) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showMentorNotesDialog(),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Mark as Taught'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      );
    } else {
      return Row(
        children: [
          const Icon(Icons.verified, size: 18, color: Color(0xFF2980B9)),
          const SizedBox(width: 6),
          const Text(
            'Taught by you',
            style: TextStyle(
              color: Color(0xFF2980B9),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _showMentorNotesDialog(),
            child: const Text('Edit Note', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }
  }

  Widget _buildLearnerActionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm your understanding:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _submitLearnerConfirmation(LearnerTopicStatus.completed),
              icon: const Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
              label: const Text('✓ Completed'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: BorderSide(
                  color: widget.topic.learnerStatus == LearnerTopicStatus.completed
                      ? AppTheme.successColor
                      : Colors.grey.shade300,
                  width: widget.topic.learnerStatus == LearnerTopicStatus.completed ? 2 : 1,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _submitLearnerConfirmation(LearnerTopicStatus.partiallyUnderstood),
              icon: const Icon(Icons.pie_chart_outline, size: 16, color: Color(0xFFE67E22)),
              label: const Text('◐ Partially'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE67E22),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: BorderSide(
                  color: widget.topic.learnerStatus == LearnerTopicStatus.partiallyUnderstood
                      ? const Color(0xFFE67E22)
                      : Colors.grey.shade300,
                  width: widget.topic.learnerStatus == LearnerTopicStatus.partiallyUnderstood ? 2 : 1,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _submitLearnerConfirmation(LearnerTopicStatus.needHelp),
              icon: const Icon(Icons.help_outline, size: 16, color: AppTheme.errorColor),
              label: const Text('? Need Help'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: BorderSide(
                  color: widget.topic.learnerStatus == LearnerTopicStatus.needHelp
                      ? AppTheme.errorColor
                      : Colors.grey.shade300,
                  width: widget.topic.learnerStatus == LearnerTopicStatus.needHelp ? 2 : 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ReportLearningIssueDialog(
                  exchangeId: widget.exchangeId,
                  moduleId: widget.moduleId,
                  topicId: widget.topic.topicId,
                  topicTitle: widget.topic.title,
                ),
              );
            },
            icon: const Icon(Icons.flag_outlined, size: 14, color: AppTheme.textSecondaryColor),
            label: const Text(
              'Report Learning Issue',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
            ),
          ),
        ),
      ],
    );
  }

  void _showMentorNotesDialog() {
    final controller = TextEditingController(text: widget.topic.mentorNotes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Topic as Taught'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Topic: ${widget.topic.title}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Optional Mentor Note',
                hintText: 'e.g. Covered key concepts and code sample',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSubmitting = true);

              try {
                await widget.planService.markTopicAsTaught(
                  exchangeId: widget.exchangeId,
                  moduleId: widget.moduleId,
                  topicId: widget.topic.topicId,
                  mentorNotes: controller.text.trim().isNotEmpty ? controller.text.trim() : null,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSubmitting = false);
              }
            },
            child: const Text('Confirm Taught'),
          ),
        ],
      ),
    );
  }

  void _submitLearnerConfirmation(LearnerTopicStatus status) {
    final controller = TextEditingController(text: widget.topic.learnerFeedback ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Understanding (${_getStatusTitle(status)})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Topic: ${widget.topic.title}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Optional Learner Feedback',
                hintText: 'e.g. Got it! Or mention specific questions.',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSubmitting = true);

              try {
                await widget.planService.confirmTopic(
                  exchangeId: widget.exchangeId,
                  moduleId: widget.moduleId,
                  topicId: widget.topic.topicId,
                  status: status,
                  feedback: controller.text.trim().isNotEmpty ? controller.text.trim() : null,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSubmitting = false);
              }
            },
            child: const Text('Save Status'),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(LearnerTopicStatus status) {
    switch (status) {
      case LearnerTopicStatus.completed:
        return '✓ Completed';
      case LearnerTopicStatus.partiallyUnderstood:
        return '◐ Partially Understood';
      case LearnerTopicStatus.needHelp:
        return '? Need Help';
      case LearnerTopicStatus.pending:
      case LearnerTopicStatus.taught:
        return 'Pending';
    }
  }
}
