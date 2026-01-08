import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/learning_request_service.dart';

class PostLearningRequestScreen extends StatefulWidget {
  const PostLearningRequestScreen({super.key});

  @override
  State<PostLearningRequestScreen> createState() =>
      _PostLearningRequestScreenState();
}

class _PostLearningRequestScreenState extends State<PostLearningRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _learningRequestService = LearningRequestService();
  final _messageController = TextEditingController();

  String? _selectedSkillToLearn;
  String? _selectedSkillToOffer;
  final List<String> _selectedTimeSlots = [];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _sessionDuration = 60; // Default 60 minutes
  bool _isPosting = false;

  final List<String> _timeSlotOptions = [
    'Morning (6 AM - 12 PM)',
    'Afternoon (12 PM - 5 PM)',
    'Evening (5 PM - 9 PM)',
    'Night (9 PM - 12 AM)',
    'Flexible',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _postRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkillToLearn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a skill you want to learn')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      await _learningRequestService.createLearningRequest(
        skillRequested: _selectedSkillToLearn!,
        skillOffered: _selectedSkillToOffer == 'none' ? null : _selectedSkillToOffer,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        preferredTimeSlots: _selectedTimeSlots.isEmpty ? null : _selectedTimeSlots,
        preferredDate: _selectedDate,
        preferredTime: _selectedTime?.format(context),
        sessionDuration: _sessionDuration,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Learning request posted! Tutors can now accept it.'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post request: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Learning Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.public, color: Colors.white, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Post a Public Learning Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Any tutor can accept (First come, first served)',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Free Exchange Info
              if (currentUser != null && currentUser.completedExchanges < 3)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration,
                          color: AppTheme.successColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have ${3 - currentUser.completedExchanges} free ${3 - currentUser.completedExchanges == 1 ? "exchange" : "exchanges"} available! No need to offer a skill.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Skill to Learn
              Text(
                'What do you want to learn?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSkillToLearn,
                decoration: InputDecoration(
                  hintText: 'Select skill',
                  prefixIcon: const Icon(Icons.school),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: AppConfig.popularSkills
                    .map((skill) => DropdownMenuItem(
                          value: skill,
                          child: Text(skill),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSkillToLearn = value;
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Skill to Offer (Optional for first 3)
              Text(
                currentUser != null && currentUser.completedExchanges < 3
                    ? 'What will you teach in return? (Optional)'
                    : 'What will you teach in return? (Required)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSkillToOffer,
                decoration: InputDecoration(
                  hintText: currentUser != null && currentUser.completedExchanges < 3
                      ? 'Optional - or use free exchange'
                      : 'Select skill',
                  prefixIcon: const Icon(Icons.swap_horiz),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  if (currentUser != null && currentUser.completedExchanges < 3)
                    const DropdownMenuItem(
                      value: 'none',
                      child: Row(
                        children: [
                          Icon(Icons.card_giftcard,
                              size: 20, color: AppTheme.successColor),
                          SizedBox(width: 8),
                          Text('No skill (Free Exchange)',
                              style: TextStyle(color: AppTheme.successColor)),
                        ],
                      ),
                    ),
                  ...(currentUser?.skillsToTeach ?? AppConfig.popularSkills)
                      .map((skill) => DropdownMenuItem(
                            value: skill,
                            child: Text(skill),
                          )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSkillToOffer = value;
                  });
                },
                validator: (value) {
                  if (currentUser != null && currentUser.completedExchanges >= 3) {
                    return value == null ? 'Required' : null;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Preferred Time Slots
              Text(
                'Preferred Time Slots (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlotOptions.map((slot) {
                  final isSelected = _selectedTimeSlots.contains(slot);
                  return FilterChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTimeSlots.add(slot);
                        } else {
                          _selectedTimeSlots.remove(slot);
                        }
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // OR Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR Specify Exact Schedule',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Preferred Date & Time
              Text(
                'Preferred Date & Time',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDate != null
                                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                        : 'Select date',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Time',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedTime?.format(context) ?? 'Select time',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Session Duration
              Text(
                'Session Duration: $_sessionDuration minutes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Slider(
                value: _sessionDuration.toDouble(),
                min: 30,
                max: 180,
                divisions: 10,
                label: '$_sessionDuration min',
                onChanged: (value) {
                  setState(() {
                    _sessionDuration = value.toInt();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('30 min', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text('180 min', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                'Message (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Describe what you want to learn, your goals, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Post Button
              ElevatedButton(
                onPressed: _isPosting ? null : _postRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Post Learning Request',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
