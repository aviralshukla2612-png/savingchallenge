class ChallengeTemplate {
  final String name;
  final String description;
  final double targetAmount;
  final int durationDays;
  final String frequency;
  final double savingAmount;
  final String categoryIcon;

  const ChallengeTemplate({
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.durationDays,
    required this.frequency,
    required this.savingAmount,
    required this.categoryIcon,
  });
}

class ChallengeTemplates {
  static const List<ChallengeTemplate> list = [
    ChallengeTemplate(
      name: '30-Day Saving Challenge',
      description: 'Save ₹5,000 in 30 days with a daily habit.',
      targetAmount: 5000.0,
      durationDays: 30,
      frequency: 'daily',
      savingAmount: 167.0,
      categoryIcon: 'calendar_month',
    ),
    ChallengeTemplate(
      name: '52-Week Challenge',
      description: 'Build a solid weekly savings habit to reach ₹52,000 in a year.',
      targetAmount: 52000.0,
      durationDays: 364,
      frequency: 'weekly',
      savingAmount: 1000.0,
      categoryIcon: 'date_range',
    ),
    ChallengeTemplate(
      name: 'Daily ₹50 Challenge',
      description: 'Small daily steps add up! Save ₹50 every single day.',
      targetAmount: 18250.0,
      durationDays: 365,
      frequency: 'daily',
      savingAmount: 50.0,
      categoryIcon: 'savings',
    ),
    ChallengeTemplate(
      name: 'Daily ₹100 Challenge',
      description: 'Save ₹100 daily for one full year to build your nest egg.',
      targetAmount: 36500.0,
      durationDays: 365,
      frequency: 'daily',
      savingAmount: 100.0,
      categoryIcon: 'monetization_on',
    ),
    ChallengeTemplate(
      name: 'Weekly ₹500 Challenge',
      description: 'Put aside ₹500 every week to save ₹26,000 comfortably.',
      targetAmount: 26000.0,
      durationDays: 364,
      frequency: 'weekly',
      savingAmount: 500.0,
      categoryIcon: 'account_balance',
    ),
    ChallengeTemplate(
      name: '₹10,000 Short-Term Goal',
      description: 'A quick 3-month saving goal for small purchases or gifts.',
      targetAmount: 10000.0,
      durationDays: 90,
      frequency: 'monthly',
      savingAmount: 3334.0,
      categoryIcon: 'flag',
    ),
    ChallengeTemplate(
      name: 'Emergency Fund',
      description: 'Build a safety net for unexpected financial needs over 6 months.',
      targetAmount: 50000.0,
      durationDays: 180,
      frequency: 'monthly',
      savingAmount: 8334.0,
      categoryIcon: 'health_and_safety',
    ),
  ];
}
