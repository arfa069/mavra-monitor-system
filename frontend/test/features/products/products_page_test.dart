import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/files/file_service.dart';
import 'package:mavra_frontend/features/products/domain/product_models.dart';
import 'package:mavra_frontend/features/products/presentation/products_page.dart';

void main() {
  testWidgets('renders products, history, bindings, cron, and crawl logs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductsPage(repository: _FakeProductRepository.full()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Taobao rice cooker'), findsOneWidget);
    expect(find.text('¥299'), findsOneWidget);
    expect(find.text('Price history'), findsOneWidget);
    expect(find.text('Monday: ¥329'), findsOneWidget);
    expect(find.text('Profile binding'), findsOneWidget);
    expect(find.text('taobao-main'), findsOneWidget);
    expect(find.text('Platform cron'), findsOneWidget);
    expect(find.text('0 9 * * *'), findsOneWidget);
    expect(find.text('Crawl logs'), findsOneWidget);
    expect(find.text('Crawl completed'), findsOneWidget);
  });

  testWidgets('creates and edits a product from the form', (tester) async {
    final repository = _FakeProductRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: ProductsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New product'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('product-title-field')),
      'JD desk lamp',
    );
    await tester.enterText(
      find.byKey(const Key('product-url-field')),
      'https://jd.example/lamp',
    );
    await tester.enterText(
      find.byKey(const Key('product-platform-field')),
      'jd',
    );
    await tester.tap(find.text('Save product'));
    await tester.pumpAndSettle();

    expect(repository.savedDrafts.last.title, 'JD desk lamp');
    expect(repository.savedDrafts.last.platform, 'jd');

    await tester.tap(find.text('Edit Taobao rice cooker'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('product-title-field')),
      'Taobao rice cooker Pro',
    );
    await tester.tap(find.text('Save product'));
    await tester.pumpAndSettle();

    expect(repository.updatedProductId, 1);
    expect(repository.savedDrafts.last.title, 'Taobao rice cooker Pro');
  });

  testWidgets('imports products from a picked file', (tester) async {
    final repository = _FakeProductRepository.full();

    await tester.pumpWidget(
      MaterialApp(
        home: ProductsPage(
          repository: repository,
          fileService: const _FakeFileService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Batch import'));
    await tester.pumpAndSettle();

    expect(repository.importedFileName, 'products.csv');
    expect(find.text('Imported products.csv'), findsOneWidget);
  });

  testWidgets('exposes table filters, trends, crawl, and deletion intents', (
    tester,
  ) async {
    final repository = _FakeProductRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: ProductsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('product-search-field')),
      'chair',
    );
    await tester.pumpAndSettle();

    expect(find.text('Taobao rice cooker'), findsNothing);
    expect(find.text('JD office chair'), findsOneWidget);

    await tester.tap(find.byKey(const Key('product-clear-search-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-trend-1-button')));
    await tester.pumpAndSettle();

    expect(find.text('Price trend: Taobao rice cooker'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('product-select-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('product-batch-delete-button')));
    await tester.pumpAndSettle();

    expect(repository.batchDeletedIds, [1]);

    await tester.tap(find.byKey(const Key('product-delete-2-button')));
    await tester.pumpAndSettle();

    expect(repository.deletedProductId, 2);

    await tester.tap(find.byKey(const Key('product-crawl-now-button')));
    await tester.pumpAndSettle();

    expect(repository.crawlRequested, isTrue);
    expect(find.text('Crawl task requested'), findsOneWidget);
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
      history: const [
        PriceHistoryPoint(label: 'Monday', price: '¥329'),
        PriceHistoryPoint(label: 'Tuesday', price: '¥299'),
      ],
      bindings: const [
        ProductProfileBinding(platform: 'taobao', profileName: 'taobao-main'),
      ],
      cronConfigs: const [
        ProductCronConfig(platform: 'taobao', cron: '0 9 * * *'),
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
  bool crawlRequested = false;

  @override
  Future<ProductsSnapshot> loadProducts() async => snapshot;

  @override
  Future<void> saveProduct(ProductDraft draft, {int? productId}) async {
    savedDrafts.add(draft);
    updatedProductId = productId;
  }

  @override
  Future<void> importProducts(PickedFileReference file) async {
    importedFileName = file.name;
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
  Future<void> saveProduct(ProductDraft draft, {int? productId}) async {}

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
  Future<void> saveProduct(ProductDraft draft, {int? productId}) async {}

  @override
  Future<void> importProducts(PickedFileReference file) async {}

  @override
  Future<void> deleteProduct(int productId) async {}

  @override
  Future<void> batchDeleteProducts(List<int> productIds) async {}

  @override
  Future<void> requestCrawlNow() async {}
}

class _FakeFileService extends FileService {
  const _FakeFileService()
    : super(canPickFiles: true, canSaveFiles: false, canDownloadFiles: false);

  @override
  Future<PickedFileReference?> pickFile() async {
    return const PickedFileReference(name: 'products.csv', bytes: [1, 2, 3]);
  }
}
