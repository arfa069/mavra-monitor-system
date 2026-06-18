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
  EventQuery _query = const EventQuery();
  Future<EventPage>? _eventsFuture;
  EventPage? _page;
  List<EventFeedItem> _events = const [];
  Object? _error;
  StreamSubscription<EventFeedItem>? _subscription;
  final _eventTypeController = TextEditingController();
  final _categoryController = TextEditingController();
  final _severityController = TextEditingController();
  final _sourceController = TextEditingController();
  final _keywordController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _eventTypeController.dispose();
    _categoryController.dispose();
    _severityController.dispose();
    _sourceController.dispose();
    _keywordController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _load() {
    _error = null;
    _eventsFuture =
        Future.sync(() => widget.repository.listEvents(query: _query))
          ..then((page) {
            if (mounted) {
              setState(() {
                _page = page;
                _events = page.items;
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
    _subscription = widget.repository.watchEvents(query: _query).listen((
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
    if (_query.filter == filter) {
      return;
    }
    setState(() {
      _query = _query.copyWith(filter: filter, page: 1);
      _events = const [];
    });
    _load();
  }

  void _applyFilters() {
    setState(() {
      _query = EventQuery(
        filter: _query.filter,
        eventType: _textOrNull(_eventTypeController),
        category: _textOrNull(_categoryController),
        severity: _textOrNull(_severityController),
        source: _textOrNull(_sourceController),
        keyword: _textOrNull(_keywordController),
        startAt: DateTime.tryParse(_startController.text.trim()),
        endAt: DateTime.tryParse(_endController.text.trim()),
        page: 1,
        pageSize: _query.pageSize,
      );
      _events = const [];
    });
    _load();
  }

  void _goToPage(int page) {
    setState(() {
      _query = _query.copyWith(page: page);
      _events = const [];
    });
    _load();
  }

  String? _textOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
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
                  selected: {_query.filter},
                  onSelectionChanged: (selection) =>
                      _setFilter(selection.single),
                ),
                const SizedBox(height: 12),
                _EventFilterForm(
                  eventTypeController: _eventTypeController,
                  categoryController: _categoryController,
                  severityController: _severityController,
                  sourceController: _sourceController,
                  keywordController: _keywordController,
                  startController: _startController,
                  endController: _endController,
                  onApplyFilters: _applyFilters,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<EventPage>(
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
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              itemCount: _events.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) => _EventTile(
                                item: _events[index],
                                onShowDetails: () =>
                                    _showEventDetails(context, _events[index]),
                              ),
                            ),
                          ),
                          _EventPager(
                            page: _page ?? snapshot.data,
                            onPrevious: () => _goToPage(_query.page - 1),
                            onNext: () => _goToPage(_query.page + 1),
                          ),
                        ],
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

class _EventFilterForm extends StatelessWidget {
  const _EventFilterForm({
    required this.eventTypeController,
    required this.categoryController,
    required this.severityController,
    required this.sourceController,
    required this.keywordController,
    required this.startController,
    required this.endController,
    required this.onApplyFilters,
  });

  final TextEditingController eventTypeController;
  final TextEditingController categoryController;
  final TextEditingController severityController;
  final TextEditingController sourceController;
  final TextEditingController keywordController;
  final TextEditingController startController;
  final TextEditingController endController;
  final VoidCallback onApplyFilters;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _SmallFilterField(
          key: const Key('events-keyword-field'),
          controller: keywordController,
          label: 'Keyword',
        ),
        _SmallFilterField(
          key: const Key('events-type-field'),
          controller: eventTypeController,
          label: 'Type',
        ),
        _SmallFilterField(
          key: const Key('events-category-field'),
          controller: categoryController,
          label: 'Category',
        ),
        _SmallFilterField(
          key: const Key('events-severity-field'),
          controller: severityController,
          label: 'Severity',
        ),
        _SmallFilterField(
          key: const Key('events-source-field'),
          controller: sourceController,
          label: 'Source',
        ),
        _SmallFilterField(
          key: const Key('events-start-field'),
          controller: startController,
          label: 'Start',
        ),
        _SmallFilterField(
          key: const Key('events-end-field'),
          controller: endController,
          label: 'End',
        ),
        FilledButton.icon(
          key: const Key('events-apply-filters-button'),
          onPressed: onApplyFilters,
          icon: const Icon(Icons.filter_alt),
          label: const Text('Apply'),
        ),
      ],
    );
  }
}

class _SmallFilterField extends StatelessWidget {
  const _SmallFilterField({
    super.key,
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.item, required this.onShowDetails});

  final EventFeedItem item;
  final VoidCallback onShowDetails;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bolt),
      title: Text(item.message),
      subtitle: Text('${item.kind.label} - ${item.source} - ${item.severity}'),
      trailing: Wrap(
        spacing: 8,
        children: [
          Text(item.category),
          IconButton(
            key: Key('event-detail-${item.id}-button'),
            tooltip: 'Open event ${item.id}',
            onPressed: onShowDetails,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
    );
  }
}

class _EventPager extends StatelessWidget {
  const _EventPager({
    required this.page,
    required this.onPrevious,
    required this.onNext,
  });

  final EventPage? page;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final current = page;
    if (current == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text('Page ${current.page} of ${_pageCount(current)}'),
          const Spacer(),
          IconButton(
            key: const Key('events-previous-page-button'),
            tooltip: 'Previous page',
            onPressed: current.hasPrevious ? onPrevious : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            key: const Key('events-next-page-button'),
            tooltip: 'Next page',
            onPressed: current.hasNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  int _pageCount(EventPage page) {
    if (page.total == 0) {
      return 1;
    }
    return ((page.total + page.pageSize - 1) / page.pageSize).floor();
  }
}

void _showEventDetails(BuildContext context, EventFeedItem item) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Event details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.message),
          Text(item.eventType),
          Text(item.category),
          Text(item.source),
          Text(item.severity),
          Text(item.occurredAt.toIso8601String()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _EventsError extends StatelessWidget {
  const _EventsError();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Event center unavailable'));
  }
}
