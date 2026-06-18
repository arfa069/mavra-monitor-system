import 'dart:convert';

import 'package:built_collection/built_collection.dart';
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
      const ProductListQuery(page: 1, pageSize: 50),
    );
    final products = productPage.items;

    final firstProductId = products.isEmpty ? null : products.first.id;
    final results = await Future.wait([
      if (firstProductId != null)
        _productsApi.productsGetProductHistory(productId: firstProductId),
      _productsApi.productsListProductProfileBindings(),
      _productsApi.productsListProductCronConfigs(),
      _productsCrawlApi.productsCrawlGetCrawlLogs(limit: 20),
    ]);

    final history = firstProductId == null
        ? <generated.PriceHistoryResponse>[]
        : ((results[0].data as BuiltList<generated.PriceHistoryResponse>?)
                  ?.toList() ??
              const []);
    final offset = firstProductId == null ? 0 : 1;
    final bindings =
        (results[offset].data
                as BuiltList<generated.ProductPlatformProfileBindingResponse>?)
            ?.toList() ??
        const [];
    final cronConfigs =
        (results[offset + 1].data
                as BuiltList<generated.ProductPlatformCronResponse>?)
            ?.toList() ??
        const [];
    final logs =
        (results[offset + 2].data as BuiltList<generated.CrawlLogResponse>?)
            ?.toList() ??
        const [];

    return ProductsSnapshot(
      products: [
        for (final product in products)
          product.copyWith(currentPrice: _latestPrice(product.id, history)),
      ],
      history: [
        for (final point in history)
          PriceHistoryPoint(
            label: _shortDate(point.scrapedAt),
            price: _formatPrice(point.price, point.currency),
          ),
      ],
      bindings: [
        for (final binding in bindings)
          ProductProfileBinding(
            platform: binding.platform,
            profileName: binding.profileKey ?? 'Unbound',
          ),
      ],
      cronConfigs: [
        for (final cron in cronConfigs)
          ProductCronConfig(
            platform: cron.platform,
            cron: cron.cronExpression ?? 'Disabled',
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
            ..active = draft.enabled,
        ),
      );
      return;
    }

    await _alertsApi.alertsUpdateAlert(
      alertId: alertId,
      alertUpdate: generated.AlertUpdate(
        (builder) => builder.active = draft.enabled,
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
  Future<void> saveProduct(ProductDraft draft, {int? productId}) async {
    if (productId == null) {
      await _productsApi.productsCreateProduct(
        productCreate: generated.ProductCreate(
          (builder) => builder
            ..title = draft.title
            ..url = draft.url
            ..platform = draft.platform
            ..active = true,
        ),
      );
      return;
    }

    await _productsApi.productsUpdateProduct(
      productId: productId,
      productUpdate: generated.ProductUpdate(
        (builder) => builder
          ..title = draft.title
          ..url = draft.url
          ..platform = draft.platform
          ..active = true,
      ),
    );
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

  static String _latestPrice(
    int productId,
    List<generated.PriceHistoryResponse> history,
  ) {
    final matches = history.where((point) => point.productId == productId);
    if (matches.isEmpty) {
      return '-';
    }
    final latest = matches.reduce(
      (a, b) => a.scrapedAt.isAfter(b.scrapedAt) ? a : b,
    );
    return _formatPrice(latest.price, latest.currency);
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
}
