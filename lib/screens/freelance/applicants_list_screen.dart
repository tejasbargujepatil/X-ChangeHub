import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/freelance_service.dart';
import '../../services/user_service.dart';
import '../../config/theme.dart';
import '../../models/freelance_project_model.dart';
import '../../models/user_model.dart';

class ApplicantsListScreen extends StatefulWidget {
  final FreelanceProjectModel project;

  const ApplicantsListScreen({
    super.key,
    required this.project,
  });

  @override
  State<ApplicantsListScreen> createState() => _ApplicantsListScreenState();
}

class _ApplicantsListScreenState extends State<ApplicantsListScreen> {
  final UserService _userService = UserService();
  final FreelanceService _freelanceService = FreelanceService();
  
  List<UserModel>? _applicants;
  bool _isLoading = true;
  String _sortBy = 'rating'; // rating, level, alphabetical

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final applicants = <UserModel>[];
      
      for (final userId in widget.project.applicantIds) {
        final user = await _userService.getUserById(userId);
        if (user != null) {
          applicants.add(user);
        }
      }

      // Sort applicants
      _sortApplicants(applicants);

      setState(() {
        _applicants = applicants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortApplicants(List<UserModel> applicants) {
    switch (_sortBy) {
      case 'rating':
        applicants.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'level':
        applicants.sort((a, b) => b.level.compareTo(a.level));
        break;
      case 'alphabetical':
        applicants.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
    }
  }

  Future<void> _assignProject(UserModel freelancer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Project'),
        content: Text(
          'Are you sure you want to assign this project to ${freelancer.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _freelanceService.assignProject(
        projectId: widget.project.id,
        freelancerId: freelancer.uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project assigned to ${freelancer.fullName}!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate assignment
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign project: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.project.applicantIds.length} Applicants'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                if (_applicants != null) {
                  _sortApplicants(_applicants!);
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rating',
                child: Text('Sort by Rating'),
              ),
              const PopupMenuItem(
                value: 'level',
                child: Text('Sort by Level'),
              ),
              const PopupMenuItem(
                value: 'alphabetical',
                child: Text('Sort Alphabetically'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applicants == null || _applicants!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No applicants yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applicants!.length,
                  itemBuilder: (context, index) {
                    final applicant = _applicants![index];
                    return _buildApplicantCard(applicant, index);
                  },
                ),
    );
  }

  Widget _buildApplicantCard(UserModel applicant, int index) {
    // Calculate match score based on required skills
    final matchingSkills = widget.project.requiredSkills
        .where((skill) => applicant.skillsToTeach.contains(skill))
        .toList();
    final matchPercentage = (matchingSkills.length / widget.project.requiredSkills.length * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showApplicantDetails(applicant),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: index == 0 ? AppTheme.primaryGradient : null,
                      color: index == 0 ? null : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: index == 0 ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: applicant.profileImageUrl != null
                        ? NetworkImage(applicant.profileImageUrl!)
                        : null,
                    child: applicant.profileImageUrl == null
                        ? Text(
                            applicant.fullName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Name and stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicant.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '⭐ ${applicant.averageRating.toStringAsFixed(1)} • ${applicant.completedProjects} completed',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.trending_up, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Level ${applicant.level} • ${applicant.xpPoints} XP',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Match score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMatchColor(matchPercentage),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$matchPercentage% Match',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Skills
              if (matchingSkills.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: matchingSkills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      avatar: const Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
                      backgroundColor: AppTheme.successColor.withOpacity(0.1),
                      labelStyle: const TextStyle(fontSize: 11),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Bio preview
              if (applicant.bio != null && applicant.bio!.isNotEmpty) ...[
                Text(
                  applicant.bio!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showApplicantDetails(applicant),
                      icon: const Icon(Icons.person, size: 18),
                      label: const Text('View Profile'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _assignProject(applicant),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Assign'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplicantDetails(UserModel applicant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: applicant.profileImageUrl != null
                          ? NetworkImage(applicant.profileImageUrl!)
                          : null,
                      child: applicant.profileImageUrl == null
                          ? Text(
                              applicant.fullName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 40),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      applicant.fullName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${applicant.averageRating.toStringAsFixed(1)} • ',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Level ${applicant.level}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bio
              if (applicant.bio != null && applicant.bio!.isNotEmpty) ...[
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(applicant.bio!),
                const SizedBox(height: 20),
              ],

              // Skills
              Text(
                'Skills',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: applicant.skillsToTeach.map((skill) {
                  final isRequired = widget.project.requiredSkills.contains(skill);
                  return Chip(
                    label: Text(skill),
                    avatar: isRequired
                        ? const Icon(Icons.check_circle, size: 16, color: AppTheme.successColor)
                        : null,
                    backgroundColor: isRequired
                        ? AppTheme.successColor.withOpacity(0.2)
                        : AppTheme.primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Stats
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Projects',
                      '${applicant.completedProjects}',
                      Icons.work,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Exchanges',
                      '${applicant.completedExchanges}',
                      Icons.swap_horiz,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'XP Points',
                      '${applicant.xpPoints}',
                      Icons.stars,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Badges',
                      '${applicant.badges.length}',
                      Icons.emoji_events,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Assign button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _assignProject(applicant);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Assign Project to This Freelancer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}
