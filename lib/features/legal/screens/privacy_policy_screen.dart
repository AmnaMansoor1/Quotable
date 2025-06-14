import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 80,
                    color: Color(0xFF003B5C),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003B5C),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Last updated: December 2024',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Introduction
            _buildSection(
              'Introduction',
              'Welcome to Quoteable! This Privacy Policy explains how we collect, use, and protect your information when you use our mobile application. We are committed to protecting your privacy and ensuring you have a positive experience on our app.',
            ),
            
            _buildSection(
              'Information We Collect',
              '''We may collect the following types of information:

• Account Information: When you create an account, we collect your email address and any profile information you provide.

• Usage Data: We collect information about how you use the app, including quotes you view, save, and share.

• Device Information: We may collect device-specific information such as your device model, operating system version, and unique device identifiers.

• Analytics Data: We use analytics services to understand app usage patterns and improve our services.''',
            ),
            
            _buildSection(
              'How We Use Your Information',
              '''We use the collected information for the following purposes:

• To provide and maintain our service
• To personalize your experience with relevant quotes
• To sync your favorites across devices
• To send you notifications (if enabled)
• To improve our app and develop new features
• To communicate with you about updates and support
• To ensure the security and integrity of our service''',
            ),
            
            _buildSection(
              'Data Storage and Security',
              '''We take the security of your personal information seriously:

• Your data is stored securely using industry-standard encryption
• We use Firebase services for secure data storage and authentication
• We implement appropriate technical and organizational measures to protect your information
• We regularly review our security practices and update them as needed''',
            ),
            
            _buildSection(
              'Third-Party Services',
              '''Our app integrates with the following third-party services:

• Firebase (Google): For authentication, database, and analytics
• Google AdMob: For displaying advertisements
• Quote APIs: For fetching inspirational quotes

Each of these services has their own privacy policies, which we encourage you to review.''',
            ),
            
            _buildSection(
              'Advertisements',
              '''Our app displays advertisements through Google AdMob:

• Ads may be personalized based on your interests
• You can opt out of personalized ads in your device settings
• We do not share your personal information with advertisers
• Ad networks may collect anonymous usage data for ad targeting''',
            ),
            
            _buildSection(
              'Your Rights and Choices',
              '''You have the following rights regarding your personal information:

• Access: You can request access to your personal data
• Correction: You can update or correct your information
• Deletion: You can request deletion of your account and data
• Portability: You can request a copy of your data
• Opt-out: You can disable notifications and data collection features''',
            ),
            
            _buildSection(
              'Children\'s Privacy',
              'Our app is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
            ),
            
            _buildSection(
              'Data Retention',
              'We retain your personal information only as long as necessary to provide our services and fulfill the purposes outlined in this policy. When you delete your account, we will delete your personal information within 30 days, except where we are required to retain it by law.',
            ),
            
            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. We encourage you to review this Privacy Policy periodically.',
            ),
            
            _buildSection(
              'Contact Us',
              '''If you have any questions about this Privacy Policy or our privacy practices, please contact us:

Email: privacy@quoteable.app
Subject: Privacy Policy Inquiry

We will respond to your inquiry within 48 hours.''',
            ),
            
            const SizedBox(height: 32),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF003B5C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: Color(0xFF003B5C),
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your Privacy Matters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003B5C),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'We are committed to protecting your privacy and being transparent about our data practices.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF003B5C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003B5C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
