import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/widgets/app_logo.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String privacyPolicyText = '''
Privacy Policy - Emperor Smart Solutions
Effective Date: September 21, 2026
Last Updated: September 21, 2026

1. Overview
Emperor Smart Solutions ("we", "us", "our", or "Company") develops and publishes mobile applications, including utility and productivity tools available through Google Play and other supported platforms. This Privacy Policy explains how we handle information in our mobile applications.
This Privacy Policy applies to all our applications that link to this policy, including utility apps such as frame generators, calculators, converters, productivity tools, and document utilities. By using one of our applications, you acknowledge the practices described in this Privacy Policy.

2. Information We Collect
The information handled by an application depends on the specific features and services used in that application.
• Information You Provide: Our basic utility applications generally do not require account creation, registration, or submission of personal information such as your name, email address, or phone number. Any data entered into local tools remains processed on your device.
• Device and Technical Data: Limited non-identifying technical data may be processed automatically, such as device model, OS version, language preference, system performance metrics, and app stability reports.
• Storage and Media Access: For applications that handle images, files, or custom exports, access to local device storage is requested solely with your explicit permission to perform requested user actions.

3. How We Use Information
We process data strictly to provide, operate, maintain, and improve application functionality, fulfill user requests, diagnose technical issues, and enforce security standards.

4. Local Processing & Data Privacy
Our utility applications operate 100% locally on your device. Your images, edits, calculations, and custom content remain strictly stored on your device and are never uploaded, transmitted, or stored on external servers.

5. Advertising & Analytics
Applications may incorporate standard third-party services (such as Google AdMob, Firebase Analytics, or Google Play Services) to deliver in-app ads or track general performance metrics. These services may collect device identifiers in accordance with their privacy policies.
''';

  void _sharePrivacyPolicy(BuildContext context) {
    try {
      Share.share(
        privacyPolicyText,
        subject: 'Privacy Policy - Emperor Smart Solutions',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Privacy Policy',
            onPressed: () => _sharePrivacyPolicy(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const AppLogo(size: 40, borderRadius: 10),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emperor Smart Solutions',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Effective: Sept 21, 2026 • Updated: Sept 21, 2026',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              title: '1. Overview',
              content:
                  'Emperor Smart Solutions ("we", "us", "our", or "Company") develops and publishes mobile applications, including utility and productivity tools available through Google Play and other supported platforms. This Privacy Policy explains how we handle information in our mobile applications.\n\nThis Privacy Policy applies to all our applications that link to this policy, including utility apps such as frame generators, calculators, converters, productivity tools, and document utilities. By using one of our applications, you acknowledge the practices described in this Privacy Policy.',
            ),
            _buildSection(
              context,
              title: '2. Information We Collect',
              content:
                  'The information handled by an application depends on the specific features and services used in that application.\n\n'
                  '• Information You Provide: Our basic utility applications generally do not require account creation, registration, or submission of personal information such as your name, email address, or phone number. Any data entered into local tools remains processed on your device.\n\n'
                  '• Device and Technical Data: Limited non-identifying technical data may be processed automatically, such as device model, OS version, language preference, system performance metrics, and app stability reports.\n\n'
                  '• Storage and Media Access: For applications that handle images, files, or custom exports, access to local device storage is requested solely with your explicit permission to perform requested user actions.',
            ),
            _buildSection(
              context,
              title: '3. How We Use Information',
              content:
                  'We process data strictly to provide, operate, maintain, and improve application functionality, fulfill user requests, diagnose technical issues, and enforce security standards.',
            ),
            _buildSection(
              context,
              title: '4. Local Processing & Data Privacy',
              content:
                  'Our utility applications operate 100% locally on your device. Your images, edits, calculations, and custom content remain strictly stored on your device and are never uploaded, transmitted, or stored on external servers.',
            ),
            _buildSection(
              context,
              title: '5. Advertising & Analytics',
              content:
                  'Applications may incorporate standard third-party services (such as Google AdMob, Firebase Analytics, or Google Play Services) to deliver in-app ads or track general performance metrics. These services may collect device identifiers in accordance with their privacy policies.',
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                '© 2026 Emperor Smart Solutions. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
