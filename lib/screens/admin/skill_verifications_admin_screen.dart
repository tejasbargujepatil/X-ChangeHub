import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/enhancement_models.dart';
import '../../services/enhancement_services.dart';

class SkillVerificationsAdminScreen extends StatefulWidget {
  final VerificationService? verificationService;

  const SkillVerificationsAdminScreen({
    super.key,
    this.verificationService,
  });

  @override
  State<SkillVerificationsAdminScreen> createState() => _SkillVerificationsAdminScreenState();
}

class _SkillVerificationsAdminScreenState extends State<SkillVerificationsAdminScreen>
    with SingleTickerProviderStateMixin {
  late final VerificationService _verificationService;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _verificationService = widget.verificationService ?? VerificationService();
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
      future: _verificationService.isReviewer(),
      builder: (context, authSnapshot) {
        final isAuthorizedReviewer = authSnapshot.data ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Skill Verification Portal'),
            bottom: isAuthorizedReviewer
                ? TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: AppTheme.textSecondaryColor,
                    indicatorColor: AppTheme.primaryColor,
                    tabs: const [
                      Tab(text: 'Pending'),
                      Tab(text: 'Verified'),
                      Tab(text: 'Rejected'),
                      Tab(text: 'Revoked'),
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
                              'All verification approvals and revocations are protected server-side by Firestore Security Rules.',
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
                        _buildVerificationsList(VerificationStatus.pending),
                        _buildVerificationsList(VerificationStatus.verified),
                        _buildVerificationsList(VerificationStatus.rejected),
                        _buildVerificationsList(VerificationStatus.revoked),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildVerificationsList(VerificationStatus status) {
    return StreamBuilder<List<SkillVerificationModel>>(
      stream: _verificationService.watchPendingVerifications(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading verification requests: ${snapshot.error}',
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined, size: 48, color: AppTheme.textSecondaryColor),
                const SizedBox(height: 12),
                Text(
                  'No ${status.name} verification requests found',
                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildVerificationCard(request);
          },
        );
      },
    );
  }

  Widget _buildVerificationCard(SkillVerificationModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.skill,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'User ID: ${request.userId}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
            ),
            Text(
              'Type: ${request.type.name.toUpperCase()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (request.certificateUrl != null && request.certificateUrl!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Proof URL: ${request.certificateUrl}',
                style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor),
              ),
            ],
            if (request.learningPlanId != null && request.learningPlanId!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Learning Plan ID: ${request.learningPlanId}',
                style: const TextStyle(fontSize: 12, color: AppTheme.secondaryColor),
              ),
            ],
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reviewer Notes: ${request.notes}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 12),
            if (request.status == VerificationStatus.pending) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showDecisionDialog(request, approve: false),
                    icon: const Icon(Icons.close, size: 16, color: AppTheme.errorColor),
                    label: const Text('Reject', style: TextStyle(color: AppTheme.errorColor)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showDecisionDialog(request, approve: true),
                    icon: const Icon(Icons.check, size: 16),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ] else if (request.status == VerificationStatus.verified) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showRevokeDialog(request),
                    icon: const Icon(Icons.block, size: 16, color: AppTheme.errorColor),
                    label: const Text('Revoke Verification', style: TextStyle(color: AppTheme.errorColor)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(VerificationStatus status) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case VerificationStatus.pending:
        bg = AppTheme.warningColor.withValues(alpha: 0.15);
        fg = AppTheme.warningColor;
        icon = Icons.hourglass_empty;
        break;
      case VerificationStatus.verified:
        bg = AppTheme.successColor.withValues(alpha: 0.15);
        fg = AppTheme.successColor;
        icon = Icons.verified;
        break;
      case VerificationStatus.rejected:
        bg = AppTheme.errorColor.withValues(alpha: 0.15);
        fg = AppTheme.errorColor;
        icon = Icons.cancel;
        break;
      case VerificationStatus.revoked:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        icon = Icons.block;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
        icon = Icons.info;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 14, color: fg),
      label: Text(status.name.toUpperCase(), style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold)),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
    );
  }

  void _showDecisionDialog(SkillVerificationModel request, {required bool approve}) {
    final notesController = TextEditingController();
    final testScoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve Skill Verification' : 'Reject Skill Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skill: ${request.skill}'),
            const SizedBox(height: 12),
            if (approve) ...[
              TextField(
                controller: testScoreController,
                decoration: const InputDecoration(
                  labelText: 'Assessment Score / Grade (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: approve ? 'Approval Notes (Optional)' : 'Rejection Reason (Required)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppTheme.successColor : AppTheme.errorColor,
            ),
            onPressed: () async {
              final notes = notesController.text.trim();
              if (!approve && notes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a rejection reason.')),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await _verificationService.verifySkill(
                  verificationId: request.id,
                  approve: approve,
                  notes: notes.isNotEmpty ? notes : null,
                  testScore: testScoreController.text.trim().isNotEmpty
                      ? testScoreController.text.trim()
                      : null,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(approve
                        ? '${request.skill} verified successfully!'
                        : '${request.skill} verification rejected.'),
                    backgroundColor: approve ? AppTheme.successColor : AppTheme.warningColor,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Operation failed: $e'), backgroundColor: AppTheme.errorColor),
                );
              }
            },
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _showRevokeDialog(SkillVerificationModel request) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Skill Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skill: ${request.skill}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Revocation Reason (Required)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a revocation reason.')),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await _verificationService.revokeVerification(
                  verificationId: request.id,
                  reason: reason,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${request.skill} verification revoked.'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Revocation failed: $e'), backgroundColor: AppTheme.errorColor),
                );
              }
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}
