import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/batch_model.dart';
import '../../services/batch_service.dart';

class BatchDetailsScreen extends StatefulWidget {
  final String batchId;

  const BatchDetailsScreen({
    super.key,
    required this.batchId,
  });

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen> {
  final BatchService _batchService = BatchService();
  BatchModel? _batch;
  bool _isLoading = true;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _loadBatch();
  }

  Future<void> _loadBatch() async {
    try {
      final batch = await _batchService.getBatchById(widget.batchId);
      setState(() {
        _batch = batch;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enrollInBatch() async {
    setState(() {
      _isEnrolling = true;
    });

    try {
      await _batchService.enrollInBatch(widget.batchId);
      await _loadBatch(); // Reload to get updated enrollment

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully enrolled in batch!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
      }
    }
  }

  Future<void> _leaveBatch() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Batch?'),
        content: const Text('Are you sure you want to leave this batch?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _batchService.leaveBatch(widget.batchId);
      await _loadBatch();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Left the batch'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Batch Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_batch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Batch Details')),
        body: const Center(child: Text('Batch not found')),
      );
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isEnrolled = _batch!.enrolledStudentIds.contains(currentUserId);
    final isTutor = _batch!.tutorId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tutor Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: _batch!.tutorImageUrl != null
                            ? NetworkImage(_batch!.tutorImageUrl!)
                            : null,
                        child: _batch!.tutorImageUrl == null
                            ? Text(_batch!.tutorName[0],
                                style: const TextStyle(fontSize: 24))
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tutor',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _batch!.tutorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    _batch!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Skill Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _batch!.skillToTeach,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    'About this batch',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _batch!.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Details Cards
                  _buildDetailCard(
                    'Schedule',
                    Icons.calendar_today,
                    [
                      'Start: ${DateFormat('MMM dd, yyyy').format(_batch!.startDate)}',
                      'End: ${DateFormat('MMM dd, yyyy').format(_batch!.endDate)}',
                      'Time: ${_batch!.timeSlot}',
                      'Frequency: ${_getScheduleText(_batch!.scheduleType)}',
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildDetailCard(
                    'Enrollment',
                    Icons.people,
                    [
                      'Enrolled: ${_batch!.currentEnrollments}/${_batch!.maxStudents}',
                      'Available Seats: ${_batch!.availableSeats}',
                      'Status: ${_getStatusText(_batch!.status)}',
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Meeting Link
                  if (isEnrolled || isTutor) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4285F4).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.video_call,
                                  color: Color(0xFF4285F4)),
                              SizedBox(width: 8),
                              Text(
                                'Google Meet Link',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _batch!.meetingLink ?? 'No link provided',
                            style: const TextStyle(
                              color: Color(0xFF4285F4),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (_batch!.meetingLink != null) {
                                final uri = Uri.parse(_batch!.meetingLink!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                            icon: const Icon(Icons.launch),
                            label: const Text('Join Meeting'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Button
                  if (!isTutor)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isEnrolling
                            ? null
                            : (isEnrolled ? _leaveBatch : _enrollInBatch),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: isEnrolled
                              ? AppTheme.errorColor
                              : AppTheme.primaryColor,
                        ),
                        child: _isEnrolling
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEnrolled ? 'Leave Batch' : 'Enroll Now',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, IconData icon, List<String> details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: AppTheme.successColor),
                    const SizedBox(width: 8),
                    Text(detail),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _getScheduleText(ScheduleType type) {
    switch (type) {
      case ScheduleType.daily:
        return 'Daily';
      case ScheduleType.weekdays:
        return 'Monday - Friday';
      case ScheduleType.weekends:
        return 'Saturday - Sunday';
      case ScheduleType.custom:
        return 'Custom Schedule';
    }
  }

  String _getStatusText(BatchStatus status) {
    switch (status) {
      case BatchStatus.open:
        return 'Open for Enrollment';
      case BatchStatus.ongoing:
        return 'Ongoing';
      case BatchStatus.closed:
        return 'Closed';
      case BatchStatus.completed:
        return 'Completed';
    }
  }
}
