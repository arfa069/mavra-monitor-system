import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/files/file_service.dart';
import 'package:mavra_frontend/core/widgets/mavra_chart.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';
import 'package:mavra_frontend/features/products/domain/product_models.dart';
import 'package:mavra_frontend/features/products/presentation/products_page.dart';

void main() {
  testWidgets('renders products, schedule config, and crawl logs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductsPage(repository: _FakeProductRepository.full()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Taobao rice cooker'), findsOneWidget);
    expect(find.text('Products'), findsWidgets);
    expect(find.byKey(const Key('product-tab-products')), findsOneWidget);
    expect(
      find.byKey(const Key('product-tab-recent-crawl-logs')),
      findsOneWidget,
    );
    expect(find.text('Crawl Logs'), findsNothing);
    expect(find.text('Schedule Config'), findsOneWidget);
    expect(find.text('Product Crawl Schedule Config'), findsOneWidget);
    expect(find.text('0 9 * * *'), findsOneWidget);
    expect(find.text('Taobao'), findsWidgets);
    expect(find.text('JD'), findsWidgets);
    expect(find.text('Amazon'), findsWidgets);
    expect(find.text('Crawl completed'), findsNothing);

    await tester.tap(find.byKey(const Key('product-tab-recent-crawl-logs')));
    await tester.pumpAndSettle();

    expect(find.text('Recent Crawl Logs'), findsWidgets);
    expect(find.byKey(const Key('product-crawl-logs-table')), findsOneWidget);
    expect(find.text('Crawl completed'), findsOneWidget);
    expect(find.text('Schedule Config'), findsNothing);
  });

  testWidgets('creates and edits a product from the form', (tester) async {
    final repository = _FakeProductRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: ProductsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-form-dialog')), findsNothing);

    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-form-dialog')), findsOneWidget);
    expect(find.text('Add Product'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('product-title-field')),
      'JD desk lamp',
    );
    await tester.enterText(
      find.byKey(const Key('product-url-field')),
      'https://jd.example/lamp',
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('product-platform-field')),
        matching: find.text('JD'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Save product'));
    await tester.pumpAndSettle();

    expect(repository.savedDrafts.last.title, 'JD desk lamp');
    expect(repository.savedDrafts.last.platform, 'jd');

    await tester.ensureVisible(find.byKey(const Key('product-edit-1-button')));
    await tester.tap(find.byKey(const Key('product-edit-1-button')));
    await tester.pumpAndSettle();
    expect(find.text('Edit Product'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('product-title-field')),
      'Taobao rice cooker Pro',
    );
    await tester.tap(find.text('Save product'));
    await tester.pumpAndSettle();

    expect(repository.updatedProductId, 1);
    expect(repository.savedDrafts.last.title, 'Taobao rice cooker Pro');
  });

  testWidgets('imports products through the React-style paste workflow', (
    tester,
  ) async {
    final repository = _FakeProductRepository.full();
    final openedUrls = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ProductsPage(repository: repository, urlOpener: openedUrls.add),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Batch Import'));
    await tester.pumpAndSettle();

    expect(find.text('Batch Import Products'), findsOneWidget);
    expect(find.text('Paste URLs'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('product-import-raw-field')),
      'https://item.jd.com/10001234.html\n'
      'https://detail.tmall.com/item.htm?id=12345',
    );
    await tester.tap(find.byKey(const Key('product-import-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Confirm Platform'), findsOneWidget);
    expect(find.text('JD'), findsWidgets);
    expect(find.text('Taobao'), findsWidgets);
    await tester.tap(find.byKey(const Key('product-import-confirm-button')));
    await tester.pumpAndSettle();

    expect(repository.importedFileName, 'batch-import.csv');
    expect(repository.importedCsvContent, contains('10001234'));
    expect(repository.importedCsvContent, contains('taobao'));
    expect(find.text('Imported 2 products'), findsOneWidget);
  });

  testWidgets('exposes table filters, trends, crawl, and deletion intents', (
    tester,
  ) async {
    final repository = _FakeProductRepository.full();
    final openedUrls = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ProductsPage(repository: repository, urlOpener: openedUrls.add),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('product-search-field')),
      'chair',
    );
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Taobao rice cooker'), findsNothing);
    expect(find.text('JD office chair'), findsOneWidget);

    await tester.tap(find.byKey(const Key('product-clear-search-button')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('product-open-1-button')));
    await tester.tap(find.byKey(const Key('product-open-1-button')));
    await tester.pumpAndSettle();

    expect(openedUrls, ['https://taobao.example/rice']);

    await tester.ensureVisible(find.byKey(const Key('product-trend-1-button')));
    await tester.tap(find.byKey(const Key('product-trend-1-button')));
    await tester.pumpAndSettle();

    expect(find.text('Taobao rice cooker Price Trend'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('product-select-1')));
    await tester.tap(find.byKey(const Key('product-select-1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('product-batch-delete-button')),
    );
    await tester.tap(find.byKey(const Key('product-batch-delete-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('product-batch-delete-dialog-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.batchDeletedIds, [1]);

    await tester.ensureVisible(
      find.byKey(const Key('product-delete-2-button')),
    );
    await tester.tap(find.byKey(const Key('product-delete-2-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-delete-2-confirm-button')));
    await tester.pumpAndSettle();

    expect(repository.deletedProductId, 2);

    await tester.ensureVisible(
      find.byKey(const Key('product-crawl-now-button')),
    );
    await tester.tap(find.byKey(const Key('product-crawl-now-button')));
    await tester.pumpAndSettle();

    expect(repository.crawlRequested, isTrue);
    expect(find.text('Crawl task requested'), findsOneWidget);
  });

  testWidgets('matches React products workbench parity interactions', (
    tester,
  ) async {
    final repository = _FakeProductRepository.full();
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: ProductsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-platform-filter')), findsOneWidget);
    expect(find.byKey(const Key('product-active-filter')), findsOneWidget);
    expect(find.byKey(const Key('product-page-size-field')), findsOneWidget);
    expect(
      find.byKey(const Key('product-primary-actions-row')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('product-filter-row')), findsOneWidget);
    expect(find.byKey(const Key('product-import-open-button')), findsOneWidget);
    expect(
      find.byKey(const Key('product-batch-delete-confirm-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('product-pagination-summary')), findsOneWidget);
    expect(find.text('Page 1 of 3 - 42 products'), findsOneWidget);
    expect(find.byType(MavraResponsiveDataView<ProductItem>), findsOneWidget);
    expect(find.byType(DataTable), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const Key('product-next-page-button')));
    await tester.pumpAndSettle();
    expect(repository.lastListQuery.page, 2);

    await tester.tap(find.byKey(const Key('product-platform-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JD').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-page-size-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-active-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inactive').last);
    await tester.pumpAndSettle();

    expect(repository.lastListQuery.platform, 'jd');
    expect(repository.lastListQuery.active, false);
    expect(repository.lastListQuery.page, 1);
    expect(repository.lastListQuery.pageSize, 20);

    await tester.ensureVisible(find.byKey(const Key('product-edit-1-button')));
    await tester.tap(find.byKey(const Key('product-edit-1-button')));
    await tester.pumpAndSettle();

    expect(find.text('Edit Product'), findsOneWidget);
    expect(
      find.byKey(const Key('product-alert-enabled-field')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('product-alert-enabled-field')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('product-alert-threshold-field')),
      '8',
    );
    await tester.tap(find.text('Save product'));
    await tester.pumpAndSettle();

    expect(repository.savedProductAlertId, 1);
    expect(repository.savedProductAlertDraft?.enabled, isTrue);
    expect(repository.savedProductAlertDraft?.thresholdPercent, 8);

    await tester.ensureVisible(find.byKey(const Key('product-trend-1-button')));
    await tester.tap(find.byKey(const Key('product-trend-1-button')));
    await tester.pumpAndSettle();

    expect(find.text('Taobao rice cooker Price Trend'), findsOneWidget);
    expect(find.text('7d'), findsOneWidget);
    expect(find.text('30d'), findsOneWidget);
    expect(find.text('90d'), findsOneWidget);
    expect(find.text('Lowest'), findsOneWidget);
    expect(find.text('Highest'), findsOneWidget);
    expect(
      find.byKey(const Key('product-price-history-chart')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('product-price-history-table')),
      findsOneWidget,
    );
    expect(find.text('Period change: Drop 9.1%'), findsOneWidget);
    expect(find.byType(MavraTrendChart), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('product-cron-taobao-edit-button')),
    );
    expect(
      find.byKey(const Key('product-cron-taobao-edit-button')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('product-cron-jd-delete-button')),
    );
    await tester.tap(find.byKey(const Key('product-cron-jd-delete-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('product-cron-jd-delete-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.deletedCronPlatform, 'jd');
  });

  testWidgets('renders React-style crawl logs table and refresh action', (
    tester,
  ) async {
    final repository = _FakeProductRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: ProductsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('product-tab-recent-crawl-logs')));
    await tester.pumpAndSettle();

    expect(find.text('Recent Crawl Logs'), findsWidgets);
    expect(
      find.byKey(const Key('product-crawl-logs-refresh-button')),
      findsOneWidget,
    );
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Platform'), findsWidgets);
    expect(find.text('Status'), findsWidgets);
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('product-crawl-logs-refresh-button')),
    );
    await tester.tap(
      find.byKey(const Key('product-crawl-logs-refresh-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.crawlLogsRefreshCount, 1);
  });

  testWidgets('renders loading, empty, and error states', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProductsPage(repository: _SlowProductRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: ProductsPage(repository: _FakeProductRepository.empty()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No products yet'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: ProductsPage(repository: _FailingProductRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Products unavailable'), findsOneWidget);
  });

  testWidgets('disables crawl now without crawl permission', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductsPage(
          repository: _FakeProductRepository.full(),
          permissions: const {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-crawl-now-button')), findsNothing);
  });
}

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.snapshot);

  factory _FakeProductRepository.full() => _FakeProductRepository(
    ProductsSnapshot(
      products: const [
        ProductItem(
          id: 1,
          title: 'Taobao rice cooker',
          platform: 'taobao',
          currentPrice: '¥299',
          url: 'https://taobao.example/rice',
          enabled: true,
        ),
        ProductItem(
          id: 2,
          title: 'JD office chair',
          platform: 'jd',
          currentPrice: '¥899',
          url: 'https://jd.example/chair',
          enabled: true,
        ),
      ],
      page: const ProductPageState(
        items: [
          ProductItem(
            id: 1,
            title: 'Taobao rice cooker',
            platform: 'taobao',
            currentPrice: '¥299',
            url: 'https://taobao.example/rice',
            enabled: true,
          ),
          ProductItem(
            id: 2,
            title: 'JD office chair',
            platform: 'jd',
            currentPrice: '¥899',
            url: 'https://jd.example/chair',
            enabled: true,
          ),
        ],
        page: 1,
        pageSize: 15,
        total: 42,
      ),
      history: const [
        PriceHistoryPoint(label: 'Monday', price: '¥329'),
        PriceHistoryPoint(label: 'Tuesday', price: '¥299'),
      ],
      bindings: const [
        ProductProfileBinding(platform: 'taobao', profileName: 'taobao-main'),
      ],
      cronConfigs: const [
        ProductCronConfig(platform: 'taobao', cron: '0 9 * * *'),
        ProductCronConfig(platform: 'jd', cron: '30 10 * * 1-5'),
      ],
      crawlLogs: [
        ProductCrawlLog(
          message: 'Crawl completed',
          status: 'success',
          createdAt: DateTime.utc(2026, 6, 16, 8),
        ),
      ],
    ),
  );

  factory _FakeProductRepository.empty() => _FakeProductRepository(
    const ProductsSnapshot(
      products: [],
      history: [],
      bindings: [],
      cronConfigs: [],
      crawlLogs: [],
    ),
  );

  final ProductsSnapshot snapshot;
  final savedDrafts = <ProductDraft>[];
  int? updatedProductId;
  int? deletedProductId;
  List<int>? batchDeletedIds;
  String? importedFileName;
  String? importedCsvContent;
  bool crawlRequested = false;
  ProductListQuery lastListQuery = const ProductListQuery();
  int? savedProductAlertId;
  ProductAlertDraft? savedProductAlertDraft;
  String? savedProfileBindingPlatform;
  String? savedProfileBindingProfileKey;
  String? deletedProfileBindingPlatform;
  String? deletedCronPlatform;
  int crawlLogsRefreshCount = 0;

  @override
  Future<ProductsSnapshot> loadProducts() async => snapshot;

  @override
  Future<ProductPageState> listProducts(ProductListQuery query) async {
    lastListQuery = query;
    return ProductPageState(
      items: snapshot.products,
      page: query.page,
      pageSize: query.pageSize,
      total: snapshot.page.total == 0
          ? snapshot.products.length
          : snapshot.page.total,
    );
  }

  @override
  Future<List<PriceHistoryPoint>> getProductHistory(
    int productId, {
    int days = 30,
  }) async {
    return snapshot.history;
  }

  @override
  Future<void> saveAlert(
    int productId,
    ProductAlertDraft draft, {
    int? alertId,
  }) async {
    savedProductAlertId = productId;
    savedProductAlertDraft = draft;
  }

  @override
  Future<List<ProductPlatformProfileBinding>> listProfileBindings() async {
    return const [
      ProductPlatformProfileBinding(
        platform: 'taobao',
        profileKey: 'taobao-main',
        profileStatus: 'available',
      ),
    ];
  }

  @override
  Future<void> saveProfileBinding({
    required String platform,
    required String profileKey,
  }) async {
    savedProfileBindingPlatform = platform;
    savedProfileBindingProfileKey = profileKey;
  }

  @override
  Future<void> deleteProfileBinding(String platform) async {
    deletedProfileBindingPlatform = platform;
  }

  @override
  Future<List<ProductCrawlLog>> listCrawlLogs({
    int? productId,
    String? status,
  }) async {
    crawlLogsRefreshCount += 1;
    return snapshot.crawlLogs;
  }

  @override
  Future<List<ProductCronConfig>> listProductSchedules() async {
    return snapshot.cronConfigs;
  }

  @override
  Future<void> saveProductSchedule({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> deleteProductSchedule(String platform) async {
    deletedCronPlatform = platform;
  }

  @override
  Future<int?> saveProduct(ProductDraft draft, {int? productId}) async {
    savedDrafts.add(draft);
    updatedProductId = productId;
    return productId ?? 99;
  }

  @override
  Future<void> importProducts(PickedFileReference file) async {
    importedFileName = file.name;
    importedCsvContent = file.bytes == null ? null : utf8.decode(file.bytes!);
  }

  @override
  Future<void> deleteProduct(int productId) async {
    deletedProductId = productId;
  }

  @override
  Future<void> batchDeleteProducts(List<int> productIds) async {
    batchDeletedIds = productIds;
  }

  @override
  Future<void> requestCrawlNow() async {
    crawlRequested = true;
  }
}

class _SlowProductRepository implements ProductRepository {
  final _completer = Completer<ProductsSnapshot>();

  @override
  Future<ProductsSnapshot> loadProducts() => _completer.future;

  @override
  Future<ProductPageState> listProducts(ProductListQuery query) async {
    return ProductPageState(
      items: const [],
      page: query.page,
      pageSize: query.pageSize,
      total: 0,
    );
  }

  @override
  Future<List<PriceHistoryPoint>> getProductHistory(
    int productId, {
    int days = 30,
  }) async => const [];

  @override
  Future<void> saveAlert(
    int productId,
    ProductAlertDraft draft, {
    int? alertId,
  }) async {}

  @override
  Future<List<ProductPlatformProfileBinding>> listProfileBindings() async =>
      const [];

  @override
  Future<void> saveProfileBinding({
    required String platform,
    required String profileKey,
  }) async {}

  @override
  Future<void> deleteProfileBinding(String platform) async {}

  @override
  Future<List<ProductCrawlLog>> listCrawlLogs({
    int? productId,
    String? status,
  }) async => const [];

  @override
  Future<List<ProductCronConfig>> listProductSchedules() async => const [];

  @override
  Future<void> saveProductSchedule({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> deleteProductSchedule(String platform) async {}

  @override
  Future<int?> saveProduct(ProductDraft draft, {int? productId}) async =>
      productId ?? 99;

  @override
  Future<void> importProducts(PickedFileReference file) async {}

  @override
  Future<void> deleteProduct(int productId) async {}

  @override
  Future<void> batchDeleteProducts(List<int> productIds) async {}

  @override
  Future<void> requestCrawlNow() async {}
}

class _FailingProductRepository implements ProductRepository {
  @override
  Future<ProductsSnapshot> loadProducts() {
    throw StateError('products down');
  }

  @override
  Future<ProductPageState> listProducts(ProductListQuery query) async {
    throw StateError('products down');
  }

  @override
  Future<List<PriceHistoryPoint>> getProductHistory(
    int productId, {
    int days = 30,
  }) async {
    throw StateError('products down');
  }

  @override
  Future<void> saveAlert(
    int productId,
    ProductAlertDraft draft, {
    int? alertId,
  }) async {}

  @override
  Future<List<ProductPlatformProfileBinding>> listProfileBindings() async =>
      const [];

  @override
  Future<void> saveProfileBinding({
    required String platform,
    required String profileKey,
  }) async {}

  @override
  Future<void> deleteProfileBinding(String platform) async {}

  @override
  Future<List<ProductCrawlLog>> listCrawlLogs({
    int? productId,
    String? status,
  }) async => const [];

  @override
  Future<List<ProductCronConfig>> listProductSchedules() async => const [];

  @override
  Future<void> saveProductSchedule({
    required String platform,
    required String cronExpression,
    String timezone = 'Asia/Shanghai',
  }) async {}

  @override
  Future<void> deleteProductSchedule(String platform) async {}

  @override
  Future<int?> saveProduct(ProductDraft draft, {int? productId}) async =>
      productId ?? 99;

  @override
  Future<void> importProducts(PickedFileReference file) async {}

  @override
  Future<void> deleteProduct(int productId) async {}

  @override
  Future<void> batchDeleteProducts(List<int> productIds) async {}

  @override
  Future<void> requestCrawlNow() async {}
}
