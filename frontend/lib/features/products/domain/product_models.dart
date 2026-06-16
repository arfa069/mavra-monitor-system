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

class ProductsSnapshot {
  const ProductsSnapshot({
    required this.products,
    required this.history,
    required this.bindings,
    required this.cronConfigs,
    required this.crawlLogs,
  });

  const ProductsSnapshot.empty()
    : products = const [],
      history = const [],
      bindings = const [],
      cronConfigs = const [],
      crawlLogs = const [];

  final List<ProductItem> products;
  final List<PriceHistoryPoint> history;
  final List<ProductProfileBinding> bindings;
  final List<ProductCronConfig> cronConfigs;
  final List<ProductCrawlLog> crawlLogs;
}

abstract class ProductRepository {
  Future<ProductsSnapshot> loadProducts();

  Future<void> saveProduct(ProductDraft draft, {int? productId});

  Future<void> importProducts(PickedFileReference file);
}
