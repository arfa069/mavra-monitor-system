enum EventKind { audit, system, platform }

enum EventFilter { all, audit, system, platform }

class EventQuery {
  const EventQuery({
    this.filter = EventFilter.all,
    this.eventType,
    this.category,
    this.severity,
    this.source,
    this.keyword,
    this.startAt,
    this.endAt,
    this.page = 1,
    this.pageSize = 20,
  });

  final EventFilter filter;
  final String? eventType;
  final String? category;
  final String? severity;
  final String? source;
  final String? keyword;
  final DateTime? startAt;
  final DateTime? endAt;
  final int page;
  final int pageSize;

  EventQuery copyWith({
    EventFilter? filter,
    String? eventType,
    String? category,
    String? severity,
    String? source,
    String? keyword,
    DateTime? startAt,
    DateTime? endAt,
    int? page,
    int? pageSize,
  }) {
    return EventQuery(
      filter: filter ?? this.filter,
      eventType: eventType ?? this.eventType,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      source: source ?? this.source,
      keyword: keyword ?? this.keyword,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class EventFeedItem {
  const EventFeedItem({
    required this.id,
    required this.kind,
    required this.category,
    required this.eventType,
    required this.message,
    required this.severity,
    required this.source,
    required this.occurredAt,
  });

  final String id;
  final EventKind kind;
  final String category;
  final String eventType;
  final String message;
  final String severity;
  final String source;
  final DateTime occurredAt;
}

class EventPage {
  const EventPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<EventFeedItem> items;
  final int page;
  final int pageSize;
  final int total;

  bool get hasPrevious => page > 1;

  bool get hasNext => page * pageSize < total;
}

abstract class EventRepository {
  Future<EventPage> listEvents({EventQuery query = const EventQuery()});

  Stream<EventFeedItem> watchEvents({EventQuery query = const EventQuery()});
}

extension EventFilterApiValue on EventFilter {
  String get apiValue => switch (this) {
    EventFilter.all => 'all',
    EventFilter.audit => 'audit',
    EventFilter.system => 'system',
    EventFilter.platform => 'platform',
  };
}

extension EventKindLabel on EventKind {
  String get label => switch (this) {
    EventKind.audit => 'Audit',
    EventKind.system => 'System',
    EventKind.platform => 'Platform',
  };
}
