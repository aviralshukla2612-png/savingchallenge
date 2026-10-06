class AppConstants {
  static const String appName = 'Saving Challenge';
  static const String appVersion = '1.0.0';

  // Frequencies
  static const String freqDaily = 'daily';
  static const String freqWeekly = 'weekly';
  static const String freqMonthly = 'monthly';
  static const String freqCustom = 'custom';

  // Statuses
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusPaused = 'paused';
  static const String statusCancelled = 'cancelled';

  // Payment Methods
  static const String payCash = 'cash';
  static const String payBank = 'bank';
  static const String payUpi = 'upi';
  static const String payCard = 'card';
  static const String payOther = 'other';

  static const List<String> paymentMethods = [
    payCash,
    payBank,
    payUpi,
    payCard,
    payOther,
  ];

  // Currencies
  static const Map<String, String> currencies = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
  };

  // Milestone Percentages
  static const List<double> milestones = [0.10, 0.25, 0.50, 0.75, 0.90, 1.00];
}

class AchievementDef {
  final String key;
  final String title;
  final String description;
  final String iconName;

  const AchievementDef({
    required this.key,
    required this.title,
    required this.description,
    required this.iconName,
  });
}

class AppAchievements {
  static const List<AchievementDef> all = [
    AchievementDef(
      key: 'first_save',
      title: 'First Save',
      description: 'Made your first saving.',
      iconName: 'savings',
    ),
    AchievementDef(
      key: 'first_1000',
      title: 'First ₹1,000',
      description: 'Saved your first ₹1,000 total.',
      iconName: 'money',
    ),
    AchievementDef(
      key: 'streak_7',
      title: '7 Day Streak',
      description: 'Saved for 7 consecutive periods.',
      iconName: 'local_fire_department',
    ),
    AchievementDef(
      key: 'streak_30',
      title: '30 Day Streak',
      description: 'Saved for 30 consecutive periods.',
      iconName: 'whatshot',
    ),
    AchievementDef(
      key: 'first_challenge',
      title: 'First Challenge',
      description: 'Completed your first saving challenge.',
      iconName: 'emoji_events',
    ),
    AchievementDef(
      key: 'savings_master',
      title: 'Savings Master',
      description: 'Completed 5 saving challenges.',
      iconName: 'stars',
    ),
    AchievementDef(
      key: 'saved_10000',
      title: '₹10,000 Saved',
      description: 'Reached ₹10,000 total savings.',
      iconName: 'account_balance_wallet',
    ),
    AchievementDef(
      key: 'saved_50000',
      title: '₹50,000 Saved',
      description: 'Reached ₹50,000 total savings.',
      iconName: 'military_tech',
    ),
  ];
}
