// lib/models/pregnancy_model.dart

class PregnancyModel {
  final int pregnancyWeek;
  final String userName;

  const PregnancyModel({
    required this.pregnancyWeek,
    this.userName = 'Sarah',
  });

  factory PregnancyModel.defaults() => const PregnancyModel(
    pregnancyWeek: 22,
    userName:      'Sarah',
  );

  // ─── Derived values ─────────────────────────────────────────────────────────
  int get pregnancyMonth {
    if (pregnancyWeek <= 4)  return 1;
    if (pregnancyWeek <= 8)  return 2;
    if (pregnancyWeek <= 13) return 3;
    if (pregnancyWeek <= 17) return 4;
    if (pregnancyWeek <= 21) return 5;
    if (pregnancyWeek <= 26) return 6;
    if (pregnancyWeek <= 30) return 7;
    if (pregnancyWeek <= 35) return 8;
    return 9;
  }

  String get trimesterLabel {
    if (pregnancyWeek <= 13) return 'First Trimester';
    if (pregnancyWeek <= 26) return 'Second Trimester';
    return 'Third Trimester';
  }

  int get daysRemaining {
    const totalDays = 280; // 40 weeks
    final elapsed = pregnancyWeek * 7;
    return (totalDays - elapsed).clamp(0, totalDays);
  }

  DateTime get estimatedDueDate =>
      DateTime.now().add(Duration(days: daysRemaining));

  String get estimatedDueDateLabel {
    final d = estimatedDueDate;
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  double get progressFraction => (pregnancyWeek / 40.0).clamp(0.0, 1.0);

  String get weekLabel => 'Week $pregnancyWeek';
  String get monthLabel => 'Month $pregnancyMonth';
  String get daysRemainingLabel => '$daysRemaining days to go';

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  PregnancyModel copyWith({int? pregnancyWeek, String? userName}) =>
      PregnancyModel(
        pregnancyWeek: pregnancyWeek ?? this.pregnancyWeek,
        userName:      userName      ?? this.userName,
      );
}
