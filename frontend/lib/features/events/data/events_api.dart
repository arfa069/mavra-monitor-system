import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../../../core/realtime/realtime_client.dart';
import '../domain/event_models.dart';

class GeneratedEventRepository implements EventRepository {
  GeneratedEventRepository({
    required AppConfig config,
    generated.MavraApi? client,
    RealtimeClient? realtimeClient,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           ),
       _realtimeClient =
           realtimeClient ?? PollingRealtimeClient(poll: () async => const []);

  final generated.MavraApi _client;
  final RealtimeClient _realtimeClient;

  generated.EventsApi get _eventsApi => _client.getEventsApi();

  @override
  Future<EventPage> listEvents({EventQuery query = const EventQuery()}) async {
    final response = await _eventsApi.eventsListEvents(
      kind: query.filter.apiValue,
      eventType: query.eventType,
      category: query.category,
      severity: query.severity,
      source_: query.source,
      keyword: query.keyword,
      startAt: query.startAt,
      endAt: query.endAt,
      page: query.page,
      pageSize: query.pageSize,
    );
    final data = response.data;
    return EventPage(
      items: [
        for (final item in data?.items ?? <generated.EventCenterItem>[])
          _mapEvent(item),
      ],
      page: data?.page ?? query.page,
      pageSize: data?.pageSize ?? query.pageSize,
      total: data?.total ?? 0,
    );
  }

  @override
  Stream<EventFeedItem> watchEvents({EventQuery query = const EventQuery()}) {
    return _realtimeClient
        .connect('events')
        .map(_eventFromRealtime)
        .where((item) => _matchesQuery(item, query));
  }

  EventFeedItem _mapEvent(generated.EventCenterItem item) {
    return EventFeedItem(
      id: item.id,
      kind: _mapKind(item.kind.name),
      category: item.category,
      eventType: item.eventType,
      message: item.message,
      severity: item.severity,
      source: item.source_,
      occurredAt: item.occurredAt,
      status: item.status,
      userId: item.userId,
      entityType: item.entityType,
      entityId: item.entityId,
      traceId: item.traceId,
      payload: _mapPayload(item.payload),
    );
  }

  EventFeedItem _eventFromRealtime(RealtimeMessage message) {
    final payload = message.payload;
    return EventFeedItem(
      id: payload['id']?.toString() ?? DateTime.now().toIso8601String(),
      kind: _mapKind(payload['kind']?.toString()),
      category: payload['category']?.toString() ?? 'runtime',
      eventType: payload['event_type']?.toString() ?? message.type,
      message: payload['message']?.toString() ?? 'Event update',
      severity: payload['severity']?.toString() ?? 'info',
      source: payload['source']?.toString() ?? 'realtime',
      occurredAt:
          DateTime.tryParse(payload['occurred_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      status: payload['status']?.toString(),
      userId: _intOrNull(payload['user_id']),
      entityType: payload['entity_type']?.toString(),
      entityId: payload['entity_id']?.toString(),
      traceId: payload['trace_id']?.toString(),
      payload: _mapRealtimePayload(payload['payload']),
    );
  }

  EventKind _mapKind(String? value) {
    return switch (value) {
      'audit' => EventKind.audit,
      'platform' => EventKind.platform,
      _ => EventKind.system,
    };
  }

  bool _matchesQuery(EventFeedItem item, EventQuery query) {
    if (query.filter != EventFilter.all &&
        item.kind.name != query.filter.name) {
      return false;
    }
    if (!_equalsIfPresent(query.eventType, item.eventType)) {
      return false;
    }
    if (!_equalsIfPresent(query.category, item.category)) {
      return false;
    }
    if (!_equalsIfPresent(query.severity, item.severity)) {
      return false;
    }
    if (!_equalsIfPresent(query.source, item.source)) {
      return false;
    }
    final startAt = query.startAt;
    if (startAt != null && item.occurredAt.isBefore(startAt)) {
      return false;
    }
    final endAt = query.endAt;
    if (endAt != null && item.occurredAt.isAfter(endAt)) {
      return false;
    }
    final keyword = query.keyword?.trim().toLowerCase();
    if (keyword == null || keyword.isEmpty) {
      return true;
    }
    return [
      item.message,
      item.eventType,
      item.category,
      item.severity,
      item.source,
      item.status,
      item.entityType,
      item.entityId,
      item.traceId,
      item.userId?.toString(),
    ].whereType<String>().any((value) => value.toLowerCase().contains(keyword));
  }

  bool _equalsIfPresent(String? expected, String actual) {
    return expected == null || expected.isEmpty || actual == expected;
  }

  int? _intOrNull(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, Object?>? _mapPayload(BuiltMap<String, JsonObject?>? payload) {
    if (payload == null) {
      return null;
    }
    return {
      for (final entry in payload.entries)
        entry.key: _normalizeJson(entry.value?.value),
    };
  }

  Map<String, Object?>? _mapRealtimePayload(Object? payload) {
    if (payload is Map) {
      return {
        for (final entry in payload.entries)
          entry.key.toString(): _normalizeJson(entry.value),
      };
    }
    return null;
  }

  Object? _normalizeJson(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _normalizeJson(entry.value),
      };
    }
    if (value is Iterable) {
      return [for (final item in value) _normalizeJson(item)];
    }
    return value;
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
