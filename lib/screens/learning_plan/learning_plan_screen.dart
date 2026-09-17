import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/learning_plan_model.dart';
import '../../services/learning_plan_service.dart';
import '../../services/learning_issue_service.dart';
import '../../widgets/topic_progress_tile.dart';
import 'create_plan_screen.dart';
import '../admin/learning_issues_admin_screen.dart';

class LearningPlanScreen extends StatefulWidget {
  final String exchangeId;
  final String currentUserId;
  final String mentorId;
  final String learnerId;
  final String skillName;

  const LearningPlanScreen({
    super.key,
    required this.exchangeId,
    required this.currentUserId,
    required this.mentorId,
    required this.learnerId,
    required this.skillName,
  });

  @override
  State<LearningPlanScreen> createState() => _LearningPlanScreenState();
}

class _LearningPlanScreenState extends State<LearningPlanScreen> {
  final LearningPlanService _planService = LearningPlanService();
  final LearningIssueService _issueService = LearningIssueService();

  @override
  Widget build(BuildContext context) {
    final bool isMentor = widget.currentUserId == widget.mentorId;
    final bool isLearner = widget.currentUserId == widget.learnerId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Plan'),
        actions: [
          FutureBuilder<bool>(
            future: _issueService.isReviewer(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return IconButton(
                  icon: const Icon(Icons.gavel_outlined),
                  tooltip: 'Review Issues',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LearningIssuesAdminScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          StreamBuilder<LearningPlan?>(
            stream: _planService.watchLearningPlan(widget.exchangeId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final plan = snapshot.data!;
                if (plan.status == LearningPlanStatus.draft && (isMentor || isLearner)) {
                  return IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Plan Draft',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateLearningPlanScreen(
                            exchangeId: widget.exchangeId,
                            mentorId: widget.mentorId,
                            learnerId: widget.learnerId,
                            skillName: widget.skillName,
                            initialPlan: plan,
                          ),
                        ),
                      );
                    },
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<LearningPlan?>(
        stream: _planService.watchLearningPlan(widget.exchangeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final plan = snapshot.data;

          if (plan == null) {
            return _buildNoPlanState(context, isMentor, isLearner);
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Plan Status Banner
                  _buildPlanHeader(plan),

                  const SizedBox(height: 20),

                  // Overall Progress Card
                  _buildProgressSummaryCard(plan),

                  const SizedBox(height: 24),

                  // Modules & Topics List
                  Text(
                    'Curriculum & Topics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  if (plan.modules.isEmpty)
                    _buildEmptyModulesMessage()
                  else
                    ...plan.modules.map((module) => _buildModuleSection(
                          module,
                          plan,
                          isMentor,
                          isLearner,
                        )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanHeader(LearningPlan plan) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.skillName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Structured Peer Learning Plan',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
        _buildPlanStatusChip(plan.status),
      ],
    );
  }

  Widget _buildPlanStatusChip(LearningPlanStatus status) {
    Color color;
    String label;

    switch (status) {
      case LearningPlanStatus.active:
        color = AppTheme.primaryColor;
        label = 'Active Plan';
        break;
      case LearningPlanStatus.draft:
        color = AppTheme.warningColor;
        label = 'Draft';
        break;
      case LearningPlanStatus.completed:
        color = AppTheme.successColor;
        label = 'Completed';
        break;
      case LearningPlanStatus.disputed:
        color = AppTheme.errorColor;
        label = 'Disputed';
        break;
      case LearningPlanStatus.cancelled:
        color = Colors.grey;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildProgressSummaryCard(LearningPlan plan) {
    final double percentage = plan.overallProgressPercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Learning Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricStat('Total', '${plan.totalTopics}', Icons.format_list_bulleted),
              _buildMetricStat('Completed', '${plan.completedTopics}', Icons.check_circle),
              _buildMetricStat('Partially', '${plan.partiallyUnderstoodTopics}', Icons.pie_chart_outline),
              _buildMetricStat('Need Help', '${plan.needHelpTopics}', Icons.help_outline),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStat(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildModuleSection(
    LearningModule module,
    LearningPlan plan,
    bool isMentor,
    bool isLearner,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Module ${module.order}: ${module.title}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        if (module.topics.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 12.0, bottom: 12.0),
            child: Text('No topics added to this module.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...module.topics.map((topic) => TopicProgressTile(
                topic: topic,
                moduleId: module.moduleId,
                exchangeId: plan.exchangeId,
                isMentor: isMentor,
                isLearner: isLearner,
                planService: _planService,
              )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNoPlanState(BuildContext context, bool isMentor, bool isLearner) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Learning Plan Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a structured learning plan to outline modules, topics, and expected outcomes for this exchange.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (isMentor || isLearner)
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateLearningPlanScreen(
                        exchangeId: widget.exchangeId,
                        mentorId: widget.mentorId,
                        learnerId: widget.learnerId,
                        skillName: widget.skillName,
                      ),
                    ),
                  );
                  if (result == true) {
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Learning Plan'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyModulesMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: const Text(
        'This plan currently has no modules or topics.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.textSecondaryColor),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
