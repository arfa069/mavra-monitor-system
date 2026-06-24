class SmartHomeConfig {
  const SmartHomeConfig({
    required this.baseUrl,
    required this.enabled,
    required this.lastStatus,
    required this.tokenConfigured,
  });

  final String baseUrl;
  final bool enabled;
  final String? lastStatus;
  final bool tokenConfigured;
}

class SmartHomeSummary {
  const SmartHomeSummary({
    required this.configured,
    required this.connected,
    required this.activeCount,
    required this.unavailableCount,
  });

  final bool configured;
  final bool connected;
  final int activeCount;
  final int unavailableCount;
}

class SmartHomeEntityItem {
  const SmartHomeEntityItem({
    required this.domain,
    required this.entityId,
    required this.name,
    required this.state,
    required this.area,
    required this.available,
    this.attributes = const {},
  });

  final String domain;
  final String entityId;
  final String name;
  final String state;
  final String? area;
  final bool available;
  final Map<String, Object?> attributes;

  SmartHomeEntityItem copyWith({
    String? domain,
    String? entityId,
    String? name,
    String? state,
    String? area,
    bool? available,
    Map<String, Object?>? attributes,
  }) {
    return SmartHomeEntityItem(
      domain: domain ?? this.domain,
      entityId: entityId ?? this.entityId,
      name: name ?? this.name,
      state: state ?? this.state,
      area: area ?? this.area,
      available: available ?? this.available,
      attributes: attributes ?? this.attributes,
    );
  }
}

class SmartHomeSnapshot {
  const SmartHomeSnapshot({
    required this.config,
    required this.summary,
    required this.entities,
    required this.canControl,
    required this.canConfigure,
    required this.realtimeConnected,
  });

  const SmartHomeSnapshot.empty()
    : config = null,
      summary = const SmartHomeSummary(
        configured: false,
        connected: false,
        activeCount: 0,
        unavailableCount: 0,
      ),
      entities = const [],
      canControl = true,
      canConfigure = true,
      realtimeConnected = false;

  final SmartHomeConfig? config;
  final SmartHomeSummary summary;
  final List<SmartHomeEntityItem> entities;
  final bool canControl;
  final bool canConfigure;
  final bool realtimeConnected;
}

class SmartHomeConfigDraft {
  const SmartHomeConfigDraft({
    required this.baseUrl,
    required this.enabled,
    required this.token,
  });

  final String baseUrl;
  final bool enabled;
  final String? token;
}

class SmartHomeServiceDraft {
  const SmartHomeServiceDraft({
    required this.entityId,
    required this.service,
    this.serviceData = const {},
  });

  final String entityId;
  final String service;
  final Map<String, Object?> serviceData;
}

class SmartHomeServiceResult {
  const SmartHomeServiceResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}

abstract class SmartHomeRepository {
  Future<SmartHomeSnapshot> loadSmartHome();

  Stream<List<SmartHomeEntityItem>> watchEntities();

  Future<void> saveConfig(SmartHomeConfigDraft draft);

  Future<SmartHomeServiceResult> testConfig(SmartHomeConfigDraft draft);

  Future<SmartHomeServiceResult> callService(SmartHomeServiceDraft draft);
}
