import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/learning_issue_model.dart';
import '../../services/learning_issue_service.dart';

class LearningIssuesAdminScreen extends StatefulWidget {
  final LearningIssueService? issueService;

  const LearningIssuesAdminScreen({
    super.key,
    this.issueService,
  });

  @override
  State<LearningIssuesAdminScreen> createState() => _LearningIssuesAdminScreenState();
}

class _LearningIssuesAdminScreenState extends State<LearningIssuesAdminScreen>
    with SingleTickerProviderStateMixin {
  late final LearningIssueService _issueService;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _issueService = widget.issueService ?? LearningIssueService();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _issueService.isReviewer(),
      builder: (context, authSnapshot) {
        final isAuthorizedReviewer = authSnapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Learning Issue Reviewer Portal'),
            bottom: isAuthorizedReviewer
                ? TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.textSecondaryColor,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: const [
                      Tab(text: 'Open'),
                      Tab(text: 'Under Review'),
                      Tab(text: 'Resolved'),
                      Tab(text: 'Dismissed'),
                    ],
                  )
                : null,
          ),
          body: authSnapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : !isAuthorizedReviewer
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.gavel, size: 64, color: AppTheme.errorColor),
                            const SizedBox(height: 16),
                            Text(
                              'Unauthorized Reviewer Access',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.errorColor,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your account lacks trusted server-side custom claims (reviewer: true). '
                              'All backend operations and global queries are protected server-side by Firestore Security Rules.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondaryColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIssuesList(LearningIssueStatus.open),
                        _buildIssuesList(LearningIssueStatus.underReview),
                        _buildIssuesList(LearningIssueStatus.resolved),
                        _buildIssuesList(LearningIssueStatus.dismissed),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildIssuesList(LearningIssueStatus statusFilter) {
    return StreamBuilder<List<LearningIssueModel>>(
      stream: _issueService.watchAllLearningIssues(status: statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading issues: ${snapshot.error}'),
            ),
          );
        }

        final issues = snapshot.data ?? [];

        if (issues.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_turned_in, size: 64, color: AppTheme.textSecondaryColor),
                const SizedBox(height: 12),
                Text(
                  'No ${statusFilter.name} learning issues found.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: issues.length,
          itemBuilder: (context, index) {
            final issue = issues[index];
            return _buildIssueCard(issue);
          },
        );
      },
    );
  }

  Widget _buildIssueCard(LearningIssueModel issue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    issue.issueType.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildStatusChip(issue.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Exchange ID: ${issue.exchangeId}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
            ),
            Text(
              'Reporter: ${issue.reporterId}  •  Reported: ${issue.reportedUserId}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
            ),

            if (issue.evidenceSnapshot != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Topic: ${issue.evidenceSnapshot!.topicTitle}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (issue.evidenceSnapshot!.expectedOutcome != null)
                      Text(
                        'Agreed Outcome: ${issue.evidenceSnapshot!.expectedOutcome}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Mentor Taught: ${issue.evidenceSnapshot!.taughtByMentor ? "YES" : "NO"}  •  Learner Status: ${issue.evidenceSnapshot!.learnerStatus.name}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    if (issue.evidenceSnapshot!.learnerFeedback != null)
                      Text(
                        'Learner Feedback: "${issue.evidenceSnapshot!.learnerFeedback}"',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            Text(
              'Description: ${issue.description}',
              style: const TextStyle(fontSize: 13),
            ),

            if (issue.status == LearningIssueStatus.resolved ||
                issue.status == LearningIssueStatus.dismissed) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Resolution (${issue.resolution.displayName}): ${issue.resolutionNotes ?? "No notes recorded"}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                ),
              ),
            ],

            if (issue.status == LearningIssueStatus.open ||
                issue.status == LearningIssueStatus.underReview) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showReviewModal(issue),
                  icon: const Icon(Icons.gavel, size: 18),
                  label: const Text('Review & Resolve Issue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(LearningIssueStatus status) {
    Color color;
    switch (status) {
      case LearningIssueStatus.open:
        color = AppTheme.warningColor;
        break;
      case LearningIssueStatus.underReview:
        color = const Color(0xFF2980B9);
        break;
      case LearningIssueStatus.resolved:
        color = AppTheme.successColor;
        break;
      case LearningIssueStatus.dismissed:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  void _showReviewModal(LearningIssueModel issue) {
    LearningIssueResolution selectedResolution = LearningIssueResolution.correctiveSession;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Issue: ${issue.issueType.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select Resolution Action:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    ...LearningIssueResolution.values
                        .where((r) => r != LearningIssueResolution.pending)
                        .map((res) {
                      return RadioListTile<LearningIssueResolution>(
                        title: Text(res.displayName, style: const TextStyle(fontSize: 13)),
                        value: res,
                        groupValue: selectedResolution,
                        dense: true,
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedResolution = val);
                        },
                      );
                    }),

                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Resolution Notes / Instructions',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              try {
                                await _issueService.resolveLearningIssue(
                                  issueId: issue.issueId,
                                  resolution: selectedResolution,
                                  resolutionNotes: notesController.text.trim(),
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Issue resolved and intervention recorded!'),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error resolving issue: $e'),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                              }
                            },
                            child: const Text('Save Resolution'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
