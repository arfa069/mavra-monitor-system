import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mavra_page_banner.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../../../core/widgets/mavra_side_sheet.dart';
import '../../../core/widgets/mavra_style_helpers.dart';
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
  Timer? _filterDebounce;
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
    _filterDebounce?.cancel();
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
    _filterDebounce?.cancel();
    _loadQuery(_queryFromControllers(page: 1));
  }

  void _scheduleApplyFilters() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _applyFilters();
      }
    });
  }

  void _setPage(int page) {
    _loadQuery(_query.copyWith(page: page));
  }

  void _setPageSize(int pageSize) {
    _loadQuery(_queryFromControllers(page: 1, pageSize: pageSize));
  }

  void _resetFilters() {
    _filterDebounce?.cancel();
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
              onTextFilterChanged: _scheduleApplyFilters,
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
                    const MavraPageBanner(
                      key: Key('events-banner'),
                      accentColor: AppTheme.brandMagenta,
                      eyebrow: 'System Events',
                      title: 'Event Center',
                      subtitle:
                          'Unified audit, runtime, and platform event stream with realtime updates',
                    ),
                    const SizedBox(height: 20),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return _CompactEventFilters(
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
          );
        }
        return Wrap(
          key: const Key('events-filter-toolbar'),
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _KindFilter(
              query: query,
              width: 230,
              onFilterChanged: onFilterChanged,
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
            _SeverityFilter(
              controller: severityController,
              width: 270,
              onChanged: onTextFilterChanged,
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
            SizedBox(
              width: 92,
              height: 40,
              child: MavraFilterButton.outlined(
                key: const Key('events-reset-filters-button'),
                onPressed: onResetFilters,
                icon: Icons.refresh,
                label: 'Reset',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompactEventFilters extends StatelessWidget {
  const _CompactEventFilters({
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
    return Column(
      key: const Key('events-filter-toolbar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _KindFilter(
                query: query,
                onFilterChanged: onFilterChanged,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SeverityFilter(
                controller: severityController,
                onChanged: onTextFilterChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SmallFilterField(
          key: const Key('events-keyword-field'),
          controller: keywordController,
          label: 'Keyword',
          width: double.infinity,
          onChanged: onTextFilterChanged,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 130,
              height: 40,
              child: MavraFilterButton.outlined(
                key: const Key('events-more-filters-button'),
                onPressed: () => _openMoreFilters(context),
                icon: Icons.tune,
                label: 'More filters',
              ),
            ),
            SizedBox(
              width: 92,
              height: 40,
              child: MavraFilterButton.outlined(
                key: const Key('events-reset-filters-button'),
                onPressed: onResetFilters,
                icon: Icons.refresh,
                label: 'Reset',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openMoreFilters(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('More filters'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SmallFilterField(
                  key: const Key('events-type-field'),
                  controller: eventTypeController,
                  label: 'Event type',
                  width: double.infinity,
                  onChanged: onTextFilterChanged,
                ),
                const SizedBox(height: 8),
                _SmallFilterField(
                  key: const Key('events-category-field'),
                  controller: categoryController,
                  label: 'Category',
                  width: double.infinity,
                  onChanged: onTextFilterChanged,
                ),
                const SizedBox(height: 8),
                _SmallFilterField(
                  key: const Key('events-source-field'),
                  controller: sourceController,
                  label: 'Source',
                  width: double.infinity,
                  onChanged: onTextFilterChanged,
                ),
                const SizedBox(height: 8),
                _SmallFilterField(
                  key: const Key('events-start-field'),
                  controller: startController,
                  label: 'Start',
                  width: double.infinity,
                  onChanged: onTextFilterChanged,
                ),
                const SizedBox(height: 8),
                _SmallFilterField(
                  key: const Key('events-end-field'),
                  controller: endController,
                  label: 'End',
                  width: double.infinity,
                  onChanged: onTextFilterChanged,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onResetFilters();
              Navigator.of(context).pop();
            },
            style: MavraButtonStyle.compactText(context: context),
            child: const Text('Reset'),
          ),
          FilledButton(
            onPressed: () {
              onTextFilterChanged();
              Navigator.of(context).pop();
            },
            style: MavraButtonStyle.compactFilled(context: context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _KindFilter extends StatelessWidget {
  const _KindFilter({
    required this.query,
    required this.onFilterChanged,
    this.width,
  });

  final EventQuery query;
  final ValueChanged<EventFilter> onFilterChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: DropdownButtonFormField<EventFilter>(
        key: const Key('events-kind-filter'),
        initialValue: query.filter,
        isExpanded: true,
        decoration: MavraInputStyle.filterInput(
          context: context,
          label: 'Kind',
        ),
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
    );
  }
}

class _SeverityFilter extends StatelessWidget {
  const _SeverityFilter({
    required this.controller,
    required this.onChanged,
    this.width,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: DropdownButtonFormField<String>(
        key: const Key('events-severity-filter'),
        initialValue: _severityValue(controller.text),
        isExpanded: true,
        decoration: MavraInputStyle.filterInput(
          context: context,
          label: 'Severity',
        ),
        items: const [
          DropdownMenuItem(value: '', child: Text('All severity')),
          DropdownMenuItem(value: 'info', child: Text('Info')),
          DropdownMenuItem(value: 'warning', child: Text('Warning')),
          DropdownMenuItem(value: 'error', child: Text('Error')),
        ],
        onChanged: (severity) {
          controller.text = severity ?? '';
          onChanged();
        },
      ),
    );
  }
}

String _severityValue(String value) {
  return const {'', 'info', 'warning', 'error'}.contains(value) ? value : '';
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
      height: 40,
      child: TextField(
        controller: controller,
        decoration: MavraInputStyle.filterInput(context: context, label: label),
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
            rowKey: (item) => ValueKey('event-${item.id}'),
            columns: const [
              DataColumn(label: Text('Kind')),
              DataColumn(label: Text('Event Type')),
              DataColumn(label: Text('Message')),
              DataColumn(label: Text('Severity')),
              DataColumn(label: Text('Source')),
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Action')),
            ],
            columnSpacing: 12,
            tableCells: (item) => [
              DataCell(_KindPill(kind: item.kind)),
              DataCell(Text(item.eventType)),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(item.message, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(_SeverityPill(severity: item.severity)),
              DataCell(Text(item.source)),
              DataCell(Text(_formatDateTime(item.occurredAt))),
              DataCell(
                IconButton(
                  key: Key('event-detail-${item.id}-button'),
                  tooltip: 'Details',
                  style: MavraButtonStyle.rowIconButton(context: context),
                  onPressed: () => _showEventDetails(context, item),
                  icon: const Icon(Icons.notes, size: 18),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return DecoratedBox(
          decoration: MavraTableStyle.panelDecoration(context),
          child: Padding(padding: EdgeInsets.all(wide ? 16 : 12), child: child),
        );
      },
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
