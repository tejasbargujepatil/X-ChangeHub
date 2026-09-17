import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/skill_exchange_service.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_config.dart';
import '../../config/theme.dart';
import '../../widgets/exchange_dialogs.dart';

class FindMatchesScreen extends StatefulWidget {
  const FindMatchesScreen({super.key});

  @override
  State<FindMatchesScreen> createState() => _FindMatchesScreenState();
}

class _FindMatchesScreenState extends State<FindMatchesScreen> {
  final UserService _userService = UserService();
  String? _selectedSkill;
  List<UserModel> _matches = [];
  bool _isLoading = false;

  Future<void> _searchMatches() async {
    if (_selectedSkill == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.searchUsersBySkill(_selectedSkill!);
      setState(() {
        _matches = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _requestExchange(UserModel teacher) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    // For first 3 exchanges, skills to teach is not required
    // After 3 exchanges, user must have skills to teach
    if (currentUser.completedExchanges >= 3 && currentUser.skillsToTeach.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add skills you can teach in your profile. All free exchanges used (${currentUser.completedExchanges}/3)!',
          ),
        ),
      );
      return;
    }

    // Show request dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RequestExchangeDialog(
        teacher: teacher,
        skillRequested: _selectedSkill!,
        mySkills: currentUser.skillsToTeach,
        completedExchanges: currentUser.completedExchanges,
      ),
    );

    if (result == null) return;

    // Create exchange request
    try {
      final exchangeService = SkillExchangeService();
      final skillOffered = result['skillOffered'];
      
      await exchangeService.createExchangeRequest(
        teacherId: teacher.uid,
        skillOffered: skillOffered ?? 'Free Exchange', // Use placeholder for free exchanges
        skillRequested: _selectedSkill!,
        message: result['message'].isEmpty ? null : result['message'],
      );

      if (!mounted) return;

      // Calculate remaining free exchanges
      final remainingAfter = 3 - currentUser.completedExchanges - 1;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            skillOffered == null
                ? 'Free exchange request sent! You have $remainingAfter free ${remainingAfter == 1 ? "exchange" : "exchanges"} left after this.'
                : 'Exchange request sent to ${teacher.fullName}!',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Learning Partners'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What do you want to learn?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSkill,
              decoration: const InputDecoration(
                labelText: 'Select a skill',
                prefixIcon: Icon(Icons.school),
              ),
              items: AppConfig.popularSkills.map((skill) {
                return DropdownMenuItem(
                  value: skill,
                  child: Text(skill),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSkill = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _searchMatches,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Find Matches'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _matches.isEmpty
                  ? Center(
                      child: Text(
                        _selectedSkill == null
                            ? 'Select a skill to find matches'
                            : 'No matches found. Try another skill!',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _matches.length,
                      itemBuilder: (context, index) {
                        final user = _matches[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profileImageUrl != null
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                              child: user.profileImageUrl == null
                                  ? Text(user.fullName[0])
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Text(user.fullName),
                                if (_selectedSkill != null && user.verifiedSkills.contains(_selectedSkill)) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, size: 16, color: AppTheme.successColor),
                                  const Text(
                                    ' XchangeHub Verified',
                                    style: TextStyle(
                                      color: AppTheme.successColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '⭐ ${user.averageRating.toStringAsFixed(1)} • Level ${user.level}',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                await _requestExchange(user);
                              },
                              child: const Text('Connect'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
