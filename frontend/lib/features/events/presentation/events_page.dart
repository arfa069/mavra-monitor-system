import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_scaffold.dart';
import '../domain/event_models.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key, required this.repository});

  final EventRepository repository;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  EventFilter _filter = EventFilter.all;
  Future<List<EventFeedItem>>? _eventsFuture;
  List<EventFeedItem> _events = const [];
  Object? _error;
  StreamSubscription<EventFeedItem>? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _load() {
    _error = null;
    _eventsFuture =
        Future.sync(() => widget.repository.listEvents(filter: _filter))
          ..then((events) {
            if (mounted) {
              setState(() {
                _events = events;
              });
            }
          }).catchError((Object error) {
            if (mounted) {
              setState(() {
                _error = error;
              });
            }
          });
    _subscription?.cancel();
    _subscription = widget.repository.watchEvents(filter: _filter).listen((
      event,
    ) {
      if (mounted) {
        setState(() {
          _events = [event, ..._events.where((item) => item.id != event.id)];
        });
      }
    });
  }

  void _setFilter(EventFilter filter) {
    if (_filter == filter) {
      return;
    }
    setState(() {
      _filter = filter;
      _events = const [];
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.today, label: 'Today'),
          AdaptiveDestination(icon: Icons.event_note, label: 'Events'),
          AdaptiveDestination(icon: Icons.notifications, label: 'Alerts'),
          AdaptiveDestination(icon: Icons.analytics, label: 'Analytics'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 2:
              context.go('/alerts');
            case 3:
              context.go('/analytics');
          }
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                SegmentedButton<EventFilter>(
                  segments: const [
                    ButtonSegment(value: EventFilter.all, label: Text('All')),
                    ButtonSegment(
                      value: EventFilter.audit,
                      label: Text('Audit'),
                    ),
                    ButtonSegment(
                      value: EventFilter.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: EventFilter.platform,
                      label: Text('Platform'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (selection) =>
                      _setFilter(selection.single),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<EventFeedItem>>(
                    future: _eventsFuture,
                    builder: (context, snapshot) {
                      if (_error != null) {
                        return const _EventsError();
                      }
                      if (snapshot.connectionState != ConnectionState.done &&
                          _events.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_events.isEmpty) {
                        return const Center(child: Text('No events yet'));
                      }
                      return ListView.separated(
                        itemCount: _events.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _EventTile(item: _events[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.item});

  final EventFeedItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bolt),
      title: Text(item.message),
      subtitle: Text('${item.kind.label} - ${item.source} - ${item.severity}'),
      trailing: Text(item.category),
    );
  }
}

class _EventsError extends StatelessWidget {
  const _EventsError();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Event center unavailable'));
  }
}
