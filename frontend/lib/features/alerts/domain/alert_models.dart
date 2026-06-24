enum AlertFilter { all, active, inactive }

class AlertItem {
  const AlertItem({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.alertType,
    required this.thresholdLabel,
    required this.active,
    required this.updatedAt,
    this.lastNotifiedPrice,
  });

  final int id;
  final int productId;
  final String productTitle;
  final String alertType;
  final String thresholdLabel;
  final bool active;
  final DateTime updatedAt;
  final String? lastNotifiedPrice;
}

abstract class AlertRepository {
  Future<List<AlertItem>> listAlerts({AlertFilter filter = AlertFilter.all});

  Stream<AlertItem> watchAlerts({AlertFilter filter = AlertFilter.all});
}
