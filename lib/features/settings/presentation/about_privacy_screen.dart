import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/app_card.dart';

class AboutPrivacyScreen extends StatelessWidget {
  const AboutPrivacyScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const sectionHeaderStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.0,
      color: Color(0xFF4C51BF),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Privacy', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Description Header Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Text(
                'A professional, 100% offline personal savings tracker app. Create saving challenges, record savings, track balances, categories, and achieve your financial goals without sending data to servers.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: LEGAL & GOVERNANCE
            const Text('LEGAL & GOVERNANCE', style: sectionHeaderStyle),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.green, size: 24),
                ),
                title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text(
                  'Read full data safety practices & privacy policy',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => context.push('/settings/privacy'),
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: CONNECT WITH US
            const Text('CONNECT WITH US', style: sectionHeaderStyle),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Instagram
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const InstagramBrandAvatar(size: 44),
                    title: const Text('Instagram', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('Follow Emperor Smart Solutions', style: TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.north_east, color: Colors.grey, size: 20),
                    onTap: () => _launchUrl(context, 'https://www.instagram.com/emperorsmartsolutions'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // LinkedIn
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const LinkedInBrandAvatar(size: 44),
                    title: const Text('LinkedIn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('Follow Emperor Smart Solutions', style: TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.north_east, color: Colors.grey, size: 20),
                    onTap: () => _launchUrl(context, 'https://www.linkedin.com/company/emperor-smart-solutions/'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Contact Us
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phone_outlined, color: Colors.teal, size: 24),
                    ),
                    title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('+91 63543 51080', style: TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.north_east, color: Colors.teal, size: 20),
                    onTap: () => _launchUrl(context, 'tel:+916354351080'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: DEVELOPER
            const Text('DEVELOPER', style: sectionHeaderStyle),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Emperor Smart Solutions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.domain, color: Colors.indigo, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Emperor Smart Solutions',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Emperor Smart Solutions develops software, mobile applications, digital products, and utility applications.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Office Address
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_on_outlined, color: Colors.redAccent, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Office Address',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '202, Shitiratna Complex, Panchvati, Navrangpura, Ahmedabad - 380009, Gujarat, India',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _launchUrl(
                            context,
                            'https://maps.google.com/?q=202,+Shitiratna+Complex,+Panchvati,+Navrangpura,+Ahmedabad+-+380009,+Gujarat,+India',
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined, color: Color(0xFF4C51BF), size: 22),
                                SizedBox(height: 2),
                                Text(
                                  'View Map',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4C51BF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                '© 2026 Emperor Smart Solutions. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Custom Vector Brand Avatar for Instagram
class InstagramBrandAvatar extends StatelessWidget {
  final double size;
  const InstagramBrandAvatar({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF833AB4),
            Color(0xFFFD1D1D),
            Color(0xFFF77737),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.55, size * 0.55),
          painter: _InstagramIconPainter(),
        ),
      ),
    );
  }
}

class _InstagramIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.28),
    );
    canvas.drawRRect(rect, paint);

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.22, paint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.25), size.width * 0.06, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Vector Brand Avatar for LinkedIn
class LinkedInBrandAvatar extends StatelessWidget {
  final double size;
  const LinkedInBrandAvatar({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0077B5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'in',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.55,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
