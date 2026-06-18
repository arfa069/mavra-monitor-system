import '../../../core/files/file_service.dart';

class ProductItem {
  const ProductItem({
    required this.id,
    required this.title,
    required this.platform,
    required this.currentPrice,
    required this.url,
    required this.enabled,
  });

  final int id;
  final String title;
  final String platform;
  final String currentPrice;
  final String url;
  final bool enabled;

  ProductItem copyWith({
    String? title,
    String? platform,
    String? currentPrice,
    String? url,
    bool? enabled,
  }) {
    return ProductItem(
      id: id,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      currentPrice: currentPrice ?? this.currentPrice,
      url: url ?? this.url,
      enabled: enabled ?? this.enabled,
    );
  }
}

class PriceHistoryPoint {
  const PriceHistoryPoint({required this.label, required this.price});

  final String label;
  final String price;
}

class ProductProfileBinding {
  const ProductProfileBinding({
    required this.platform,
    required this.profileName,
  });

  final String platform;
  final String profileName;
}

class ProductPlatformProfileBinding {
  const ProductPlatformProfileBinding({
    required this.platform,
    this.profileKey,
    this.profileStatus,
    this.profileLastError,
  });

  final String platform;
  final String? profileKey;
  final String? profileStatus;
  final String? profileLastError;
}

class ProductCronConfig {
  const ProductCronConfig({required this.platform, required this.cron});

  final String platform;
  final String cron;
}

class ProductCrawlLog {
  const ProductCrawlLog({
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String message;
  final String status;
  final DateTime createdAt;
}

class ProductDraft {
  const ProductDraft({
    required this.title,
    required this.url,
    required this.platform,
  });

  final String title;
  final String url;
  final String platform;
}

class ProductListQuery {
  const ProductListQuery({
    this.keyword,
    this.platform,
    this.active,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? keyword;
  final String? platform;
  final bool? active;
  final int page;
  final int pageSize;
}

class ProductPageState {
  const ProductPageState({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<ProductItem> items;
  final int page;
  final int pageSize;
  final int total;
}

class ProductAlertDraft {
  const ProductAlertDraft({
    required this.enabled,
    required this.alertType,
    required this.thresholdPercent,
  });

  final bool enabled;
  final String alertType;
  final double thresholdPercent;
}

class ProductsSnapshot {
  const ProductsSnapshot({
    required this.products,
    required this.history,
    required this.bindings,
    required this.cronConfigs,
    required this.crawlLogs,
    ProductPageState? page,
  }) : page =
           page ??
           const ProductPageState(items: [], page: 1, pageSize: 20, total: 0);

  const ProductsSnapshot.empty()
    : products = const [],
      history = const [],
      bindings = const [],
      cronConfigs = const [],
      crawlLogs = const [],
      page = const ProductPageState(items: [], page: 1, pageSize: 20, total: 0);

  final List<ProductItem> products;
  final List<PriceHistoryPoint> history;
  final List<ProductProfileBinding> bindings;
  final List<ProductCronConfig> cronConfigs;
  final List<ProductCrawlLog> crawlLogs;
  final ProductPageState page;
}

abstract class ProductRepository {
  Future<ProductsSnapshot> loadProducts();

  Future<ProductPageState> listProducts(ProductListQuery query);

  Future<List<PriceHistoryPoint>> getProductHistory(
    int productId, {
    int days = 30,
  });

  Future<void> saveAlert(
    int productId,
    ProductAlertDraft draft, {
    int? alertId,
  });

  Future<List<ProductPlatformProfileBinding>> listProfileBindings();

  Future<void> saveProfileBinding({
    required String platform,
    required String profileKey,
  });

  Future<void> deleteProfileBinding(String platform);

  Future<List<ProductCrawlLog>> listCrawlLogs({int? productId, String? status});

  Future<List<ProductCronConfig>> listProductSchedules();

  Future<void> saveProductSchedule({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  });

  Future<void> deleteProductSchedule(String platform);

  Future<void> saveProduct(ProductDraft draft, {int? productId});

  Future<void> importProducts(PickedFileReference file);

  Future<void> deleteProduct(int productId);

  Future<void> batchDeleteProducts(List<int> productIds);

  Future<void> requestCrawlNow();
}
