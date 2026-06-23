import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../../../core/widgets/mavra_side_sheet.dart';
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
    _loadQuery(_query, notify: false, clearEvents: false);
  }

  @override
  void didUpdateWidget(covariant EventsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _loadQuery(_query);
    }
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

  void _loadQuery(
    EventQuery query, {
    bool notify = true,
    bool clearEvents = true,
  }) {
    final future = Future<EventPage>.sync(
      () => widget.repository.listEvents(query: query),
    );
    void updateLoadingState() {
      _query = query;
      _error = null;
      _eventsFuture = future;
      if (clearEvents) {
        _page = null;
        _events = const [];
      }
    }

    if (notify && mounted) {
      setState(updateLoadingState);
    } else {
      updateLoadingState();
    }

    _subscribeRealtime(query);

    future
        .then((page) {
          if (mounted && _eventsFuture == future) {
            setState(() {
              _page = page;
              _events = page.items;
            });
          }
        })
        .catchError((Object error) {
          if (mounted && _eventsFuture == future) {
            setState(() {
              _error = error;
            });
          }
        });
  }

  void _subscribeRealtime(EventQuery query) {
    _subscription?.cancel();
    if (query.page != 1) {
      _subscription = null;
      return;
    }
    _subscription = widget.repository.watchEvents(query: query).listen((event) {
      if (!mounted || _events.any((item) => item.id == event.id)) {
        return;
      }
      setState(() {
        final limit = (_page?.pageSize ?? _query.pageSize).clamp(1, 1000);
        _events = [event, ..._events].take(limit).toList();
        final current = _page;
        if (current != null) {
          _page = EventPage(
            items: _events,
            page: current.page,
            pageSize: current.pageSize,
            total: current.total + 1,
          );
        }
      });
    });
  }

  void _setFilter(EventFilter filter) {
    if (_query.filter == filter) {
      return;
    }
    _loadQuery(_queryFromControllers(filter: filter, page: 1));
  }

  void _applyFilters() {
    _loadQuery(_queryFromControllers(page: 1));
  }

  void _setPage(int page) {
    _loadQuery(_query.copyWith(page: page));
  }

  void _setPageSize(int pageSize) {
    _loadQuery(_queryFromControllers(page: 1, pageSize: pageSize));
  }

  void _resetFilters() {
    _eventTypeController.clear();
    _categoryController.clear();
    _severityController.clear();
    _sourceController.clear();
    _keywordController.clear();
    _startController.clear();
    _endController.clear();
    _loadQuery(EventQuery(pageSize: _query.pageSize));
  }

  EventQuery _queryFromControllers({
    EventFilter? filter,
    int? page,
    int? pageSize,
  }) {
    return EventQuery(
      filter: filter ?? _query.filter,
      eventType: _textOrNull(_eventTypeController),
      category: _textOrNull(_categoryController),
      severity: _textOrNull(_severityController),
      source: _textOrNull(_sourceController),
      keyword: _textOrNull(_keywordController),
      startAt: DateTime.tryParse(_startController.text.trim()),
      endAt: DateTime.tryParse(_endController.text.trim()),
      page: page ?? _query.page,
      pageSize: pageSize ?? _query.pageSize,
    );
  }

  String? _textOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<EventPage>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            final loading =
                snapshot.connectionState != ConnectionState.done &&
                _events.isEmpty &&
                _error == null;
            return _EventsContent(
              query: _query,
              events: _events,
              page: _page ?? snapshot.data,
              loading: loading,
              error: _error,
              eventTypeController: _eventTypeController,
              categoryController: _categoryController,
              severityController: _severityController,
              sourceController: _sourceController,
              keywordController: _keywordController,
              startController: _startController,
              endController: _endController,
              onFilterChanged: _setFilter,
              onTextFilterChanged: _applyFilters,
              onResetFilters: _resetFilters,
              onPageChanged: _setPage,
              onPageSizeChanged: _setPageSize,
            );
          },
        ),
      ),
    );
  }
}

class _EventsContent extends StatelessWidget {
  const _EventsContent({
    required this.query,
    required this.events,
    required this.page,
    required this.loading,
    required this.error,
    required this.eventTypeController,
    required this.categoryController,
    required this.severityController,
    required this.sourceController,
    required this.keywordController,
    required this.startController,
    required this.endController,
    required this.onFilterChanged,
    required this.onTextFilterChanged,
    required this.onResetFilters,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final EventQuery query;
  final List<EventFeedItem> events;
  final EventPage? page;
  final bool loading;
  final Object? error;
  final TextEditingController eventTypeController;
  final TextEditingController categoryController;
  final TextEditingController severityController;
  final TextEditingController sourceController;
  final TextEditingController keywordController;
  final TextEditingController startController;
  final TextEditingController endController;
  final ValueChanged<EventFilter> onFilterChanged;
  final VoidCallback onTextFilterChanged;
  final VoidCallback onResetFilters;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return ListView(
          key: Key(wide ? 'events-desktop-layout' : 'events-mobile-layout'),
          padding: EdgeInsets.all(wide ? 24 : 16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _EventsBanner(),
                    const SizedBox(height: 16),
                    _EventFilterToolbar(
                      query: query,
                      eventTypeController: eventTypeController,
                      categoryController: categoryController,
                      severityController: severityController,
                      sourceController: sourceController,
                      keywordController: keywordController,
                      startController: startController,
                      endController: endController,
                      onFilterChanged: onFilterChanged,
                      onTextFilterChanged: onTextFilterChanged,
                      onResetFilters: onResetFilters,
                    ),
                    const SizedBox(height: 16),
                    _EventBody(
                      events: events,
                      page: page,
                      loading: loading,
                      error: error,
                      onPageChanged: onPageChanged,
                      onPageSizeChanged: onPageSizeChanged,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EventsBanner extends StatelessWidget {
  const _EventsBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      key: const Key('events-banner'),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.54),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Events',
              style: text.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Event Center',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Unified audit, runtime, and platform event stream with realtime updates',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventFilterToolbar extends StatelessWidget {
  const _EventFilterToolbar({
    required this.query,
    required this.eventTypeController,
    required this.categoryController,
    required this.severityController,
    required this.sourceController,
    required this.keywordController,
    required this.startController,
    required this.endController,
    required this.onFilterChanged,
    required this.onTextFilterChanged,
    required this.onResetFilters,
  });

  final EventQuery query;
  final TextEditingController eventTypeController;
  final TextEditingController categoryController;
  final TextEditingController severityController;
  final TextEditingController sourceController;
  final TextEditingController keywordController;
  final TextEditingController startController;
  final TextEditingController endController;
  final ValueChanged<EventFilter> onFilterChanged;
  final VoidCallback onTextFilterChanged;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('events-filter-toolbar'),
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 230,
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Kind'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<EventFilter>(
                key: const Key('events-kind-filter'),
                value: query.filter,
                isExpanded: true,
                items: [
                  for (final filter in EventFilter.values)
                    DropdownMenuItem(value: filter, child: Text(filter.label)),
                ],
                onChanged: (filter) {
                  if (filter != null) {
                    onFilterChanged(filter);
                  }
                },
              ),
            ),
          ),
        ),
        _SmallFilterField(
          key: const Key('events-type-field'),
          controller: eventTypeController,
          label: 'Event type',
          onChanged: onTextFilterChanged,
        ),
        _SmallFilterField(
          key: const Key('events-category-field'),
          controller: categoryController,
          label: 'Category',
          onChanged: onTextFilterChanged,
        ),
        SizedBox(
          width: 270,
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Severity'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('events-severity-filter'),
                value: severityController.text,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: '', child: Text('All severity')),
                  DropdownMenuItem(value: 'info', child: Text('Info')),
                  DropdownMenuItem(value: 'warning', child: Text('Warning')),
                  DropdownMenuItem(value: 'error', child: Text('Error')),
                ],
                onChanged: (severity) {
                  severityController.text = severity ?? '';
                  onTextFilterChanged();
                },
              ),
            ),
          ),
        ),
        _SmallFilterField(
          key: const Key('events-source-field'),
          controller: sourceController,
          label: 'Source',
          onChanged: onTextFilterChanged,
        ),
        _SmallFilterField(
          key: const Key('events-keyword-field'),
          controller: keywordController,
          label: 'Keyword',
          width: 220,
          onChanged: onTextFilterChanged,
        ),
        _SmallFilterField(
          key: const Key('events-start-field'),
          controller: startController,
          label: 'Start',
          width: 210,
          onChanged: onTextFilterChanged,
        ),
        _SmallFilterField(
          key: const Key('events-end-field'),
          controller: endController,
          label: 'End',
          width: 210,
          onChanged: onTextFilterChanged,
        ),
        OutlinedButton.icon(
          key: const Key('events-reset-filters-button'),
          onPressed: onResetFilters,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
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
    required this.onChanged,
    this.width = 160,
  });

  final TextEditingController controller;
  final String label;
  final double width;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _EventBody extends StatelessWidget {
  const _EventBody({
    required this.events,
    required this.page,
    required this.loading,
    required this.error,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final List<EventFeedItem> events;
  final EventPage? page;
  final bool loading;
  final Object? error;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return const _EventStatus(
        icon: Icons.error_outline,
        message: 'Event center unavailable',
      );
    }
    if (loading) {
      return const _EventStatus(
        icon: Icons.sync,
        message: 'Loading event stream...',
      );
    }
    if (events.isEmpty) {
      return const _EventStatus(
        icon: Icons.event_busy,
        message: 'No events yet',
      );
    }

    return _EventPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MavraResponsiveDataView<EventFeedItem>(
            rows: events,
            columns: const [
              DataColumn(label: Text('Kind')),
              DataColumn(label: Text('Event Type')),
              DataColumn(label: Text('Message')),
              DataColumn(label: Text('Severity')),
              DataColumn(label: Text('Source')),
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Action')),
            ],
            columnSpacing: 28,
            tableCells: (item) => [
              DataCell(_KindPill(kind: item.kind)),
              DataCell(Text(item.eventType)),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(item.message, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(_SeverityPill(severity: item.severity)),
              DataCell(Text(item.source)),
              DataCell(Text(_formatDateTime(item.occurredAt))),
              DataCell(
                TextButton(
                  key: Key('event-detail-${item.id}-button'),
                  onPressed: () => _showEventDetails(context, item),
                  child: const Text('Details'),
                ),
              ),
            ],
            wideBreakpoint: 860,
            mobileBuilder: (context, item) => _EventTile(item: item),
          ),
          if (page != null) ...[
            const Divider(height: 24),
            _EventPager(
              page: page!,
              onPrevious: () => onPageChanged(page!.page - 1),
              onNext: () => onPageChanged(page!.page + 1),
              onPageSizeChanged: onPageSizeChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.item});

  final EventFeedItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      key: Key('event-tile-${item.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _KindPill(kind: item.kind),
              _SeverityPill(severity: item.severity),
              Text(
                _formatDateTime(item.occurredAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.eventType,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(item.message),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.source,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                key: Key('event-detail-${item.id}-button'),
                onPressed: () => _showEventDetails(context, item),
                child: const Text('Details'),
              ),
            ],
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
    required this.onPageSizeChanged,
  });

  final EventPage page;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        Text('Total ${page.total} events'),
        Text('Page ${page.page} of ${_pageCount(page)}'),
        SizedBox(
          width: 120,
          child: DropdownButton<int>(
            key: const Key('events-page-size-dropdown'),
            value: page.pageSize,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 10, child: Text('10 / page')),
              DropdownMenuItem(value: 20, child: Text('20 / page')),
              DropdownMenuItem(value: 50, child: Text('50 / page')),
            ],
            onChanged: (value) {
              if (value != null) {
                onPageSizeChanged(value);
              }
            },
          ),
        ),
        IconButton(
          key: const Key('events-previous-page-button'),
          tooltip: 'Previous page',
          onPressed: page.hasPrevious ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          key: const Key('events-next-page-button'),
          tooltip: 'Next page',
          onPressed: page.hasNext ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  int _pageCount(EventPage page) {
    if (page.total == 0) {
      return 1;
    }
    return (page.total / page.pageSize).ceil();
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({required this.kind});

  final EventKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (kind) {
      EventKind.audit => colors.secondary,
      EventKind.system => colors.primary,
      EventKind.platform => colors.error,
    };
    return _EventPill(label: kind.badgeLabel, color: color);
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (severity) {
      'warning' => colors.tertiary,
      'error' => colors.error,
      _ => colors.onSurfaceVariant,
    };
    return _EventPill(label: severity.toUpperCase(), color: color);
  }
}

class _EventPill extends StatelessWidget {
  const _EventPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.48)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EventPanel extends StatelessWidget {
  const _EventPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _EventStatus extends StatelessWidget {
  const _EventStatus({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _EventPanel(
      child: SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}

void _showEventDetails(BuildContext context, EventFeedItem item) {
  MavraSideSheet.show<void>(
    context,
    title: 'Event Details',
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'ID', value: item.id),
            _DetailRow(label: 'Kind', value: item.kind.name),
            _DetailRow(label: 'Event Type', value: item.eventType),
            _DetailRow(label: 'Category', value: item.category),
            _DetailRow(label: 'Severity', value: item.severity),
            _DetailRow(label: 'Status', value: item.status ?? '-'),
            _DetailRow(label: 'Source', value: item.source),
            _DetailRow(label: 'User ID', value: item.userId?.toString() ?? '-'),
            _DetailRow(
              label: 'Entity',
              value: '${item.entityType ?? '-'} / ${item.entityId ?? '-'}',
            ),
            _DetailRow(label: 'Trace ID', value: item.traceId ?? '-'),
            _DetailRow(
              label: 'Occurred At',
              value: _formatDateTime(item.occurredAt),
            ),
            _DetailRow(label: 'Message', value: item.message),
            const SizedBox(height: 12),
            Text(
              'Payload',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _formatPayload(item.payload),
                  key: const Key('event-detail-payload'),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }
}

String _formatPayload(Map<String, Object?>? payload) {
  if (payload == null) {
    return 'null';
  }
  return const JsonEncoder.withIndent('  ').convert(payload);
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute:$second';
}
