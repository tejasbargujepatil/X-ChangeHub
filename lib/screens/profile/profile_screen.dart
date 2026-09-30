import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../models/mentor_metrics_model.dart';
import '../../services/mentor_quality_service.dart';
import '../../services/enhancement_services.dart';
import '../portfolio/portfolio_view_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'request_verification_dialog.dart';
import '../../widgets/verified_certificate_dialog.dart';
import '../admin/skill_verifications_admin_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context, authProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: user.profileImageUrl != null
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Text(
                            user.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '@${user.username}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      user.bio!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            // Stats Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn(
                    context,
                    'Level',
                    '${user.level}',
                    Icons.trending_up,
                  ),
                  _buildStatColumn(
                    context,
                    'XP Points',
                    '${user.xpPoints}',
                    Icons.stars,
                  ),
                  _buildStatColumn(
                    context,
                    'Rating',
                    user.averageRating.toStringAsFixed(1),
                    Icons.star,
                  ),
                ],
              ),
            ),

            const Divider(),

            // Skills Section
            _buildSection(
              context,
              'Skills I Can Teach',
              user.skillsToTeach,
              AppTheme.primaryColor,
              verifiedSkills: user.verifiedSkills,
              userId: user.uid,
              userName: user.fullName,
            ),

            _buildSection(
              context,
              'Skills I Want to Learn',
              user.skillsToLearn,
              AppTheme.secondaryColor,
              userId: user.uid,
              userName: user.fullName,
            ),

            // Achievements Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAchievement(
                        context,
                        'Exchanges',
                        '${user.completedExchanges}',
                        Icons.swap_horiz,
                      ),
                      _buildAchievement(
                        context,
                        'Projects',
                        '${user.completedProjects}',
                        Icons.work,
                      ),
                      _buildAchievement(
                        context,
                        'Badges',
                        '${user.badges.length}',
                        Icons.military_tech,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Mentor Quality & Reputation Section
            _buildMentorQualitySection(context, user.uid),

            // Portfolio Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PortfolioViewScreen(user: user),
                    ),
                  );
                },
                icon: const Icon(Icons.folder_special),
                label: const Text('View My Portfolio'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            // Request Skill Verification Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => RequestVerificationDialog(
                      userId: user.uid,
                      availableSkills: user.skillsToTeach,
                      verifiedSkills: user.verifiedSkills,
                    ),
                  );
                },
                icon: const Icon(Icons.verified),
                label: const Text('Request Skill Verification'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            // Reviewer Verification Portal Button (only visible if reviewer/admin)
            FutureBuilder<bool>(
              future: VerificationService().isReviewer(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SkillVerificationsAdminScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.gavel),
                      label: const Text('Reviewer Verification Portal'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Privacy Policy Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.privacy_tip),
                label: const Text('Privacy Policy'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 30),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> items,
    Color color, {
    List<String> verifiedSkills = const [],
    String? userId,
    String? userName,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              'No skills added yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((skill) {
                final isVerified = verifiedSkills.contains(skill);
                final chipWidget = Chip(
                  avatar: isVerified
                      ? const Icon(Icons.verified, size: 16, color: AppTheme.successColor)
                      : null,
                  label: Text(
                    isVerified ? '$skill (XchangeHub Verified)' : skill,
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: isVerified ? FontWeight.bold : FontWeight.w500,
                  ),
                );

                if (isVerified && userId != null && userName != null) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => VerifiedCertificateDialog(
                          userId: userId,
                          userName: userName,
                          skill: skill,
                        ),
                      );
                    },
                    child: chipWidget,
                  );
                }

                return chipWidget;
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievement(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.successGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorQualitySection(BuildContext context, String userId) {
    final qualityService = MentorQualityService();

    return StreamBuilder<MentorMetricsModel?>(
      stream: qualityService.watchMentorMetrics(userId),
      builder: (context, snapshot) {
        final metrics = snapshot.data;
        if (metrics == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified_user, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Mentor Quality & Reputation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    if (metrics.sufficientHistory && metrics.qualityScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.successColor),
                        ),
                        child: Text(
                          '${metrics.qualityScore} / 100',
                          style: const TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'New Mentor',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQualityMetricTile(
                      context,
                      'Delivery Rate',
                      '${metrics.topicDeliveryRate.toStringAsFixed(0)}%',
                      Icons.task_alt,
                    ),
                    _buildQualityMetricTile(
                      context,
                      'Plans Finished',
                      '${metrics.learningPlansCompleted}',
                      Icons.assignment_turned_in,
                    ),
                    _buildQualityMetricTile(
                      context,
                      'Confirmed Topics',
                      '${metrics.topicsLearnerConfirmed}',
                      Icons.thumb_up,
                    ),
                  ],
                ),
                if (metrics.validatedLearningIssues > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Validated Accountability Record: ${metrics.validatedLearningIssues} issue(s) resolved',
                    style: const TextStyle(fontSize: 11, color: AppTheme.warningColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQualityMetricTile(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
        ),
      ],
    );
  }
}
