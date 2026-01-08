import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.privacy_tip, color: Colors.white, size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Introduction
            _buildSection(
              context,
              'Introduction',
              'Welcome to XChangeHub. We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our application.',
            ),

            // Information We Collect
            _buildSection(
              context,
              'Information We Collect',
              'We collect information that you provide to us directly and information that is automatically collected when you use our services:',
            ),

            _buildBulletPoint(context, 'Account Information: Name, email address, username, profile picture, and bio'),
            _buildBulletPoint(context, 'Skills Information: Skills you want to teach and learn'),
            _buildBulletPoint(context, 'Portfolio Data: Your projects, work samples, and achievements'),
            _buildBulletPoint(context, 'Communication Data: Messages, exchange requests, and notifications'),
            _buildBulletPoint(context, 'Usage Data: How you interact with our app and services'),

            const SizedBox(height: 16),

            // Permissions Explained
            _buildSection(
              context,
              'Permissions Explained',
              'Our app requires certain permissions to provide you with the best experience. Here\'s why we need each permission:',
            ),

            _buildPermissionCard(
              context,
              icon: Icons.camera_alt,
              title: 'Camera Permission',
              description: 'We request camera access to allow you to:',
              uses: [
                'Take and upload profile pictures',
                'Capture project images for your portfolio',
                'Participate in video calls and live sessions with other users',
                'Share visual content during skill exchanges',
              ],
              color: AppTheme.primaryColor,
            ),

            _buildPermissionCard(
              context,
              icon: Icons.mic,
              title: 'Microphone Permission',
              description: 'We request microphone access to enable you to:',
              uses: [
                'Participate in audio and video calls with other users',
                'Record voice messages during skill exchanges',
                'Communicate during live learning sessions',
                'Provide audio feedback and reviews',
              ],
              color: AppTheme.secondaryColor,
            ),

            _buildPermissionCard(
              context,
              icon: Icons.wifi,
              title: 'Internet Permission',
              description: 'We use internet connectivity to:',
              uses: [
                'Sync your data across devices',
                'Connect you with other users for skill exchanges',
                'Send and receive messages and notifications',
                'Upload and download content (images, portfolio items)',
                'Access real-time features like video calls and chat',
              ],
              color: Colors.blue,
            ),

            _buildPermissionCard(
              context,
              icon: Icons.notifications,
              title: 'Notification Permission',
              description: 'We request notification permission to:',
              uses: [
                'Notify you about new skill exchange requests',
                'Alert you about upcoming scheduled sessions',
                'Inform you about messages from other users',
                'Remind you about important events and deadlines',
                'Update you about your achievements and milestones',
              ],
              color: Colors.orange,
            ),

            _buildPermissionCard(
              context,
              icon: Icons.power_settings_new,
              title: 'Boot Completed Permission',
              description: 'This permission allows us to:',
              uses: [
                'Restore scheduled notifications after device restart',
                'Ensure you don\'t miss important reminders',
                'Maintain background services for timely notifications',
              ],
              color: Colors.green,
            ),

            _buildPermissionCard(
              context,
              icon: Icons.vibration,
              title: 'Vibration Permission',
              description: 'We use vibration to:',
              uses: [
                'Provide haptic feedback for better user experience',
                'Alert you about important notifications',
                'Enhance notification awareness',
              ],
              color: Colors.purple,
            ),

            // Data Usage
            _buildSection(
              context,
              'How We Use Your Data',
              'We use the collected information for the following purposes:',
            ),

            _buildBulletPoint(context, 'To provide and maintain our services'),
            _buildBulletPoint(context, 'To facilitate skill exchanges between users'),
            _buildBulletPoint(context, 'To send you notifications about your account activity'),
            _buildBulletPoint(context, 'To improve and personalize your experience'),
            _buildBulletPoint(context, 'To communicate with you about updates and features'),
            _buildBulletPoint(context, 'To ensure the security and integrity of our platform'),

            const SizedBox(height: 16),

            // Data Sharing
            _buildSection(
              context,
              'Data Sharing and Disclosure',
              'We do not sell your personal information. We may share your data only in the following circumstances:',
            ),

            _buildBulletPoint(context, 'With other users: Your profile information, skills, and portfolio are visible to other users to facilitate skill exchanges'),
            _buildBulletPoint(context, 'Service Providers: We may share data with trusted service providers who help us operate our app (e.g., cloud storage, analytics)'),
            _buildBulletPoint(context, 'Legal Compliance: We may disclose information if required by law or to protect our rights'),

            const SizedBox(height: 16),

            // Data Security
            _buildSection(
              context,
              'Data Security',
              'We implement industry-standard security measures to protect your personal information:',
            ),

            _buildBulletPoint(context, 'Encrypted data transmission (SSL/TLS)'),
            _buildBulletPoint(context, 'Secure cloud storage with Firebase'),
            _buildBulletPoint(context, 'Regular security audits and updates'),
            _buildBulletPoint(context, 'Access controls and authentication mechanisms'),

            const SizedBox(height: 16),

            // User Rights
            _buildSection(
              context,
              'Your Rights',
              'You have the following rights regarding your personal data:',
            ),

            _buildBulletPoint(context, 'Access: You can view and download your personal data'),
            _buildBulletPoint(context, 'Correction: You can update or correct your information'),
            _buildBulletPoint(context, 'Deletion: You can request deletion of your account and data'),
            _buildBulletPoint(context, 'Portability: You can request a copy of your data in a portable format'),
            _buildBulletPoint(context, 'Withdraw Consent: You can revoke permissions at any time through your device settings'),

            const SizedBox(height: 16),

            // Permission Management
            _buildSection(
              context,
              'Managing Permissions',
              'You can manage app permissions at any time through your device settings:',
            ),

            _buildInfoCard(
              context,
              title: 'Android',
              content: 'Settings → Apps → XChangeHub → Permissions\n\nHere you can enable or disable individual permissions. Note that disabling certain permissions may limit app functionality.',
              icon: Icons.android,
              color: Colors.green,
            ),

            const SizedBox(height: 16),

            // Third Party Services
            _buildSection(
              context,
              'Third-Party Services',
              'Our app uses the following third-party services:',
            ),

            _buildBulletPoint(context, 'Firebase (Google): For authentication, database, and cloud storage'),
            _buildBulletPoint(context, 'Firebase Cloud Messaging: For push notifications'),

            const Text(
              '\nThese services have their own privacy policies which govern the use of your information.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 16),

            // Children's Privacy
            _buildSection(
              context,
              'Children\'s Privacy',
              'Our services are not directed to children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
            ),

            // Data Retention
            _buildSection(
              context,
              'Data Retention',
              'We retain your personal information for as long as your account is active or as needed to provide you services. If you delete your account, we will delete your personal data within 30 days, except where we are required to retain it for legal purposes.',
            ),

            // Changes to Privacy Policy
            _buildSection(
              context,
              'Changes to This Privacy Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. We encourage you to review this Privacy Policy periodically.',
            ),

            // Contact Information
            _buildSection(
              context,
              'Contact Us',
              'If you have any questions or concerns about this Privacy Policy or our data practices, please contact us:',
            ),

            _buildInfoCard(
              context,
              title: 'Contact Information',
              content: 'Email: support@xchangehub.com\nApp: Use the "Contact Support" feature in settings',
              icon: Icons.contact_mail,
              color: AppTheme.primaryColor,
            ),

            const SizedBox(height: 16),

            // Consent
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.verified_user, color: AppTheme.primaryColor, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Your Consent',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'By using XChangeHub, you consent to this Privacy Policy and agree to our collection and use of information as described herein.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 20, height: 1.2)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<String> uses,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          ...uses.map((use) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✓ ', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        use,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
