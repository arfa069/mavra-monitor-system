class SchedulerStatus {
  const SchedulerStatus({required this.label, required this.timezone});

  final String label;
  final String? timezone;
}

class ProductSchedule {
  const ProductSchedule({
    required this.platform,
    required this.cronExpression,
    required this.nextRunAt,
  });

  final String platform;
  final String cronExpression;
  final String? nextRunAt;
}

class JobSchedule {
  const JobSchedule({
    required this.configId,
    required this.name,
    required this.cronExpression,
    required this.nextRunAt,
  });

  final int configId;
  final String name;
  final String cronExpression;
  final String? nextRunAt;
}

class ScheduleSnapshot {
  const ScheduleSnapshot({
    required this.status,
    required this.productSchedules,
    required this.jobSchedules,
    required this.canConfigure,
  });

  const ScheduleSnapshot.empty()
    : status = const SchedulerStatus(
        label: 'Scheduler stopped',
        timezone: null,
      ),
      productSchedules = const [],
      jobSchedules = const [],
      canConfigure = true;

  final SchedulerStatus status;
  final List<ProductSchedule> productSchedules;
  final List<JobSchedule> jobSchedules;
  final bool canConfigure;

  bool get hasRules => productSchedules.isNotEmpty || jobSchedules.isNotEmpty;
}

enum ScheduleRuleTarget { productPlatform, jobConfig }

class ScheduleRuleDraft {
  const ScheduleRuleDraft({
    required this.targetType,
    required this.targetName,
    required this.hour,
    required this.minute,
    required this.weekdays,
    this.configId,
    this.timezone = 'Asia/Shanghai',
  });

  final ScheduleRuleTarget targetType;
  final String targetName;
  final int hour;
  final int minute;
  final String weekdays;
  final int? configId;
  final String timezone;

  String get cronExpression => CronGenerator.expressionFor(
    hour: hour,
    minute: minute,
    weekdays: weekdays,
  );
}

class CronPreview {
  const CronPreview({required this.expression});

  final String expression;
}

abstract class ScheduleRepository {
  Future<ScheduleSnapshot> loadSchedule();

  Future<CronPreview> previewCron(ScheduleRuleDraft draft);

  Future<void> saveRule(ScheduleRuleDraft draft);
}

class ScheduleValidationException implements Exception {
  const ScheduleValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CronGenerator {
  const CronGenerator._();

  static String expressionFor({
    required int hour,
    required int minute,
    required String weekdays,
  }) {
    _validateHour(hour);
    _validateMinute(minute);
    final normalizedWeekdays = _normalizeWeekdays(weekdays);
    return '$minute $hour * * $normalizedWeekdays';
  }

  static void validateDraft(ScheduleRuleDraft draft) {
    if (draft.targetName.trim().isEmpty) {
      throw const ScheduleValidationException('Target is required');
    }
    if (draft.targetType == ScheduleRuleTarget.jobConfig &&
        draft.configId == null) {
      throw const ScheduleValidationException('Job config id is required');
    }
    expressionFor(
      hour: draft.hour,
      minute: draft.minute,
      weekdays: draft.weekdays,
    );
  }

  static void _validateHour(int hour) {
    if (hour < 0 || hour > 23) {
      throw const ScheduleValidationException('Hour must be 0-23');
    }
  }

  static void _validateMinute(int minute) {
    if (minute < 0 || minute > 59) {
      throw const ScheduleValidationException('Minute must be 0-59');
    }
  }

  static String _normalizeWeekdays(String weekdays) {
    final trimmed = weekdays.trim();
    if (trimmed.isEmpty) {
      return '*';
    }
    final valid = RegExp(r'^(\*|[0-7](?:-[0-7])?(?:,[0-7](?:-[0-7])?)*)$');
    if (!valid.hasMatch(trimmed)) {
      throw const ScheduleValidationException(
        'Weekdays must be *, 1-5, or a comma list',
      );
    }
    return trimmed;
  }
}
