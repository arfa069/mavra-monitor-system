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

  @override
  Future<ProductsSnapshot> loadProducts() async {
    final productsResponse = await _productsApi.productsListProducts(size: 50);
    final products = productsResponse.data?.items.toList() ?? const [];

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
          ProductItem(
            id: product.id,
            title: product.title ?? 'Product #${product.id}',
            platform: product.platform,
            currentPrice: _latestPrice(product.id, history),
            url: product.url,
            enabled: product.active,
          ),
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
    );
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
