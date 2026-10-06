import 'package:flutter/material.dart';

class MilestoneDialog extends StatelessWidget {
  final int percentage; // e.g. 50, 100
  final String challengeName;

  const MilestoneDialog({
    super.key,
    required this.percentage,
    required this.challengeName,
  });

  static Future<void> show(BuildContext context, {required int percentage, required String challengeName}) {
    return showDialog<void>(
      context: context,
      builder: (context) => MilestoneDialog(
        percentage: percentage,
        challengeName: challengeName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final is100 = percentage >= 100;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              is100 ? '🎉 Challenge Completed!' : '🏆 Milestone Reached!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (is100 ? Colors.amber : Theme.of(context).primaryColor).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                is100 ? Icons.emoji_events : Icons.verified,
                size: 64,
                color: is100 ? Colors.amber.shade700 : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              is100
                  ? 'Congratulations! You have saved 100% of your target for "$challengeName"!'
                  : 'You have completed $percentage% of your "$challengeName" saving challenge. Keep up the great work!',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Awesome!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
