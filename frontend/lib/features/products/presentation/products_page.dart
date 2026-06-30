import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/files/file_service.dart';
import '../../../core/notifications/mavra_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_confirm.dart';
import '../../../core/widgets/mavra_page_banner.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../../../core/widgets/mavra_style_helpers.dart';
import '../domain/product_models.dart';

typedef ProductUrlOpener = FutureOr<void> Function(String url);

enum _ProductWorkbenchTab { products, recentCrawlLogs }

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    required this.repository,
    this.fileService,
    this.permissions,
    this.urlOpener,
  });

  final ProductRepository repository;
  final FileService? fileService;
  final Set<String>? permissions;
  final ProductUrlOpener? urlOpener;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  Future<ProductsSnapshot>? _productsFuture;
  ProductsSnapshot? _snapshot;
  ProductPageState? _page;
  Object? _error;
  int _loadRequestId = 0;
  int? _editingProductId;
  int? _editingAlertId;
  bool _productActive = true;
  bool _alertEnabled = false;
  _ProductWorkbenchTab _activeTab = _ProductWorkbenchTab.products;
  Timer? _searchDebounce;
  final Set<int> _selectedProductIds = {};

  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _platformController = TextEditingController();
  final _alertThresholdController = TextEditingController(text: '5');
  final _searchController = TextEditingController();
  final _filterPlatformController = TextEditingController();
  final _pageSizeController = TextEditingController(text: '15');
  String _activeFilter = 'all';

  bool get _canRequestCrawlNow =>
      widget.permissions == null ||
      widget.permissions!.contains('crawl:execute');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void didUpdateWidget(covariant ProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _snapshot = null;
      _page = null;
      _load();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _titleController.dispose();
    _urlController.dispose();
    _platformController.dispose();
    _alertThresholdController.dispose();
    _searchController.dispose();
    _filterPlatformController.dispose();
    _pageSizeController.dispose();
    super.dispose();
  }

  void _load() {
    final requestId = ++_loadRequestId;
    final future = Future.sync(widget.repository.loadProducts);
    setState(() {
      _error = null;
      _productsFuture = future;
    });
    future
        .then((snapshot) {
          if (!mounted || requestId != _loadRequestId) {
            return;
          }
          setState(() {
            _snapshot = snapshot;
            _pageSizeController.text = '${snapshot.page.pageSize}';
            _page = snapshot.page.items.isEmpty
                ? ProductPageState(
                    items: snapshot.products,
                    page: 1,
                    pageSize: snapshot.products.isEmpty
                        ? _pageSize()
                        : snapshot.products.length,
                    total: snapshot.products.length,
                  )
                : snapshot.page;
          });
        })
        .catchError((Object error) {
          if (mounted && requestId == _loadRequestId) {
            setState(() => _error = error);
          }
        });
  }

  void _newProduct() {
    _editingProductId = null;
    _editingAlertId = null;
    _productActive = true;
    _alertEnabled = false;
    _alertThresholdController.text = '5';
    _titleController.clear();
    _urlController.clear();
    _platformController.clear();
    _showProductDialog(title: 'Add Product');
  }

  void _editProduct(ProductItem product) {
    final alert = _alertForProduct(product.id);
    _editingProductId = product.id;
    _editingAlertId = alert?.id;
    _productActive = product.enabled;
    _alertEnabled = alert?.active ?? false;
    _alertThresholdController.text = _formatThreshold(alert?.thresholdPercent);
    _titleController.text = product.title;
    _urlController.text = product.url;
    _platformController.text = product.platform;
    _showProductDialog(title: 'Edit Product');
  }

  void _showProductDialog({required String title}) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            key: const Key('product-form-dialog'),
            title: Text(title),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: _ProductForm(
                  titleController: _titleController,
                  urlController: _urlController,
                  platformController: _platformController,
                  alertThresholdController: _alertThresholdController,
                  active: _productActive,
                  alertEnabled: _alertEnabled,
                  onUrlChanged: _editingProductId == null
                      ? (url) {
                          final platform = _detectProductPlatform(url);
                          if (platform == null ||
                              platform == _platformController.text) {
                            return;
                          }
                          setDialogState(() {
                            _platformController.text = platform;
                          });
                        }
                      : null,
                  onActiveChanged: (value) =>
                      setDialogState(() => _productActive = value),
                  onAlertEnabledChanged: (value) =>
                      setDialogState(() => _alertEnabled = value),
                  onPlatformChanged: (value) =>
                      setDialogState(() => _platformController.text = value),
                  onSave: _saveProduct,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProduct() async {
    final draft = ProductDraft(
      title: _titleController.text.trim(),
      url: _urlController.text.trim(),
      platform: _platformController.text.trim(),
      active: _productActive,
    );
    final alertThreshold =
        double.tryParse(_alertThresholdController.text.trim()) ?? 5;

    try {
      final savedProductId = await widget.repository.saveProduct(
        draft,
        productId: _editingProductId,
      );
      final productId = _editingProductId ?? savedProductId;
      if (productId != null && (_alertEnabled || _editingAlertId != null)) {
        await widget.repository.saveAlert(
          productId,
          ProductAlertDraft(
            enabled: _alertEnabled,
            alertType: 'price_change',
            thresholdPercent: alertThreshold,
          ),
          alertId: _editingAlertId,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      MavraNotifier.success('Saved ${draft.title}');
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  void _onSearchChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        _loadProductPage(1);
      }
    });
  }

  void _setPlatformFilter(String? value) {
    setState(() => _filterPlatformController.text = value ?? '');
    _loadProductPage(1);
  }

  void _setActiveFilter(String value) {
    setState(() => _activeFilter = value);
    _loadProductPage(1);
  }

  void _setPageSize(int value) {
    setState(() => _pageSizeController.text = '$value');
    _loadProductPage(1);
  }

  Future<void> _loadProductPage(int pageNumber) async {
    final pageSize = _pageSize();
    final active = switch (_activeFilter) {
      'active' => true,
      'inactive' => false,
      _ => null,
    };

    final query = ProductListQuery(
      keyword: _emptyToNull(_searchController.text),
      platform: _emptyToNull(_filterPlatformController.text),
      active: active,
      page: pageNumber,
      pageSize: pageSize,
    );

    try {
      final page = await widget.repository.listProducts(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _page = page;
        _selectedProductIds.clear();
      });
      MavraNotifier.info('Loaded ${page.total} products');
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _importProducts() async {
    final rows = await showDialog<List<_ParsedProductImport>>(
      context: context,
      builder: (context) => _BatchImportDialog(
        existingUrls: {
          for (final product in _snapshot?.products ?? const <ProductItem>[])
            product.url,
        },
      ),
    );
    if (rows == null || rows.isEmpty) {
      return;
    }

    try {
      final file = PickedFileReference(
        name: 'batch-import.csv',
        bytes: utf8.encode(_importRowsToCsv(rows)),
      );
      await widget.repository.importProducts(file);
      if (!mounted) {
        return;
      }
      MavraNotifier.success('Imported ${rows.length} products');
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _deleteProduct(int productId) async {
    final confirmed = await mavraConfirm(
      context,
      title: 'Delete product',
      message: 'Delete product #$productId?',
      confirmKey: Key('product-delete-$productId-confirm-button'),
      confirmLabel: 'Delete',
    );
    if (!confirmed) {
      return;
    }

    try {
      await widget.repository.deleteProduct(productId);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedProductIds.remove(productId);
      });
      MavraNotifier.success('Deleted product #$productId');
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _batchDeleteProducts() async {
    final ids = _selectedProductIds.toList()..sort();
    if (ids.isEmpty) {
      MavraNotifier.warning('Select products to delete');
      return;
    }

    final confirmed = await mavraConfirm(
      context,
      title: 'Delete selected products',
      message: 'Delete ${ids.length} selected products?',
      confirmKey: const Key('product-batch-delete-dialog-confirm-button'),
      confirmLabel: 'Delete',
    );
    if (!confirmed) {
      return;
    }

    try {
      await widget.repository.batchDeleteProducts(ids);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedProductIds.clear();
      });
      MavraNotifier.success('Deleted ${ids.length} products');
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _requestCrawlNow() async {
    try {
      await widget.repository.requestCrawlNow();
      if (!mounted) {
        return;
      }
      MavraNotifier.success('Crawl task requested');
      _load();
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Crawl request failed');
      }
    }
  }

  Future<void> _refreshCrawlLogs() async {
    try {
      final logs = await widget.repository.listCrawlLogs();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = (_snapshot ?? const ProductsSnapshot.empty()).copyWith(
          crawlLogs: logs,
        );
      });
      MavraNotifier.info('Loaded ${logs.length} crawl logs');
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Crawl logs unavailable');
      }
    }
  }

  void _toggleProductSelection(int productId, bool selected) {
    setState(() {
      if (selected) {
        _selectedProductIds.add(productId);
      } else {
        _selectedProductIds.remove(productId);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _loadProductPage(1);
  }

  void _showPriceTrend(ProductItem product) {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _PriceTrendDialog(repository: widget.repository, product: product),
    );
  }

  Future<void> _openProduct(ProductItem product) async {
    try {
      final opener = widget.urlOpener ?? _launchExternalProductUrl;
      await opener(product.url);
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Could not open ${product.title}');
      }
    }
  }

  ProductAlertInfo? _alertForProduct(int productId) {
    final alerts = _snapshot?.alerts ?? const <ProductAlertInfo>[];
    for (final alert in alerts) {
      if (alert.productId == productId) {
        return alert;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.today, label: 'Today'),
          AdaptiveDestination(icon: Icons.event_note, label: 'Events'),
          AdaptiveDestination(icon: Icons.inventory_2, label: 'Products'),
          AdaptiveDestination(icon: Icons.analytics, label: 'Analytics'),
        ],
        selectedIndex: 2,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 1:
              context.go('/events');
            case 3:
              context.go('/analytics');
          }
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<ProductsSnapshot>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (_error != null) {
                  return const Center(child: Text('Products unavailable'));
                }
                if (snapshot.connectionState != ConnectionState.done &&
                    _snapshot == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _ProductsContent(
                  snapshot: _snapshot ?? const ProductsSnapshot.empty(),
                  page: _page,
                  canRequestCrawlNow: _canRequestCrawlNow,
                  activeTab: _activeTab,
                  searchController: _searchController,
                  filterPlatformController: _filterPlatformController,
                  pageSizeController: _pageSizeController,
                  activeFilter: _activeFilter,
                  selectedProductIds: _selectedProductIds,
                  onActiveFilterChanged: (value) => _setActiveFilter(value),
                  onPlatformFilterChanged: _setPlatformFilter,
                  onPageSizeChanged: _setPageSize,
                  onNewProduct: _newProduct,
                  onImportProducts: _importProducts,
                  onEditProduct: _editProduct,
                  onDeleteProduct: _deleteProduct,
                  onBatchDeleteProducts: _batchDeleteProducts,
                  onRequestCrawlNow: _requestCrawlNow,
                  onProductSelected: _toggleProductSelection,
                  onProductPageChanged: _loadProductPage,
                  onClearSearch: _clearSearch,
                  onOpenProduct: _openProduct,
                  onShowTrend: _showPriceTrend,
                  onTabChanged: (tab) => setState(() => _activeTab = tab),
                  onRefreshCrawlLogs: _refreshCrawlLogs,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static String _formatThreshold(double? value) {
    if (value == null) {
      return '5';
    }
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int _pageSize() {
    final parsed = int.tryParse(_pageSizeController.text.trim());
    if (parsed == null || parsed < 1) {
      return 15;
    }
    return parsed.clamp(1, 100).toInt();
  }

  static String _importRowsToCsv(List<_ParsedProductImport> rows) {
    final buffer = StringBuffer('url,platform\n');
    for (final row in rows) {
      buffer.writeln('${row.url},${row.platform}');
    }
    return buffer.toString();
  }
}

Future<void> _launchExternalProductUrl(String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) {
    throw StateError('Could not open $url');
  }
}

String? _detectProductPlatform(String url) {
  final normalized = url.toLowerCase();
  if (normalized.contains('jd.com') ||
      normalized.contains('jingdong') ||
      RegExp(r'(^|[./-])jd[.-]').hasMatch(normalized)) {
    return 'jd';
  }
  if (normalized.contains('taobao.com') || normalized.contains('tmall.com')) {
    return 'taobao';
  }
  if (normalized.contains('amazon.')) {
    return 'amazon';
  }
  return null;
}

class _ProductsContent extends StatelessWidget {
  const _ProductsContent({
    required this.snapshot,
    required this.page,
    required this.canRequestCrawlNow,
    required this.activeTab,
    required this.searchController,
    required this.filterPlatformController,
    required this.pageSizeController,
    required this.activeFilter,
    required this.selectedProductIds,
    required this.onActiveFilterChanged,
    required this.onPlatformFilterChanged,
    required this.onPageSizeChanged,
    required this.onNewProduct,
    required this.onImportProducts,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onBatchDeleteProducts,
    required this.onRequestCrawlNow,
    required this.onProductSelected,
    required this.onProductPageChanged,
    required this.onClearSearch,
    required this.onOpenProduct,
    required this.onShowTrend,
    required this.onTabChanged,
    required this.onRefreshCrawlLogs,
  });

  final ProductsSnapshot snapshot;
  final ProductPageState? page;
  final bool canRequestCrawlNow;
  final _ProductWorkbenchTab activeTab;
  final TextEditingController searchController;
  final TextEditingController filterPlatformController;
  final TextEditingController pageSizeController;
  final String activeFilter;
  final Set<int> selectedProductIds;
  final ValueChanged<String> onActiveFilterChanged;
  final ValueChanged<String?> onPlatformFilterChanged;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onNewProduct;
  final VoidCallback onImportProducts;
  final ValueChanged<ProductItem> onEditProduct;
  final ValueChanged<int> onDeleteProduct;
  final Future<void> Function() onBatchDeleteProducts;
  final Future<void> Function() onRequestCrawlNow;
  final void Function(int productId, bool selected) onProductSelected;
  final Future<void> Function(int page) onProductPageChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<ProductItem> onOpenProduct;
  final ValueChanged<ProductItem> onShowTrend;
  final ValueChanged<_ProductWorkbenchTab> onTabChanged;
  final Future<void> Function() onRefreshCrawlLogs;

  @override
  Widget build(BuildContext context) {
    final pageState =
        page ??
        ProductPageState(
          items: snapshot.products,
          page: 1,
          pageSize: snapshot.products.isEmpty ? 15 : snapshot.products.length,
          total: snapshot.products.length,
        );
    final products = _filterProducts(pageState.items);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MavraPageBanner(
            accentColor: AppTheme.brandBlueDeep,
            eyebrow: 'Prices',
            title: 'Product Management',
            subtitle:
                'Track Taobao, JD, and Amazon products, schedule crawls, and review price movement.',
          ),
          const SizedBox(height: 20),
          _ProductSectionTabs(activeTab: activeTab, onTabChanged: onTabChanged),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final productsPanel = _ProductsPanel(
                products: products,
                pageState: pageState,
                searchController: searchController,
                filterPlatformController: filterPlatformController,
                pageSizeController: pageSizeController,
                activeFilter: activeFilter,
                selectedProductIds: selectedProductIds,
                canRequestCrawlNow: canRequestCrawlNow,
                onActiveFilterChanged: onActiveFilterChanged,
                onPlatformFilterChanged: onPlatformFilterChanged,
                onPageSizeChanged: onPageSizeChanged,
                onClearSearch: onClearSearch,
                onBatchDeleteProducts: onBatchDeleteProducts,
                onImportProducts: onImportProducts,
                onRequestCrawlNow: onRequestCrawlNow,
                onNewProduct: onNewProduct,
                onProductSelected: onProductSelected,
                onProductPageChanged: onProductPageChanged,
                onEditProduct: onEditProduct,
                onDeleteProduct: onDeleteProduct,
                onOpenProduct: onOpenProduct,
                onShowTrend: onShowTrend,
              );
              final logsPanel = _Section(
                title: 'Recent Crawl Logs',
                emptyText: 'No crawl records',
                actions: OutlinedButton.icon(
                  key: const Key('product-crawl-logs-refresh-button'),
                  onPressed: onRefreshCrawlLogs,
                  style: MavraButtonStyle.compactOutlined(context: context),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
                children: [
                  if (snapshot.crawlLogs.isNotEmpty)
                    _ProductCrawlLogsTable(logs: snapshot.crawlLogs),
                ],
              );

              if (activeTab == _ProductWorkbenchTab.recentCrawlLogs) {
                return logsPanel;
              }

              return productsPanel;
            },
          ),
        ],
      ),
    );
  }

  List<ProductItem> _filterProducts(List<ProductItem> products) {
    final normalized = searchController.text.trim().toLowerCase();
    return [
      for (final product in products)
        if (normalized.isEmpty ||
            product.title.toLowerCase().contains(normalized) ||
            product.platform.toLowerCase().contains(normalized) ||
            product.url.toLowerCase().contains(normalized))
          product,
    ];
  }
}

const _productPlatforms = ['taobao', 'jd', 'amazon'];

String _platformLabel(String value) {
  return switch (value) {
    'jd' => 'JD',
    'taobao' => 'Taobao',
    'amazon' => 'Amazon',
    _ => value,
  };
}

class _ProductSectionTabs extends StatelessWidget {
  const _ProductSectionTabs({
    required this.activeTab,
    required this.onTabChanged,
  });

  final _ProductWorkbenchTab activeTab;
  final ValueChanged<_ProductWorkbenchTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final productsSelected = activeTab == _ProductWorkbenchTab.products;
    final logsSelected = activeTab == _ProductWorkbenchTab.recentCrawlLogs;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SizedBox(
          height: 40,
          child: ChoiceChip(
            key: const Key('product-tab-products'),
            avatar: Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: MavraTabChipStyle.iconColor(context, productsSelected),
            ),
            label: const Text('Products'),
            labelStyle: MavraTabChipStyle.labelStyle(context, productsSelected),
            selected: productsSelected,
            selectedColor: MavraTabChipStyle.selectedColor(context),
            backgroundColor: MavraTabChipStyle.backgroundColor(context),
            side: MavraTabChipStyle.side(context),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            showCheckmark: false,
            onSelected: (_) => onTabChanged(_ProductWorkbenchTab.products),
          ),
        ),
        SizedBox(
          height: 40,
          child: ChoiceChip(
            key: const Key('product-tab-recent-crawl-logs'),
            avatar: Icon(
              Icons.receipt_long_outlined,
              size: 16,
              color: MavraTabChipStyle.iconColor(context, logsSelected),
            ),
            label: const Text('Recent Crawl Logs'),
            labelStyle: MavraTabChipStyle.labelStyle(context, logsSelected),
            selected: logsSelected,
            selectedColor: MavraTabChipStyle.selectedColor(context),
            backgroundColor: MavraTabChipStyle.backgroundColor(context),
            side: MavraTabChipStyle.side(context),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            showCheckmark: false,
            onSelected: (_) =>
                onTabChanged(_ProductWorkbenchTab.recentCrawlLogs),
          ),
        ),
      ],
    );
  }
}

class _ProductsPanel extends StatelessWidget {
  const _ProductsPanel({
    required this.products,
    required this.pageState,
    required this.searchController,
    required this.filterPlatformController,
    required this.pageSizeController,
    required this.activeFilter,
    required this.selectedProductIds,
    required this.canRequestCrawlNow,
    required this.onActiveFilterChanged,
    required this.onPlatformFilterChanged,
    required this.onPageSizeChanged,
    required this.onClearSearch,
    required this.onBatchDeleteProducts,
    required this.onImportProducts,
    required this.onRequestCrawlNow,
    required this.onNewProduct,
    required this.onProductSelected,
    required this.onProductPageChanged,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onOpenProduct,
    required this.onShowTrend,
  });

  final List<ProductItem> products;
  final ProductPageState pageState;
  final TextEditingController searchController;
  final TextEditingController filterPlatformController;
  final TextEditingController pageSizeController;
  final String activeFilter;
  final Set<int> selectedProductIds;
  final bool canRequestCrawlNow;
  final ValueChanged<String> onActiveFilterChanged;
  final ValueChanged<String?> onPlatformFilterChanged;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onBatchDeleteProducts;
  final VoidCallback onImportProducts;
  final Future<void> Function() onRequestCrawlNow;
  final VoidCallback onNewProduct;
  final void Function(int productId, bool selected) onProductSelected;
  final Future<void> Function(int page) onProductPageChanged;
  final ValueChanged<ProductItem> onEditProduct;
  final ValueChanged<int> onDeleteProduct;
  final ValueChanged<ProductItem> onOpenProduct;
  final ValueChanged<ProductItem> onShowTrend;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Products',
      emptyText: 'No products yet',
      actions: canRequestCrawlNow
          ? OutlinedButton.icon(
              key: const Key('product-crawl-now-button'),
              onPressed: onRequestCrawlNow,
              style: MavraButtonStyle.compactOutlined(context: context),
              icon: const Icon(Icons.travel_explore, size: 18),
              label: const Text('Crawl Now'),
            )
          : null,
      children: [
        _ProductFilters(
          onImportProducts: onImportProducts,
          onNewProduct: onNewProduct,
          searchController: searchController,
          platformController: filterPlatformController,
          activeFilter: activeFilter,
          selectedCount: selectedProductIds.length,
          onActiveFilterChanged: onActiveFilterChanged,
          onPlatformFilterChanged: onPlatformFilterChanged,
          onClearSearch: onClearSearch,
          onBatchDeleteProducts: onBatchDeleteProducts,
        ),
        const SizedBox(height: 12),
        if (pageState.total == 0)
          const Center(child: Text('No products yet'))
        else if (products.isEmpty)
          const Center(child: Text('No products match the current filters'))
        else
          _ProductWorkbenchTable(
            products: products,
            selectedProductIds: selectedProductIds,
            onSelected: onProductSelected,
            onEdit: onEditProduct,
            onDelete: onDeleteProduct,
            onOpen: onOpenProduct,
            onShowTrend: onShowTrend,
          ),
        const SizedBox(height: 12),
        _ProductPaginationControls(
          pageState: pageState,
          pageSizeController: pageSizeController,
          onPageChanged: onProductPageChanged,
          onPageSizeChanged: onPageSizeChanged,
        ),
      ],
    );
  }
}

class _ProductFilters extends StatelessWidget {
  const _ProductFilters({
    required this.onImportProducts,
    required this.onNewProduct,
    required this.searchController,
    required this.platformController,
    required this.activeFilter,
    required this.selectedCount,
    required this.onActiveFilterChanged,
    required this.onPlatformFilterChanged,
    required this.onClearSearch,
    required this.onBatchDeleteProducts,
  });

  final VoidCallback onImportProducts;
  final VoidCallback onNewProduct;
  final TextEditingController searchController;
  final TextEditingController platformController;
  final String activeFilter;
  final int selectedCount;
  final ValueChanged<String> onActiveFilterChanged;
  final ValueChanged<String?> onPlatformFilterChanged;
  final VoidCallback onClearSearch;
  final Future<void> Function() onBatchDeleteProducts;

  @override
  Widget build(BuildContext context) {
    final platformValue = platformController.text.trim().isEmpty
        ? null
        : platformController.text.trim();

    final actions = Wrap(
      key: const Key('product-primary-actions-row'),
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          key: const Key('product-import-open-button'),
          onPressed: onImportProducts,
          style: MavraButtonStyle.compactOutlined(context: context),
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Batch Import'),
        ),
        KeyedSubtree(
          key: const Key('product-batch-delete-confirm-button'),
          child: OutlinedButton.icon(
            key: const Key('product-batch-delete-button'),
            onPressed: selectedCount == 0 ? null : onBatchDeleteProducts,
            style: MavraButtonStyle.compactOutlined(
              context: context,
              isDangerous: true,
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Batch Delete'),
          ),
        ),
        FilledButton.icon(
          key: const Key('product-add-button'),
          onPressed: onNewProduct,
          style: MavraButtonStyle.compactFilled(context: context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Product'),
        ),
      ],
    );

    final filters = Wrap(
      key: const Key('product-filter-row'),
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          height: 48,
          child: TextField(
            key: const Key('product-search-field'),
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Search title or URL',
              suffixIcon: IconButton(
                key: const Key('product-clear-search-button'),
                tooltip: 'Clear search',
                style: MavraButtonStyle.rowIconButton(context: context),
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear, size: 18),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 230,
          height: 48,
          child: DropdownButtonFormField<String?>(
            key: const Key('product-platform-filter'),
            initialValue: platformValue,
            isExpanded: true,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Platform',
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Platforms')),
              DropdownMenuItem(value: 'taobao', child: Text('Taobao')),
              DropdownMenuItem(value: 'jd', child: Text('JD')),
              DropdownMenuItem(value: 'amazon', child: Text('Amazon')),
            ],
            onChanged: onPlatformFilterChanged,
          ),
        ),
        SizedBox(
          width: 220,
          height: 48,
          child: DropdownButtonFormField<String>(
            key: const Key('product-active-filter'),
            initialValue: activeFilter,
            isExpanded: true,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Status',
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Statuses')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
            ],
            onChanged: (value) {
              if (value != null) {
                onActiveFilterChanged(value);
              }
            },
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 980) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: actions),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Align(alignment: Alignment.centerRight, child: filters),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [actions, const SizedBox(height: 12), filters],
        );
      },
    );
  }
}

class _ProductPaginationControls extends StatelessWidget {
  const _ProductPaginationControls({
    required this.pageState,
    required this.pageSizeController,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  final ProductPageState pageState;
  final TextEditingController pageSizeController;
  final Future<void> Function(int page) onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final pageSize = pageState.pageSize <= 0 ? 15 : pageState.pageSize;
    final totalPages = pageState.total <= 0
        ? 1
        : ((pageState.total + pageSize - 1) ~/ pageSize);
    final current = pageState.page.clamp(1, totalPages).toInt();

    return Row(
      children: [
        Expanded(
          child: Text(
            key: const Key('product-pagination-summary'),
            'Page $current of $totalPages - ${pageState.total} products',
          ),
        ),
        SizedBox(
          width: 96,
          height: 48,
          child: DropdownButtonFormField<int>(
            key: const Key('product-page-size-field'),
            initialValue: _normalizedPageSize(pageSize),
            isExpanded: true,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Page size',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 15, child: Text('15')),
              DropdownMenuItem(value: 20, child: Text('20')),
              DropdownMenuItem(value: 50, child: Text('50')),
              DropdownMenuItem(value: 100, child: Text('100')),
            ],
            onChanged: (value) {
              if (value != null) {
                pageSizeController.text = '$value';
                onPageSizeChanged(value);
              }
            },
          ),
        ),
        IconButton(
          key: const Key('product-previous-page-button'),
          tooltip: 'Previous page',
          onPressed: current <= 1 ? null : () => onPageChanged(current - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          key: const Key('product-next-page-button'),
          tooltip: 'Next page',
          onPressed: current >= totalPages
              ? null
              : () => onPageChanged(current + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  static int _normalizedPageSize(int value) {
    return switch (value) {
      15 || 20 || 50 || 100 => value,
      _ => 15,
    };
  }
}

class _ParsedProductImport {
  const _ParsedProductImport({required this.url, required this.platform});

  final String url;
  final String platform;

  _ParsedProductImport copyWith({String? platform}) {
    return _ParsedProductImport(url: url, platform: platform ?? this.platform);
  }
}

class _BatchImportDialog extends StatefulWidget {
  const _BatchImportDialog({required this.existingUrls});

  final Set<String> existingUrls;

  @override
  State<_BatchImportDialog> createState() => _BatchImportDialogState();
}

class _BatchImportDialogState extends State<_BatchImportDialog> {
  final _rawController = TextEditingController();
  var _confirming = false;
  var _rows = <_ParsedProductImport>[];
  String? _error;

  @override
  void dispose() {
    _rawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batch Import Products'),
      content: SizedBox(
        width: 620,
        child: _confirming ? _buildConfirmation() : _buildPasteStep(),
      ),
      actions: [
        if (_confirming)
          TextButton(
            onPressed: () => setState(() => _confirming = false),
            child: const Text('Back'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: _confirming
              ? const Key('product-import-confirm-button')
              : const Key('product-import-next-button'),
          onPressed: _confirming ? _confirm : _parseRawUrls,
          icon: Icon(_confirming ? Icons.check : Icons.arrow_forward),
          label: Text(_confirming ? 'Import' : 'Next'),
        ),
      ],
    );
  }

  Widget _buildPasteStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Paste URLs'),
        const SizedBox(height: 8),
        TextField(
          key: const Key('product-import-raw-field'),
          controller: _rawController,
          minLines: 8,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'One URL per line',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ],
      ],
    );
  }

  Widget _buildConfirmation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirm Platform'),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _rows.length,
            separatorBuilder: (context, index) => const Divider(height: 12),
            itemBuilder: (context, index) {
              final row = _rows[index];
              return Row(
                children: [
                  Expanded(
                    child: Text(row.url, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: row.platform,
                    items: const [
                      DropdownMenuItem(value: 'jd', child: Text('JD')),
                      DropdownMenuItem(value: 'taobao', child: Text('Taobao')),
                      DropdownMenuItem(value: 'amazon', child: Text('Amazon')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _rows[index] = row.copyWith(platform: value);
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _parseRawUrls() {
    final seen = <String>{};
    final rows = <_ParsedProductImport>[];
    final chunks = _rawController.text
        .split(RegExp(r'[\r\n\t ]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);

    for (final url in chunks) {
      if (seen.contains(url) || widget.existingUrls.contains(url)) {
        continue;
      }
      final platform = _detectProductPlatform(url);
      if (platform == null) {
        continue;
      }
      seen.add(url);
      rows.add(_ParsedProductImport(url: url, platform: platform));
      if (rows.length >= 100) {
        break;
      }
    }

    if (rows.isEmpty) {
      setState(() => _error = 'Paste at least one supported product URL');
      return;
    }

    setState(() {
      _rows = rows;
      _error = null;
      _confirming = true;
    });
  }

  void _confirm() {
    Navigator.of(context).pop(_rows);
  }
}

class _ProductForm extends StatelessWidget {
  const _ProductForm({
    required this.titleController,
    required this.urlController,
    required this.platformController,
    required this.alertThresholdController,
    required this.active,
    required this.alertEnabled,
    required this.onUrlChanged,
    required this.onActiveChanged,
    required this.onAlertEnabledChanged,
    required this.onPlatformChanged,
    required this.onSave,
  });

  final TextEditingController titleController;
  final TextEditingController urlController;
  final TextEditingController platformController;
  final TextEditingController alertThresholdController;
  final bool active;
  final bool alertEnabled;
  final ValueChanged<String>? onUrlChanged;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<bool> onAlertEnabledChanged;
  final ValueChanged<String> onPlatformChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('product-title-field'),
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('product-url-field'),
          controller: urlController,
          decoration: const InputDecoration(labelText: 'URL'),
          onChanged: onUrlChanged,
        ),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: const Key('product-platform-field'),
          child: DropdownButtonFormField<String>(
            key: ValueKey('product-platform-${platformController.text}'),
            initialValue: _productPlatforms.contains(platformController.text)
                ? platformController.text
                : null,
            decoration: const InputDecoration(labelText: 'Platform'),
            items: const [
              DropdownMenuItem(value: 'taobao', child: Text('Taobao')),
              DropdownMenuItem(value: 'jd', child: Text('JD')),
              DropdownMenuItem(value: 'amazon', child: Text('Amazon')),
            ],
            onChanged: (value) {
              if (value != null) {
                onPlatformChanged(value);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('product-active-field'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Active'),
          value: active,
          onChanged: onActiveChanged,
        ),
        SwitchListTile(
          key: const Key('product-alert-enabled-field'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Price alert enabled'),
          value: alertEnabled,
          onChanged: onAlertEnabledChanged,
        ),
        if (alertEnabled) ...[
          const SizedBox(height: 8),
          TextField(
            key: const Key('product-alert-threshold-field'),
            controller: alertThresholdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Alert threshold percent',
              suffixText: '%',
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text('Save product'),
          ),
        ),
      ],
    );
  }
}

class _ProductWorkbenchTable extends StatelessWidget {
  const _ProductWorkbenchTable({
    required this.products,
    required this.selectedProductIds,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
    required this.onOpen,
    required this.onShowTrend,
  });

  final List<ProductItem> products;
  final Set<int> selectedProductIds;
  final void Function(int productId, bool selected) onSelected;
  final ValueChanged<ProductItem> onEdit;
  final ValueChanged<int> onDelete;
  final ValueChanged<ProductItem> onOpen;
  final ValueChanged<ProductItem> onShowTrend;

  @override
  Widget build(BuildContext context) {
    return MavraResponsiveDataView<ProductItem>(
      rows: products,
      rowKey: (product) => ValueKey('product-${product.id}'),
      wideBreakpoint: 850,
      columns: const [
        DataColumn(label: Text('Select')),
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Platform')),
        DataColumn(label: Text('URL')),
        DataColumn(label: Text('Active')),
        DataColumn(label: Text('Actions')),
      ],
      tableCells: (product) => [
        DataCell(
          _SelectProductBox(
            product: product,
            selected: selectedProductIds.contains(product.id),
            onSelected: onSelected,
          ),
        ),
        DataCell(
          SizedBox(
            width: 260,
            child: Text(product.title, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(product.platform)),
        DataCell(
          SizedBox(
            width: 260,
            child: Text(product.url, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(product.enabled ? 'Active' : 'Inactive')),
        DataCell(
          _ProductActionButtons(
            product: product,
            dense: true,
            onOpen: onOpen,
            onEdit: onEdit,
            onDelete: onDelete,
            onShowTrend: onShowTrend,
          ),
        ),
      ],
      mobileBuilder: (context, product) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SelectProductBox(
                    product: product,
                    selected: selectedProductIds.contains(product.id),
                    onSelected: onSelected,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('${product.platform} - ${product.url}'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [Text(product.enabled ? 'Active' : 'Paused')],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ProductActionButtons(
                product: product,
                onOpen: onOpen,
                onEdit: onEdit,
                onDelete: onDelete,
                onShowTrend: onShowTrend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectProductBox extends StatelessWidget {
  const _SelectProductBox({
    required this.product,
    required this.selected,
    required this.onSelected,
  });

  final ProductItem product;
  final bool selected;
  final void Function(int productId, bool selected) onSelected;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      key: Key('product-select-${product.id}'),
      value: selected,
      onChanged: (value) => onSelected(product.id, value ?? false),
    );
  }
}

class _ProductActionButtons extends StatelessWidget {
  const _ProductActionButtons({
    required this.product,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onShowTrend,
    this.dense = false,
  });

  final ProductItem product;
  final ValueChanged<ProductItem> onOpen;
  final ValueChanged<ProductItem> onEdit;
  final ValueChanged<int> onDelete;
  final ValueChanged<ProductItem> onShowTrend;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return Wrap(
        spacing: 4,
        children: [
          IconButton(
            key: Key('product-open-${product.id}-button'),
            tooltip: 'Open ${product.title}',
            style: MavraButtonStyle.rowIconButton(context: context),
            onPressed: () => onOpen(product),
            icon: const Icon(Icons.open_in_new, size: 18),
          ),
          IconButton(
            key: Key('product-trend-${product.id}-button'),
            tooltip: 'Trend',
            style: MavraButtonStyle.rowIconButton(context: context),
            onPressed: () => onShowTrend(product),
            icon: const Icon(Icons.timeline, size: 18),
          ),
          IconButton(
            key: Key('product-edit-${product.id}-button'),
            tooltip: 'Edit ${product.title}',
            style: MavraButtonStyle.rowIconButton(context: context),
            onPressed: () => onEdit(product),
            icon: const Icon(Icons.edit, size: 18),
          ),
          IconButton(
            key: Key('product-delete-${product.id}-button'),
            tooltip: 'Delete',
            style: MavraButtonStyle.rowIconButton(
              context: context,
              isDangerous: true,
            ),
            onPressed: () => onDelete(product.id),
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        TextButton.icon(
          key: Key('product-open-${product.id}-button'),
          style: MavraButtonStyle.compactText(context: context),
          onPressed: () => onOpen(product),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Open'),
        ),
        TextButton.icon(
          key: Key('product-trend-${product.id}-button'),
          style: MavraButtonStyle.compactText(context: context),
          onPressed: () => onShowTrend(product),
          icon: const Icon(Icons.timeline, size: 18),
          label: const Text('Trend'),
        ),
        TextButton.icon(
          key: Key('product-edit-${product.id}-button'),
          style: MavraButtonStyle.compactText(context: context),
          onPressed: () => onEdit(product),
          icon: const Icon(Icons.edit, size: 18),
          label: Text('Edit ${product.title}'),
        ),
        TextButton.icon(
          key: Key('product-delete-${product.id}-button'),
          style: MavraButtonStyle.compactText(
            context: context,
            isDangerous: true,
          ),
          onPressed: () => onDelete(product.id),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}

class _ProductCrawlLogsTable extends StatelessWidget {
  const _ProductCrawlLogsTable({required this.logs});

  final List<ProductCrawlLog> logs;

  @override
  Widget build(BuildContext context) {
    return MavraResponsiveDataView<ProductCrawlLog>(
      key: const Key('product-crawl-logs-table'),
      rows: logs,
      rowKey: (log) => ValueKey('product-crawl-log-${_crawlLogKey(log)}'),
      wideBreakpoint: 720,
      columns: const [
        DataColumn(label: Text('Time')),
        DataColumn(label: Text('Platform')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Error')),
      ],
      tableCells: (log) => [
        DataCell(Text(_shortDateTime(log.createdAt))),
        DataCell(Text(_platformLabel(log.platform ?? '-'))),
        DataCell(Text(_crawlStatusLabel(log.status))),
        DataCell(Text(log.price ?? '-')),
        DataCell(_CrawlLogErrorCell(log: log)),
      ],
      mobileBuilder: (context, log) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long),
              title: Text(
                '${_platformLabel(log.platform ?? '-')} - ${log.price ?? '-'}',
              ),
              subtitle: Text(
                '${_crawlStatusLabel(log.status)} - ${_shortDateTime(log.createdAt)}\n${log.errorMessage ?? log.message}',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key(
                  'product-crawl-log-error-details-${_crawlLogKey(log)}-button',
                ),
                style: MavraButtonStyle.compactText(context: context),
                onPressed: () => _showCrawlLogDetails(context, log),
                icon: const Icon(Icons.notes, size: 18),
                label: const Text('Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrawlLogErrorCell extends StatelessWidget {
  const _CrawlLogErrorCell({required this.log});

  final ProductCrawlLog log;

  @override
  Widget build(BuildContext context) {
    final details = log.errorMessage ?? log.message;
    return SizedBox(
      width: 420,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Tooltip(
              message: details,
              child: Text(
                details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            key: Key(
              'product-crawl-log-error-details-${_crawlLogKey(log)}-button',
            ),
            tooltip: 'View full crawl log details',
            style: MavraButtonStyle.rowIconButton(context: context),
            onPressed: () => _showCrawlLogDetails(context, log),
            icon: const Icon(Icons.notes, size: 18),
          ),
        ],
      ),
    );
  }
}

String _crawlLogKey(ProductCrawlLog log) =>
    (log.id ?? log.createdAt.millisecondsSinceEpoch).toString();

Future<void> _showCrawlLogDetails(BuildContext context, ProductCrawlLog log) {
  final details = log.errorMessage ?? log.message;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Crawl log details'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(child: SelectableText(details)),
      ),
      actions: [
        TextButton(
          style: MavraButtonStyle.compactText(context: context),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _PriceTrendDialog extends StatefulWidget {
  const _PriceTrendDialog({required this.repository, required this.product});

  final ProductRepository repository;
  final ProductItem product;

  @override
  State<_PriceTrendDialog> createState() => _PriceTrendDialogState();
}

class _PriceTrendDialogState extends State<_PriceTrendDialog> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('product-price-trend-dialog'),
      title: Text('${widget.product.title} Price Trend'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: FutureBuilder<List<PriceHistoryPoint>>(
            future: widget.repository.getProductHistory(
              widget.product.id,
              days: _days,
            ),
            builder: (context, snapshot) {
              final history = snapshot.data ?? const <PriceHistoryPoint>[];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7d')),
                      ButtonSegment(value: 30, label: Text('30d')),
                      ButtonSegment(value: 90, label: Text('90d')),
                      ButtonSegment(value: 3650, label: Text('All')),
                    ],
                    selected: {_days},
                    onSelectionChanged: (selection) =>
                        setState(() => _days = selection.first),
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    _PriceStats(history: history),
                    const SizedBox(height: 12),
                    _PricePeriodChange(history: history),
                    const SizedBox(height: 12),
                    _PriceHistoryChart(history: history),
                    const SizedBox(height: 12),
                    _PriceHistoryTable(history: history),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PricePeriodChange extends StatelessWidget {
  const _PricePeriodChange({required this.history});

  final List<PriceHistoryPoint> history;

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return const SizedBox.shrink();
    }
    final first = _parsePrice(history.first.price);
    final last = _parsePrice(history.last.price);
    if (first <= 0) {
      return const SizedBox.shrink();
    }

    final diff = last - first;
    final percent = (diff / first * 100).abs();
    final label = diff < 0
        ? 'Drop ${percent.toStringAsFixed(1)}%'
        : diff > 0
        ? 'Rise ${percent.toStringAsFixed(1)}%'
        : 'Flat';

    return Chip(
      label: Text('Period change: $label'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PriceStats extends StatelessWidget {
  const _PriceStats({required this.history});

  final List<PriceHistoryPoint> history;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final point in history)
        if (_parsePrice(point.price) > 0) _parsePrice(point.price),
    ];
    final lowest = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a < b ? a : b);
    final highest = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    final current = values.isEmpty ? 0.0 : values.last;
    var drops = 0;
    for (var index = 1; index < values.length; index += 1) {
      if (values[index] < values[index - 1]) {
        drops += 1;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatPill(label: 'Lowest', value: _formatStatPrice(lowest)),
        _StatPill(label: 'Highest', value: _formatStatPrice(highest)),
        _StatPill(label: 'Current', value: _formatStatPrice(current)),
        _StatPill(label: 'Drops', value: '$drops'),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _PriceHistoryChart extends StatelessWidget {
  const _PriceHistoryChart({required this.history});

  final List<PriceHistoryPoint> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Text('No price history yet');
    }

    final values = [for (final point in history) _parsePrice(point.price)];
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(1.0, maxValue - minValue);
    final minY = math.max(0.0, minValue - range * 0.12);
    final maxY = maxValue + range * 0.12;
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      key: const Key('product-price-history-chart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price trend', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(context).dividerColor,
                  strokeWidth: 0.8,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: Theme.of(context).dividerColor,
                  strokeWidth: 0.8,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    getTitlesWidget: (value, meta) => Text(
                      '¥${value.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _chartLabelInterval(history.length),
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= history.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          history[index].label,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var index = 0; index < values.length; index++)
                      FlSpot(index.toDouble(), values[index]),
                  ],
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
              ],
              lineTouchData: const LineTouchData(enabled: true),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceHistoryTable extends StatelessWidget {
  const _PriceHistoryTable({required this.history});

  final List<PriceHistoryPoint> history;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('product-price-history-table'),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Price')),
        ],
        rows: [
          for (final point in history)
            DataRow(
              cells: [DataCell(Text(point.label)), DataCell(Text(point.price))],
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyText,
    required this.children,
    this.actions,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final action = actions;
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return DecoratedBox(
          decoration: MavraTableStyle.panelDecoration(context),
          child: Padding(
            padding: EdgeInsets.all(wide ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                    ?action,
                  ],
                ),
                Divider(
                  height: 24,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
                if (children.isEmpty) Text(emptyText) else ...children,
              ],
            ),
          ),
        );
      },
    );
  }
}

double _parsePrice(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(normalized) ?? 0;
}

double _chartLabelInterval(int count) {
  if (count <= 6) {
    return 1;
  }
  return (count / 6).ceilToDouble();
}

String _formatStatPrice(double value) {
  if (value == 0) {
    return '-';
  }
  final fixed = value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  return '¥$fixed';
}

String _crawlStatusLabel(String value) {
  return switch (value.toUpperCase()) {
    'SUCCESS' => 'Success',
    'ERROR' => 'Failed',
    'SKIPPED' => 'Skipped',
    _ => value,
  };
}

String _shortDateTime(DateTime value) {
  return '${value.month}/${value.day} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
