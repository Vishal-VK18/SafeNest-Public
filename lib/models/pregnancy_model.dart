// lib/models/pregnancy_model.dart

class PregnancyModel {
  final DateTime? startDate;
  final String userName;
  final int age;
  final int? manualWeek; // Fallback if no start date

  const PregnancyModel({
    this.startDate,
    this.userName   = 'Sarah',
    this.age        = 27,
    this.manualWeek,
  });

  factory PregnancyModel.defaults() => PregnancyModel(
    startDate: DateTime.now().subtract(const Duration(days: 154)), // ~22 weeks ago
    userName:  'Sarah',
    age:       27,
  );

  // ─── Calculations ──────────────────────────────────────────────────────────
  int get pregnancyWeek {
    if (startDate == null) return manualWeek ?? 0;
    final diff = DateTime.now().difference(startDate!);
    final weeks = (diff.inDays / 7).floor();
    return weeks.clamp(0, 42); 
  }

  int get pregnancyMonth {
    final w = pregnancyWeek;
    if (w <= 4)  return 1;
    if (w <= 8)  return 2;
    if (w <= 13) return 3;
    if (w <= 17) return 4;
    if (w <= 21) return 5;
    if (w <= 26) return 6;
    if (w <= 30) return 7;
    if (w <= 35) return 8;
    return 9;
  }

  String get trimesterLabel {
    final w = pregnancyWeek;
    if (w <= 13) return 'FIRST TRIMESTER';
    if (w <= 26) return 'SECOND TRIMESTER';
    return 'THIRD TRIMESTER';
  }

  int get daysToGo {
    const totalDays = 280; // 40 weeks
    final elapsed = pregnancyWeek * 7;
    return (totalDays - elapsed).clamp(0, totalDays);
  }

  DateTime get estimatedDueDate {
    if (startDate != null) {
      return startDate!.add(const Duration(days: 280));
    }
    return DateTime.now().add(Duration(days: daysToGo));
  }

  String get estimatedDueDateLabel {
    final d = estimatedDueDate;
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  double get progressFraction => (pregnancyWeek / 40.0).clamp(0.0, 1.0);

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  bool get hasData => startDate != null || manualWeek != null;

  PregnancyModel copyWith({DateTime? startDate, String? userName, int? age, int? manualWeek}) =>
      PregnancyModel(
        startDate:  startDate  ?? this.startDate,
        userName:   userName   ?? this.userName,
        age:        age        ?? this.age,
        manualWeek: manualWeek ?? this.manualWeek,
      );
}
