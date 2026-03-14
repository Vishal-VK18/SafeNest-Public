import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_entry.dart';
import '../models/log_parameter.dart';
import '../services/firebase_database_service.dart';
import 'firebase_database_provider.dart';

// State for logs viewer
class LogsState {
  final List<LogEntry> entries;
  final bool isLoading;
  final String? error;
  final DateTime? startDate;
  final DateTime? endDate;
  final LogParameter parameter;

  const LogsState({
    required this.parameter,
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.startDate,
    this.endDate,
  });

  LogsState copyWith({
    List<LogEntry>? entries,
    bool? isLoading,
    String? error,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return LogsState(
      parameter: parameter,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class LogsNotifier extends StateNotifier<LogsState> {
  final FirebaseDatabaseService _db;
  final LogParameter parameter;

  LogsNotifier(this._db, this.parameter)
      : super(LogsState(parameter: parameter));

  Future<void> fetchLogs({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await _db.fetchLogsForParameter(
        parameter: parameter,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        entries: entries,
        isLoading: false,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load logs. Please try again.',
      );
    }
  }

  void clearFilter() {
    fetchLogs();
  }
}

// Family provider — one per parameter
final logsProvider = StateNotifierProvider.family<LogsNotifier, LogsState, LogParameter>((ref, parameter) {
  final db = ref.watch(firebaseDatabaseServiceProvider);
  return LogsNotifier(db, parameter);
});
