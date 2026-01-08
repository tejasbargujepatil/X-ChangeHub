import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/batch_model.dart';
import '../../services/batch_service.dart';
import 'batch_details_screen.dart';
import 'create_batch_screen.dart';

class BrowseBatchesScreen extends StatefulWidget {
  const BrowseBatchesScreen({super.key});

  @override
  State<BrowseBatchesScreen> createState() => _BrowseBatchesScreenState();
}

class _BrowseBatchesScreenState extends State<BrowseBatchesScreen> {
  final BatchService _batchService = BatchService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Learning Batches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateBatchScreen(),
                ),
              );
            },
            tooltip: 'Create Batch',
          ),
        ],
      ),
      body: StreamBuilder<List<BatchModel>>(
        stream: _batchService.getActiveBatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active batches',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Be the first to create a group batch!',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateBatchScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Batch'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final batch = snapshot.data![index];
              return _buildBatchCard(batch);
            },
          );
        },
      ),
    );
  }

  Widget _buildBatchCard(BatchModel batch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BatchDetailsScreen(batchId: batch.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tutor info
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: batch.tutorImageUrl != null
                        ? NetworkImage(batch.tutorImageUrl!)
                        : null,
                    child: batch.tutorImageUrl == null
                        ? Text(batch.tutorName[0])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.tutorName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          batch.skillToTeach,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(batch.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(batch.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusText(batch.status),
                      style: TextStyle(
                        color: _getStatusColor(batch.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                batch.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                batch.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Info Row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${DateFormat('MMM dd').format(batch.startDate)} - ${DateFormat('MMM dd').format(batch.endDate)}',
                  ),
                  _buildInfoChip(
                    Icons.access_time,
                    batch.timeSlot,
                  ),
                  _buildInfoChip(
                    Icons.repeat,
                    _getScheduleText(batch.scheduleType),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Enrollment Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${batch.currentEnrollments}/${batch.maxStudents} enrolled',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${batch.availableSeats} seats left',
                        style: TextStyle(
                          color: batch.availableSeats < 5
                              ? AppTheme.errorColor
                              : AppTheme.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: batch.currentEnrollments / batch.maxStudents,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      batch.isFull
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.open:
        return AppTheme.successColor;
      case BatchStatus.ongoing:
        return AppTheme.primaryColor;
      case BatchStatus.closed:
        return AppTheme.errorColor;
      case BatchStatus.completed:
        return Colors.grey;
    }
  }

  String _getStatusText(BatchStatus status) {
    switch (status) {
      case BatchStatus.open:
        return 'Open';
      case BatchStatus.ongoing:
        return 'Ongoing';
      case BatchStatus.closed:
        return 'Closed';
      case BatchStatus.completed:
        return 'Completed';
    }
  }

  String _getScheduleText(ScheduleType type) {
    switch (type) {
      case ScheduleType.daily:
        return 'Daily';
      case ScheduleType.weekdays:
        return 'Mon-Fri';
      case ScheduleType.weekends:
        return 'Sat-Sun';
      case ScheduleType.custom:
        return 'Custom';
    }
  }
}
