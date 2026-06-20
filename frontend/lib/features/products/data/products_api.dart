import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../../../core/files/file_service.dart';
import '../domain/product_models.dart';

class GeneratedProductRepository implements ProductRepository {
  GeneratedProductRepository({
    required AppConfig config,
    generated.MavraApi? client,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           );

  final generated.MavraApi _client;

  generated.ProductsApi get _productsApi => _client.getProductsApi();

  generated.ProductsCrawlApi get _productsCrawlApi =>
      _client.getProductsCrawlApi();

  generated.AlertsApi get _alertsApi => _client.getAlertsApi();

  @override
  Future<ProductsSnapshot> loadProducts() async {
    final productPage = await listProducts(
      const ProductListQuery(page: 1, pageSize: 15),
    );

    final results = await Future.wait([
      _productsApi.productsListProductCronConfigs(),
      _productsCrawlApi.productsCrawlGetCrawlLogs(limit: 20),
      _alertsApi.alertsListAlerts(),
    ]);

    final cronConfigs =
        (results[0].data as BuiltList<generated.ProductPlatformCronResponse>?)
            ?.toList() ??
        const [];
    final logs =
        (results[1].data as BuiltList<generated.CrawlLogResponse>?)?.toList() ??
        const [];
    final alerts =
        (results[2].data as BuiltList<generated.AlertResponse>?)?.toList() ??
        const [];

    return ProductsSnapshot(
      products: productPage.items,
      history: const [],
      bindings: const [],
      cronConfigs: [
        for (final cron in cronConfigs)
          ProductCronConfig(
            platform: cron.platform,
            cron: cron.cronExpression ?? 'Disabled',
            timezone: cron.cronTimezone,
            configured: cron.cronExpression != null,
          ),
      ],
      crawlLogs: [
        for (final log in logs)
          ProductCrawlLog(
            message: log.errorMessage ?? _crawlLogMessage(log),
            status: log.status ?? 'unknown',
            createdAt: log.timestamp,
          ),
      ],
      alerts: [
        for (final alert in alerts)
          ProductAlertInfo(
            id: alert.id,
            productId: alert.productId,
            active: alert.active,
            thresholdPercent: _parseDouble(alert.thresholdPercent) ?? 5,
          ),
      ],
      page: productPage,
    );
  }

  @override
  Future<ProductPageState> listProducts(ProductListQuery query) async {
    final response = await _productsApi.productsListProducts(
      keyword: query.keyword,
      platform: query.platform,
      active: query.active,
      page: query.page,
      size: query.pageSize,
    );
    final data = response.data;
    return ProductPageState(
      items: [
        for (final product in data?.items.toList() ?? const [])
          _mapProduct(product),
      ],
      page: data?.page ?? query.page,
      pageSize: data?.pageSize ?? query.pageSize,
      total: data?.total ?? 0,
    );
  }

  @override
  Future<List<PriceHistoryPoint>> getProductHistory(
    int productId, {
    int days = 30,
  }) async {
    final response = await _productsApi.productsGetProductHistory(
      productId: productId,
      days: days,
    );
    return [
      for (final point in response.data?.toList() ?? const [])
        PriceHistoryPoint(
          label: _shortDate(point.scrapedAt),
          price: _formatPrice(point.price, point.currency),
        ),
    ];
  }

  @override
  Future<void> saveAlert(
    int productId,
    ProductAlertDraft draft, {
    int? alertId,
  }) async {
    if (alertId == null) {
      await _alertsApi.alertsCreateAlert(
        alertCreate: generated.AlertCreate(
          (builder) => builder
            ..productId = productId
            ..active = draft.enabled
            ..thresholdPercent = _thresholdPercent(
              draft.thresholdPercent,
            ).toBuilder(),
        ),
      );
      return;
    }

    await _alertsApi.alertsUpdateAlert(
      alertId: alertId,
      alertUpdate: generated.AlertUpdate(
        (builder) => builder
          ..active = draft.enabled
          ..thresholdPercent = _thresholdPercentUpdate(
            draft.thresholdPercent,
          ).toBuilder(),
      ),
    );
  }

  @override
  Future<List<ProductPlatformProfileBinding>> listProfileBindings() async {
    final response = await _productsApi.productsListProductProfileBindings();
    return [
      for (final binding in response.data?.toList() ?? const [])
        ProductPlatformProfileBinding(
          platform: binding.platform,
          profileKey: binding.profileKey,
          profileStatus: binding.profileStatus,
          profileLastError: binding.profileLastError,
        ),
    ];
  }

  @override
  Future<void> saveProfileBinding({
    required String platform,
    required String profileKey,
  }) async {
    await _productsApi.productsUpsertProductProfileBinding(
      platform: platform,
      productPlatformProfileBindingUpdate:
          generated.ProductPlatformProfileBindingUpdate(
            (builder) => builder.profileKey = profileKey,
          ),
    );
  }

  @override
  Future<void> deleteProfileBinding(String platform) async {
    await _productsApi.productsDeleteProductProfileBinding(platform: platform);
  }

  @override
  Future<List<ProductCrawlLog>> listCrawlLogs({
    int? productId,
    String? status,
  }) async {
    final response = await _productsCrawlApi.productsCrawlGetCrawlLogs(
      productId: productId,
      status: status,
      limit: 50,
    );
    return [
      for (final log in response.data?.toList() ?? const [])
        ProductCrawlLog(
          message: log.errorMessage ?? _crawlLogMessage(log),
          status: log.status ?? 'unknown',
          createdAt: log.timestamp,
        ),
    ];
  }

  @override
  Future<List<ProductCronConfig>> listProductSchedules() async {
    final response = await _productsApi.productsListProductCronConfigs();
    return [
      for (final cron in response.data?.toList() ?? const [])
        ProductCronConfig(
          platform: cron.platform,
          cron: cron.cronExpression ?? 'Disabled',
          timezone: cron.cronTimezone,
          configured: cron.cronExpression != null,
        ),
    ];
  }

  @override
  Future<void> saveProductSchedule({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {
    await _productsApi.productsCreateProductCronConfig(
      productPlatformCronCreate: generated.ProductPlatformCronCreate(
        (builder) => builder
          ..platform = platform
          ..cronExpression = cronExpression
          ..cronTimezone = timezone,
      ),
    );
  }

  @override
  Future<void> deleteProductSchedule(String platform) async {
    await _productsApi.productsDeleteProductCronConfig(platform: platform);
  }

  @override
  Future<int?> saveProduct(ProductDraft draft, {int? productId}) async {
    if (productId == null) {
      final response = await _productsApi.productsCreateProduct(
        productCreate: generated.ProductCreate(
          (builder) => builder
            ..title = draft.title
            ..url = draft.url
            ..platform = draft.platform
            ..active = draft.active,
        ),
      );
      return response.data?.id;
    }

    await _productsApi.productsUpdateProduct(
      productId: productId,
      productUpdate: generated.ProductUpdate(
        (builder) => builder
          ..title = draft.title
          ..url = draft.url
          ..platform = draft.platform
          ..active = draft.active,
      ),
    );
    return productId;
  }

  @override
  Future<void> importProducts(PickedFileReference file) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw UnsupportedError('Product imports require readable file bytes.');
    }
    final rows = const LineSplitter()
        .convert(utf8.decode(bytes))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(_parseBatchItem)
        .whereType<generated.ProductBatchCreateItem>()
        .toList();

    if (rows.isEmpty) {
      throw const FormatException('No product rows found in import file.');
    }

    await _productsApi.productsBatchCreateProducts(
      productBatchCreate: generated.ProductBatchCreate(
        (builder) => builder.items.replace(rows),
      ),
    );
  }

  @override
  Future<void> deleteProduct(int productId) async {
    await _productsApi.productsDeleteProduct(productId: productId);
  }

  @override
  Future<void> batchDeleteProducts(List<int> productIds) async {
    if (productIds.isEmpty) {
      return;
    }
    await _productsApi.productsBatchDeleteProducts(
      productBatchDelete: generated.ProductBatchDelete(
        (builder) => builder.ids.replace(productIds),
      ),
    );
  }

  @override
  Future<void> requestCrawlNow() async {
    await _productsCrawlApi.productsCrawlCrawlNow();
  }

  static generated.ProductBatchCreateItem? _parseBatchItem(String row) {
    final parts = row.split(',').map((part) => part.trim()).toList();
    if (parts.first.toLowerCase() == 'url') {
      return null;
    }
    final url = parts.first;
    if (url.isEmpty) {
      return null;
    }
    return generated.ProductBatchCreateItem(
      (builder) => builder
        ..url = url
        ..platform = (parts.length > 1 && parts[1].isNotEmpty) ? parts[1] : null
        ..title = (parts.length > 2 && parts[2].isNotEmpty) ? parts[2] : null,
    );
  }

  static ProductItem _mapProduct(generated.ProductResponse product) {
    return ProductItem(
      id: product.id,
      title: product.title ?? 'Product #${product.id}',
      platform: product.platform,
      currentPrice: '-',
      url: product.url,
      enabled: product.active,
    );
  }

  static String _formatPrice(String price, String currency) {
    if (currency == 'CNY') {
      return '¥$price';
    }
    return '$currency $price';
  }

  static String _shortDate(DateTime value) {
    return '${value.month}/${value.day}';
  }

  static double? _parseDouble(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value);
  }

  static String _crawlLogMessage(generated.CrawlLogResponse log) {
    final platform = log.platform ?? 'crawler';
    final price = log.price == null ? '' : ' at ${log.price}';
    return '$platform ${log.status ?? 'updated'}$price';
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }

  static generated.ThresholdPercent _thresholdPercent(double value) {
    return generated.standardSerializers.deserialize(
          value,
          specifiedType: const FullType(generated.ThresholdPercent),
        )
        as generated.ThresholdPercent;
  }

  static generated.ThresholdPercent1 _thresholdPercentUpdate(double value) {
    return generated.standardSerializers.deserialize(
          value,
          specifiedType: const FullType(generated.ThresholdPercent1),
        )
        as generated.ThresholdPercent1;
  }
}
