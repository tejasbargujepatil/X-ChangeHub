import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/enhancement_services.dart';

class VerifiedCertificateDialog extends StatelessWidget {
  final String userId;
  final String userName;
  final String skill;
  final VerificationService? verificationService;

  const VerifiedCertificateDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.skill,
    this.verificationService,
  });

  @override
  Widget build(BuildContext context) {
    final service = verificationService ?? VerificationService();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: FutureBuilder<List<String>>(
        future: service.getVerifiedSkills(userId),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppTheme.surfaceColor,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Verifying credential status...',
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // 2. Error State (Fail-Closed)
          if (snapshot.hasError) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppTheme.surfaceColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Verification Lookup Error',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.errorColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to verify credential status: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }

          // 3. Fail-Closed Check: Verify Skill Exists in User's Verified Skills
          final verifiedSkills = snapshot.data ?? [];
          final isVerified = verifiedSkills.contains(skill);

          if (!isVerified) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppTheme.surfaceColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gavel, size: 48, color: AppTheme.warningColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Skill Not Verified',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.warningColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This skill does not currently have an XchangeHub Verified credential.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }

          // 4. Verified State: Render Official Credential Card
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.surfaceColor,
              border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ribbon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.successGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 16),

                Text(
                  'XCHANGEHUB VERIFIED',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 4),

                Text(
                  'Official Skill Certificate',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                const Divider(),
                const SizedBox(height: 12),

                Text(
                  'This certifies that',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: 12),

                Text(
                  'has successfully demonstrated verified mastery of',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    skill,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, size: 14, color: AppTheme.successColor),
                          SizedBox(width: 6),
                          Text(
                            'Backed by Verified Learning Outcomes & Reviewer Audit',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: const Text('Close Credential'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
