import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/learning_plan_model.dart';
import '../../services/learning_plan_service.dart';

class CreateLearningPlanScreen extends StatefulWidget {
  final String exchangeId;
  final String mentorId;
  final String learnerId;
  final String skillName;
  final LearningPlan? initialPlan;

  const CreateLearningPlanScreen({
    super.key,
    required this.exchangeId,
    required this.mentorId,
    required this.learnerId,
    required this.skillName,
    this.initialPlan,
  });

  @override
  State<CreateLearningPlanScreen> createState() => _CreateLearningPlanScreenState();
}

class _CreateLearningPlanScreenState extends State<CreateLearningPlanScreen> {
  final LearningPlanService _planService = LearningPlanService();
  late List<LearningModule> _modules;
  late TextEditingController _skillNameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _skillNameController = TextEditingController(text: widget.skillName);
    _modules = widget.initialPlan != null
        ? List<LearningModule>.from(widget.initialPlan!.modules)
        : [];
  }

  @override
  void dispose() {
    _skillNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialPlan == null ? 'Create Learning Plan' : 'Edit Learning Plan'),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Learning Plan Builder',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _skillNameController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Define modules and topics with clear expected outcomes to ensure learning accountability.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Modules Header & Add Module Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Modules (${_modules.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addModule,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Module'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_modules.isEmpty) _buildEmptyModulesState() else ..._buildModulesList(),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _savePlan(activate: false),
                          child: const Text('Save Draft'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _savePlan(activate: true),
                          child: const Text('Save & Activate'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyModulesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.playlist_add, size: 48, color: AppTheme.textSecondaryColor),
          const SizedBox(height: 12),
          Text(
            'No modules added yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Add Module" to start structuring topics for this skill exchange.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModulesList() {
    return _modules.asMap().entries.map((entry) {
      final moduleIndex = entry.key;
      final module = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Module Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Module ${moduleIndex + 1}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      module.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _editModuleTitle(moduleIndex),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                    onPressed: () => setState(() => _modules.removeAt(moduleIndex)),
                  ),
                ],
              ),

              const Divider(),

              // Topics in Module
              if (module.topics.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No topics in this module.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                )
              else
                ...module.topics.asMap().entries.map((topicEntry) {
                  final topicIndex = topicEntry.key;
                  final topic = topicEntry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.drag_indicator, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (topic.expectedOutcome != null && topic.expectedOutcome!.isNotEmpty)
                                Text(
                                  'Outcome: ${topic.expectedOutcome}',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editTopic(moduleIndex, topicIndex),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorColor, size: 18),
                          onPressed: () {
                            setState(() {
                              final updatedTopics = List<LearningTopic>.from(module.topics)..removeAt(topicIndex);
                              _modules[moduleIndex] = module.copyWith(topics: updatedTopics);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 8),

              // Add Topic Button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _addTopic(moduleIndex),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Topic'),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _addModule() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Module'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Module Title',
            hintText: 'e.g. Python Fundamentals',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _modules.add(LearningModule(
                    moduleId: 'mod_${DateTime.now().millisecondsSinceEpoch}_${_modules.length}',
                    title: controller.text.trim(),
                    order: _modules.length + 1,
                    topics: [],
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editModuleTitle(int moduleIndex) {
    final controller = TextEditingController(text: _modules[moduleIndex].title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Module Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Module Title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _modules[moduleIndex] = _modules[moduleIndex].copyWith(title: controller.text.trim());
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addTopic(int moduleIndex) {
    final titleController = TextEditingController();
    final outcomeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Topic Title',
                hintText: 'e.g. Variables & Data Types',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: outcomeController,
              decoration: const InputDecoration(
                labelText: 'Expected Outcome',
                hintText: 'e.g. Understand basic Python data types',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final newTopic = LearningTopic(
                  topicId: 'top_${DateTime.now().millisecondsSinceEpoch}_${_modules[moduleIndex].topics.length}',
                  title: titleController.text.trim(),
                  expectedOutcome: outcomeController.text.trim().isNotEmpty ? outcomeController.text.trim() : null,
                );

                setState(() {
                  final updatedTopics = List<LearningTopic>.from(_modules[moduleIndex].topics)..add(newTopic);
                  _modules[moduleIndex] = _modules[moduleIndex].copyWith(topics: updatedTopics);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  void _editTopic(int moduleIndex, int topicIndex) {
    final topic = _modules[moduleIndex].topics[topicIndex];
    final titleController = TextEditingController(text: topic.title);
    final outcomeController = TextEditingController(text: topic.expectedOutcome ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Topic Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: outcomeController,
              decoration: const InputDecoration(labelText: 'Expected Outcome'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final updatedTopic = topic.copyWith(
                  title: titleController.text.trim(),
                  expectedOutcome: outcomeController.text.trim().isNotEmpty ? outcomeController.text.trim() : null,
                );

                setState(() {
                  final updatedTopics = List<LearningTopic>.from(_modules[moduleIndex].topics);
                  updatedTopics[topicIndex] = updatedTopic;
                  _modules[moduleIndex] = _modules[moduleIndex].copyWith(topics: updatedTopics);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save Topic'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePlan({required bool activate}) async {
    if (_modules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one module and topic to save the plan.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.initialPlan == null) {
        await _planService.createLearningPlan(
          exchangeId: widget.exchangeId,
          mentorId: widget.mentorId,
          learnerId: widget.learnerId,
          skillName: _skillNameController.text.trim(),
          modules: _modules,
        );
      } else {
        final updatedPlan = widget.initialPlan!.copyWith(
          skillName: _skillNameController.text.trim(),
          modules: _modules,
          status: activate ? LearningPlanStatus.active : widget.initialPlan!.status,
        );
        await _planService.updateLearningPlan(updatedPlan);
      }

      if (activate && widget.initialPlan == null) {
        await _planService.activateLearningPlan(widget.exchangeId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(activate ? 'Learning Plan activated!' : 'Learning Plan saved as draft.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plan: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
