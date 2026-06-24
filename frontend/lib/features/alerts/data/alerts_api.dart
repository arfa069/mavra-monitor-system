import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../../../core/realtime/realtime_client.dart';
import '../domain/alert_models.dart';

class GeneratedAlertRepository implements AlertRepository {
  GeneratedAlertRepository({
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

  generated.AlertsApi get _alertsApi => _client.getAlertsApi();

  @override
  Future<List<AlertItem>> listAlerts({
    AlertFilter filter = AlertFilter.all,
  }) async {
    final response = await _alertsApi.alertsListAlerts();
    return [
      for (final alert in response.data ?? <generated.AlertResponse>[])
        _mapAlert(alert),
    ].where((alert) {
      return switch (filter) {
        AlertFilter.all => true,
        AlertFilter.active => alert.active,
        AlertFilter.inactive => !alert.active,
      };
    }).toList();
  }

  @override
  Stream<AlertItem> watchAlerts({AlertFilter filter = AlertFilter.all}) {
    return _realtimeClient.connect('alerts').map(_alertFromRealtime).where((
      alert,
    ) {
      return switch (filter) {
        AlertFilter.all => true,
        AlertFilter.active => alert.active,
        AlertFilter.inactive => !alert.active,
      };
    });
  }

  AlertItem _mapAlert(generated.AlertResponse response) {
    return AlertItem(
      id: response.id,
      productId: response.productId,
      productTitle: 'Product #${response.productId}',
      alertType: response.alertType,
      thresholdLabel: response.thresholdPercent ?? '-',
      active: response.active,
      updatedAt: response.updatedAt,
      lastNotifiedPrice: response.lastNotifiedPrice,
    );
  }

  AlertItem _alertFromRealtime(RealtimeMessage message) {
    final payload = message.payload;
    final id = int.tryParse(payload['id']?.toString() ?? '') ?? 0;
    final productId =
        int.tryParse(payload['product_id']?.toString() ?? '') ?? id;
    return AlertItem(
      id: id,
      productId: productId,
      productTitle:
          payload['product_title']?.toString() ?? 'Product #$productId',
      alertType: payload['alert_type']?.toString() ?? 'price_drop',
      thresholdLabel: payload['threshold_percent']?.toString() ?? '-',
      active: payload['active'] == false ? false : true,
      updatedAt:
          DateTime.tryParse(payload['updated_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      lastNotifiedPrice: payload['last_notified_price']?.toString(),
    );
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
