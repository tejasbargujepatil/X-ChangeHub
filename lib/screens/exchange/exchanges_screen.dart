import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/skill_exchange_model.dart';
import '../../services/skill_exchange_service.dart';
import '../../widgets/exchange_dialogs.dart';

class ExchangesScreen extends StatefulWidget {
  const ExchangesScreen({super.key});

  @override
  State<ExchangesScreen> createState() => _ExchangesScreenState();
}

class _ExchangesScreenState extends State<ExchangesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SkillExchangeService _exchangeService = SkillExchangeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exchanges'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildActiveTab(),
          _buildCompletedTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    return StreamBuilder<List<SkillExchangeModel>>(
      stream: _exchangeService.getPendingRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No pending requests', Icons.inbox);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final exchange = snapshot.data![index];
            return _buildExchangeCard(exchange);
          },
        );
      },
    );
  }

  Widget _buildActiveTab() {
    return StreamBuilder<List<SkillExchangeModel>>(
      stream: _exchangeService.getActiveExchanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No active exchanges', Icons.swap_horiz);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final exchange = snapshot.data![index];
            return _buildExchangeCard(exchange, isActive: true);
          },
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    return StreamBuilder<List<SkillExchangeModel>>(
      stream: _exchangeService.getCompletedExchanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No completed exchanges yet', Icons.check_circle_outline);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final exchange = snapshot.data![index];
            return _buildExchangeCard(exchange, isCompleted: true);
          },
        );
      },
    );
  }

  Future<void> _acceptExchange(SkillExchangeModel exchange) async {
    // Show schedule dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ScheduleExchangeDialog(exchange: exchange),
    );

    if (result == null) return;

    // Accept and schedule exchange
    try {
      await _exchangeService.acceptExchangeRequest(
        exchangeId: exchange.id,
        scheduledTime: result['scheduledTime'],
        duration: result['duration'],
        meetingLink: result['meetingLink'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exchange scheduled with ${exchange.requesterName}!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule exchange: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildExchangeCard(
    SkillExchangeModel exchange, {
    bool isActive = false,
    bool isCompleted = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: exchange.requesterImageUrl != null
                      ? NetworkImage(exchange.requesterImageUrl!)
                      : null,
                  child: exchange.requesterImageUrl == null
                      ? Text(exchange.requesterName[0])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exchange.requesterName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Wants to learn: ${exchange.skillRequested}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (isActive || isCompleted)
                        Text(
                          'Teaching: ${exchange.skillOffered}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                        ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 32,
                  ),
              ],
            ),
            if (exchange.message != null) ...[
              const SizedBox(height: 12),
              Text(
                exchange.message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Show scheduled time for active exchanges
            if (isActive && exchange.scheduledTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Scheduled: ${exchange.scheduledTime!.toString().substring(0, 16)}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action buttons based on state
            if (!isActive && !isCompleted)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _exchangeService.rejectExchangeRequest(exchange.id);
                      },
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _acceptExchange(exchange);
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            if (isActive)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // Open Google Meet link
                        try {
                          final meetingLink = exchange.meetingLink;
                          
                          if (meetingLink == null || meetingLink.isEmpty) {
                            throw Exception('No meeting link available');
                          }
                          
                          // Ensure the link is a valid URL
                          String url = meetingLink;
                          if (!url.startsWith('http')) {
                            // If it's just a room name, construct Google Meet URL
                            url = 'https://meet.google.com/$meetingLink';
                          }
                          
                          debugPrint('🎥 Opening Google Meet: $url');
                          
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            throw Exception('Could not launch meeting link');
                          }
                        } catch (e) {
                          debugPrint('❌ Meeting error: $e');
                          if (!mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error opening meeting: $e'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.video_call),
                      label: const Text('Join Google Meet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Simple completion using the service
                        try {
                          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                          await _exchangeService.completeExchange(
                            exchangeId: exchange.id,
                            isRequester: exchange.requesterId == currentUserId,
                            rating: 5.0, // Default rating for now
                            review: 'Exchange completed successfully',
                          );
                          
                          if (!mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exchange marked as completed!'),
                              backgroundColor: AppTheme.successColor,
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
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Complete'),
                    ),
                  ),
                ],
              ),
            if (isCompleted)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Exchange Completed',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
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

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppTheme.textSecondaryColor),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
