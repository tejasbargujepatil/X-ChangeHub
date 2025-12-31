import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/freelance_service.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/freelance_project_model.dart';

class PostProjectScreen extends StatefulWidget {
  const PostProjectScreen({super.key});

  @override
  State<PostProjectScreen> createState() => _PostProjectScreenState();
}

class _PostProjectScreenState extends State<PostProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _durationController = TextEditingController();
  
  ProjectDifficulty _difficulty = ProjectDifficulty.beginner;
  List<String> _selectedSkills = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _postProject() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one required skill'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final freelanceService = FreelanceService();

      await freelanceService.createProject(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        requiredSkills: _selectedSkills,
        budget: double.parse(_budgetController.text.trim()),
        difficulty: _difficulty,
        estimatedDuration: int.parse(_durationController.text.trim()),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project posted successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post project: $e'),
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

  void _showSkillSelector() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _SkillSelectorDialog(
        selectedSkills: _selectedSkills,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSkills = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Project'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Post entry-level projects. ${AppConfig.platformCommissionPercentage}% platform commission.',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Project Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Project Title',
                hintText: 'e.g., Build a simple Flutter app',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.trim().length < 10) {
                  return 'Title must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Project Description',
                hintText: 'Describe what you need in detail...',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                if (value.trim().length < 50) {
                  return 'Description must be at least 50 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Budget
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget (USD)',
                hintText: 'e.g., 100',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$ ',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Budget is required';
                }
                final budget = double.tryParse(value.trim());
                if (budget == null || budget <= 0) {
                  return 'Enter a valid budget';
                }
                if (budget < 10) {
                  return 'Minimum budget is \$10';
                }
                if (budget > 10000) {
                  return 'Maximum budget is \$10,000';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Estimated Duration
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated Duration (days)',
                hintText: 'e.g., 7',
                prefixIcon: Icon(Icons.calendar_today),
                suffixText: 'days',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Duration is required';
                }
                final days = int.tryParse(value.trim());
                if (days == null || days <= 0) {
                  return 'Enter valid number of days';
                }
                if (days > 90) {
                  return 'Maximum duration is 90 days';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Difficulty Level
            Text(
              'Difficulty Level',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ProjectDifficulty.values.map((difficulty) {
                return ChoiceChip(
                  label: Text(difficulty.name.toUpperCase()),
                  selected: _difficulty == difficulty,
                  onSelected: (selected) {
                    setState(() {
                      _difficulty = difficulty;
                    });
                  },
                  selectedColor: _getDifficultyColor(difficulty),
                  labelStyle: TextStyle(
                    color: _difficulty == difficulty ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Required Skills
            Text(
              'Required Skills',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedSkills.isEmpty)
                    TextButton.icon(
                      onPressed: _showSkillSelector,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Required Skills'),
                    )
                  else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSkills.map((skill) {
                        return Chip(
                          label: Text(skill),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedSkills.remove(skill);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showSkillSelector,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Skills'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Budget Breakdown Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Breakdown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_budgetController.text.isNotEmpty)
                    Builder(
                      builder: (context) {
                        final budget = double.tryParse(_budgetController.text) ?? 0;
                        final commission = budget * (AppConfig.platformCommissionPercentage / 100);
                        final freelancerGets = budget - commission;
                        
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Budget:'),
                                Text(
                                  '\$${budget.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Platform Fee (${AppConfig.platformCommissionPercentage}%):'),
                                Text('-\$${commission.toStringAsFixed(2)}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Freelancer Receives:'),
                                Text(
                                  '\$${freelancerGets.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _postProject,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Post Project'),
            ),
          ],
        ),
      ),
    );
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
}

// Skill Selector Dialog
class _SkillSelectorDialog extends StatefulWidget {
  final List<String> selectedSkills;

  const _SkillSelectorDialog({
    required this.selectedSkills,
  });

  @override
  State<_SkillSelectorDialog> createState() => _SkillSelectorDialogState();
}

class _SkillSelectorDialogState extends State<_SkillSelectorDialog> {
  late List<String> _selected;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedSkills);
  }

  List<String> get _filteredSkills {
    if (_searchQuery.isEmpty) {
      return AppConfig.popularSkills;
    }
    return AppConfig.popularSkills
        .where((skill) => skill.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Required Skills',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selected.length} selected',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search skills...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Skills List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredSkills.length,
                itemBuilder: (context, index) {
                  final skill = _filteredSkills[index];
                  final isSelected = _selected.contains(skill);
                  
                  return CheckboxListTile(
                    title: Text(skill),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(skill);
                        } else {
                          _selected.remove(skill);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
