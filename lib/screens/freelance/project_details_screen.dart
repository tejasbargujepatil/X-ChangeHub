import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/freelance_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/freelance_project_model.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import 'applicants_list_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final FreelanceProjectModel project;

  const ProjectDetailsScreen({
    super.key,
    required this.project,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final FreelanceService _freelanceService = FreelanceService();
  final UserService _userService = UserService();
  
  late FreelanceProjectModel _project;
  UserModel? _client;
  UserModel? _assignedFreelancer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    try {
      // Load client info
      _client = await _userService.getUserById(_project.clientId);
      
      // Load assigned freelancer if any
      if (_project.assignedToId != null) {
        _assignedFreelancer = await _userService.getUserById(_project.assignedToId!);
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _applyToProject() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    // Check if user has required skills
    final hasRequiredSkills = _project.requiredSkills.any(
      (skill) => currentUser.skillsToTeach.contains(skill),
    );

    if (!hasRequiredSkills) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least one of the required skills to apply'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _freelanceService.applyToProject(_project.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Refresh project data
      setState(() {
        _project = _project.copyWith(
          applicantIds: [..._project.applicantIds, currentUser.uid],
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitDeliverable() async {
    // TODO: Show dialog to upload deliverable
    final urlController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Deliverable'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Deliverable URL',
            hintText: 'https://github.com/...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, urlController.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _freelanceService.submitDeliverable(
        projectId: _project.id,
        deliverableUrl: result.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deliverable submitted! Waiting for client approval.'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      // Refresh
      _loadProjectData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    
    final isMyProject = currentUser?.uid == _project.clientId;
    final isAssignedToMe = currentUser?.uid == _project.assignedToId;
    final hasApplied = currentUser != null && _project.applicantIds.contains(currentUser.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          if (isMyProject)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to edit project screen
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_project.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _project.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(_project.difficulty),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _project.difficulty.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _project.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.white, size: 32),
                      Text(
                        '\$${_project.budget.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posted ${_formatDate(_project.createdAt)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Info
                  if (_client != null) ...[
                    Text(
                      'Client',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: _client!.profileImageUrl != null
                              ? NetworkImage(_client!.profileImageUrl!)
                              : null,
                          child: _client!.profileImageUrl == null
                              ? Text(_client!.fullName[0])
                              : null,
                        ),
                        title: Text(_client!.fullName),
                        subtitle: Text('⭐ ${_client!.averageRating.toStringAsFixed(1)} • Level ${_client!.level}'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _project.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),

                  // Required Skills
                  Text(
                    'Required Skills',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _project.requiredSkills.map((skill) {
                      final hasSkill = currentUser?.skillsToTeach.contains(skill) ?? false;
                      return Chip(
                        label: Text(skill),
                        backgroundColor: hasSkill
                            ? AppTheme.successColor.withOpacity(0.2)
                            : AppTheme.primaryColor.withOpacity(0.1),
                        avatar: hasSkill
                            ? const Icon(Icons.check_circle, size: 20, color: AppTheme.successColor)
                            : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Project Details
                  _buildDetailRow('Estimated Duration', '${_project.estimatedDuration} days'),
                  _buildDetailRow('Applicants', '${_project.applicantIds.length} applied'),
                  if (_project.deadline != null)
                    _buildDetailRow('Deadline', _formatDate(_project.deadline!)),
                  const SizedBox(height: 20),

                  // Assigned Freelancer
                  if (_assignedFreelancer != null) ...[
                    Text(
                      'Assigned Freelancer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: AppTheme.successColor.withOpacity(0.1),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: _assignedFreelancer!.profileImageUrl != null
                              ? NetworkImage(_assignedFreelancer!.profileImageUrl!)
                              : null,
                          child: _assignedFreelancer!.profileImageUrl == null
                              ? Text(_assignedFreelancer!.fullName[0])
                              : null,
                        ),
                        title: Text(_assignedFreelancer!.fullName),
                        subtitle: Text('⭐ ${_assignedFreelancer!.averageRating.toStringAsFixed(1)}'),
                        trailing: const Icon(Icons.work, color: AppTheme.successColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Deliverable Status
                  if (_project.deliverableUrl != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.attachment, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Deliverable Submitted',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _project.deliverableUrl!,
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Budget Breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentRow('Project Budget', '\$${_project.budget.toStringAsFixed(2)}'),
                        _buildPaymentRow(
                          'Platform Fee (${AppConfig.platformCommissionPercentage}%)',
                          '-\$${_project.platformFee.toStringAsFixed(2)}',
                          isDeduction: true,
                        ),
                        const Divider(),
                        _buildPaymentRow(
                          'You Receive',
                          '\$${(_project.budget - _project.platformFee).toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(currentUser, isMyProject, isAssignedToMe, hasApplied),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isDeduction = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDeduction ? Colors.red.shade700 : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDeduction ? Colors.red.shade700 : AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(UserModel? currentUser, bool isMyProject, bool isAssignedToMe, bool hasApplied) {
    if (currentUser == null) return null;

    // Client (project owner) view
    if (isMyProject) {
      if (_project.status == ProjectStatus.open) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplicantsListScreen(project: _project),
                  ),
                );
                
                // Refresh if freelancer was assigned
                if (result == true && mounted) {
                  _loadProjectData();
                }
              },
              icon: const Icon(Icons.people),
              label: Text('View ${_project.applicantIds.length} Applicants'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        );
      }
      return null;
    }

    // Freelancer view
    if (isAssignedToMe) {
      if (_project.deliverableUrl == null) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitDeliverable,
              icon: const Icon(Icons.upload_file),
              label: const Text('Submit Deliverable'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        );
      }
      return null;
    }

    // Other freelancers
    if (_project.status == ProjectStatus.open) {
      if (hasApplied) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle),
              label: const Text('Application Submitted'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _applyToProject,
            icon: const Icon(Icons.send),
            label: const Text('Apply to Project'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      );
    }

    return null;
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.open:
        return Colors.green;
      case ProjectStatus.inProgress:
        return Colors.blue;
      case ProjectStatus.underReview:
        return Colors.orange;
      case ProjectStatus.completed:
        return Colors.purple;
      case ProjectStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getDifficultyColor(ProjectDifficulty difficulty) {
    switch (difficulty) {
      case ProjectDifficulty.beginner:
        return Colors.green;
      case ProjectDifficulty.intermediate:
        return Colors.orange;
      case ProjectDifficulty.advanced:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
