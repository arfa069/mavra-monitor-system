import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_scaffold.dart';
import '../domain/alert_models.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key, required this.repository});

  final AlertRepository repository;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  AlertFilter _filter = AlertFilter.all;
  Future<List<AlertItem>>? _alertsFuture;
  List<AlertItem> _alerts = const [];
  Object? _error;
  StreamSubscription<AlertItem>? _subscription;
  int _loadRequestId = 0;

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
    final requestId = ++_loadRequestId;
    final future = Future.sync(
      () => widget.repository.listAlerts(filter: _filter),
    );
    setState(() {
      _error = null;
      _alertsFuture = future;
    });
    future
        .then((alerts) {
          if (mounted && requestId == _loadRequestId) {
            setState(() {
              _alerts = alerts;
            });
          }
        })
        .catchError((Object error) {
          if (mounted && requestId == _loadRequestId) {
            setState(() {
              _error = error;
            });
          }
        });
    _subscription?.cancel();
    _subscription = widget.repository.watchAlerts(filter: _filter).listen((
      alert,
    ) {
      if (mounted) {
        setState(() {
          _alerts = [alert, ..._alerts.where((item) => item.id != alert.id)];
        });
      }
    });
  }

  void _setFilter(AlertFilter filter) {
    if (_filter == filter) {
      return;
    }
    setState(() {
      _filter = filter;
      _alerts = const [];
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
        selectedIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 1:
              context.go('/events');
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
                  'Alerts',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                SegmentedButton<AlertFilter>(
                  segments: const [
                    ButtonSegment(value: AlertFilter.all, label: Text('All')),
                    ButtonSegment(
                      value: AlertFilter.active,
                      label: Text('Active'),
                    ),
                    ButtonSegment(
                      value: AlertFilter.inactive,
                      label: Text('Inactive'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (selection) =>
                      _setFilter(selection.single),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<AlertItem>>(
                    future: _alertsFuture,
                    builder: (context, snapshot) {
                      if (_error != null) {
                        return const _AlertsError();
                      }
                      if (snapshot.connectionState != ConnectionState.done &&
                          _alerts.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (_alerts.isEmpty) {
                        return const Center(
                          child: Text('No alerts configured'),
                        );
                      }
                      return ListView.separated(
                        itemCount: _alerts.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _AlertTile(item: _alerts[index]),
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

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.item});

  final AlertItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(item.active ? Icons.notifications_active : Icons.pause),
      title: Text(item.productTitle),
      subtitle: Text('${item.alertType} - ${item.thresholdLabel}'),
      trailing: Text(item.active ? 'Active' : 'Inactive'),
    );
  }
}

class _AlertsError extends StatelessWidget {
  const _AlertsError();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Alerts unavailable'));
  }
}
