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
  Future<List<EventFeedItem>> listEvents({
    EventFilter filter = EventFilter.all,
  }) async {
    final response = await _eventsApi.eventsListEvents(
      eventType: filter.apiValue,
    );
    return [
      for (final item in response.data?.items ?? <generated.EventCenterItem>[])
        _mapEvent(item),
    ];
  }

  @override
  Stream<EventFeedItem> watchEvents({EventFilter filter = EventFilter.all}) {
    return _realtimeClient
        .connect('events')
        .map(_eventFromRealtime)
        .where(
          (item) => filter == EventFilter.all || item.kind.name == filter.name,
        );
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
    );
  }

  EventKind _mapKind(String? value) {
    return switch (value) {
      'audit' => EventKind.audit,
      'platform' => EventKind.platform,
      _ => EventKind.system,
    };
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
