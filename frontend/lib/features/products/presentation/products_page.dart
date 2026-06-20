import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/files/file_service.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_chart.dart';
import '../../../core/widgets/mavra_confirm.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../domain/product_models.dart';

typedef ProductUrlOpener = FutureOr<void> Function(String url);

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
  String? _statusMessage;
  int? _editingProductId;
  int? _editingAlertId;
  bool _productActive = true;
  bool _alertEnabled = false;
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
    setState(() {
      _error = null;
      _productsFuture = Future.sync(widget.repository.loadProducts)
        ..then((snapshot) {
          if (!mounted) {
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
        }).catchError((Object error) {
          if (mounted) {
            setState(() => _error = error);
          }
        });
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
      setState(() {
        _statusMessage = 'Saved ${draft.title}';
      });
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
        _statusMessage = 'Loaded ${page.total} products';
      });
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
      setState(() => _statusMessage = 'Imported ${rows.length} products');
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
        _statusMessage = 'Deleted product #$productId';
        _selectedProductIds.remove(productId);
      });
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
      setState(() => _statusMessage = 'Select products to delete');
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
        _statusMessage = 'Deleted ${ids.length} products';
        _selectedProductIds.clear();
      });
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
      setState(() => _statusMessage = 'Crawl task requested');
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Crawl request failed');
      }
    }
  }

  Future<void> _deleteProductCron(ProductCronConfig cron) async {
    final confirmed = await mavraConfirm(
      context,
      title: 'Delete platform cron',
      message: 'Delete ${cron.platform} cron schedule?',
      confirmKey: Key('product-cron-${cron.platform}-delete-confirm-button'),
      confirmLabel: 'Delete',
    );
    if (!confirmed) {
      return;
    }

    try {
      await widget.repository.deleteProductSchedule(cron.platform);
      if (mounted) {
        setState(() => _statusMessage = 'Deleted ${cron.platform} cron');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
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
        setState(() => _statusMessage = 'Could not open ${product.title}');
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
                  statusMessage: _statusMessage,
                  canRequestCrawlNow: _canRequestCrawlNow,
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
                  onOpenSchedule: () => context.go('/schedule'),
                  onDeleteProductCron: _deleteProductCron,
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
    required this.statusMessage,
    required this.canRequestCrawlNow,
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
    required this.onOpenSchedule,
    required this.onDeleteProductCron,
  });

  final ProductsSnapshot snapshot;
  final ProductPageState? page;
  final String? statusMessage;
  final bool canRequestCrawlNow;
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
  final VoidCallback onOpenSchedule;
  final ValueChanged<ProductCronConfig> onDeleteProductCron;

  @override
  Widget build(BuildContext context) {
    final productsSectionKey = GlobalKey();
    final logsSectionKey = GlobalKey();
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
          const _ProductPageIntro(),
          if (statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(statusMessage!),
          ],
          const SizedBox(height: 16),
          _ProductSectionTabs(
            onProductsTap: () => _scrollTo(productsSectionKey),
            onCrawlLogsTap: () => _scrollTo(logsSectionKey),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1100;
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
              final sidePanel = _ScheduleConfigPanel(
                cronConfigs: snapshot.cronConfigs,
                onOpenSchedule: onOpenSchedule,
                onDeleteProductCron: onDeleteProductCron,
              );
              final logsPanel = _Section(
                title: 'Crawl Logs',
                emptyText: 'No crawl logs yet',
                children: [
                  for (final log in snapshot.crawlLogs)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long),
                      title: Text(log.message),
                      subtitle: Text(
                        '${log.status} - ${_shortDateTime(log.createdAt)}',
                      ),
                    ),
                ],
              );

              if (!wide) {
                return Column(
                  children: [
                    KeyedSubtree(key: productsSectionKey, child: productsPanel),
                    const SizedBox(height: 16),
                    sidePanel,
                    const SizedBox(height: 16),
                    KeyedSubtree(key: logsSectionKey, child: logsPanel),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        KeyedSubtree(
                          key: productsSectionKey,
                          child: productsPanel,
                        ),
                        const SizedBox(height: 16),
                        KeyedSubtree(key: logsSectionKey, child: logsPanel),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: sidePanel),
                ],
              );
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

  static void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      return;
    }
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
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
    required this.onProductsTap,
    required this.onCrawlLogsTap,
  });

  final VoidCallback onProductsTap;
  final VoidCallback onCrawlLogsTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Wrap(
        spacing: 28,
        children: [
          TextButton(
            onPressed: onProductsTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(bottom: 10),
              shape: const RoundedRectangleBorder(),
              foregroundColor: color.onSurface,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color.primary, width: 2),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Products'),
              ),
            ),
          ),
          TextButton(
            onPressed: onCrawlLogsTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(bottom: 18),
              shape: const RoundedRectangleBorder(),
              foregroundColor: color.onSurfaceVariant,
            ),
            child: const Text('Crawl Logs'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleConfigPanel extends StatelessWidget {
  const _ScheduleConfigPanel({
    required this.cronConfigs,
    required this.onOpenSchedule,
    required this.onDeleteProductCron,
  });

  final List<ProductCronConfig> cronConfigs;
  final VoidCallback onOpenSchedule;
  final ValueChanged<ProductCronConfig> onDeleteProductCron;

  @override
  Widget build(BuildContext context) {
    final configsByPlatform = {
      for (final config in cronConfigs) config.platform: config,
    };
    final rows = [
      for (final platform in _productPlatforms)
        configsByPlatform[platform] ??
            ProductCronConfig(
              platform: platform,
              cron: 'Unset',
              configured: false,
            ),
    ];

    return _Section(
      title: 'Schedule Config',
      emptyText: 'No schedule config yet',
      actions: OutlinedButton.icon(
        key: const Key('product-schedule-add-button'),
        onPressed: onOpenSchedule,
        icon: const Icon(Icons.add),
        label: const Text('Add Schedule'),
      ),
      children: [
        Text(
          'Product Crawl Schedule Config',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        MavraResponsiveDataView<ProductCronConfig>(
          rows: rows,
          wideBreakpoint: 520,
          columns: const [
            DataColumn(label: Text('Platform')),
            DataColumn(label: Text('Cron Expression')),
            DataColumn(label: Text('Timezone')),
            DataColumn(label: Text('Actions')),
          ],
          tableCells: (row) => [
            DataCell(Text(_platformLabel(row.platform))),
            DataCell(
              row.configured
                  ? Text(row.cron)
                  : const Chip(label: Text('Unset')),
            ),
            DataCell(Text(row.timezone)),
            DataCell(
              _ScheduleActions(
                row: row,
                onOpenSchedule: onOpenSchedule,
                onDeleteProductCron: onDeleteProductCron,
              ),
            ),
          ],
          mobileBuilder: (context, row) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_platformLabel(row.platform)),
            subtitle: Text(
              row.configured ? '${row.cron} - ${row.timezone}' : 'Unset',
            ),
            trailing: _ScheduleActions(
              row: row,
              onOpenSchedule: onOpenSchedule,
              onDeleteProductCron: onDeleteProductCron,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Schedule controls when to crawl products automatically.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ScheduleActions extends StatelessWidget {
  const _ScheduleActions({
    required this.row,
    required this.onOpenSchedule,
    required this.onDeleteProductCron,
  });

  final ProductCronConfig row;
  final VoidCallback onOpenSchedule;
  final ValueChanged<ProductCronConfig> onDeleteProductCron;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        IconButton(
          key: Key('product-cron-${row.platform}-edit-button'),
          tooltip: 'Edit ${row.platform} schedule',
          onPressed: onOpenSchedule,
          icon: const Icon(Icons.edit_calendar),
        ),
        IconButton(
          key: Key('product-cron-${row.platform}-delete-button'),
          tooltip: 'Delete ${row.platform} schedule',
          onPressed: row.configured ? () => onDeleteProductCron(row) : null,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _ProductPageIntro extends StatelessWidget {
  const _ProductPageIntro();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prices', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              'Product Management',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text(
              'Track Taobao, JD, and Amazon products, schedule crawls, and review price movement.',
            ),
          ],
        ),
      ),
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
              icon: const Icon(Icons.travel_explore),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const Key('product-import-open-button'),
              onPressed: onImportProducts,
              icon: const Icon(Icons.upload_file),
              label: const Text('Batch Import'),
            ),
            KeyedSubtree(
              key: const Key('product-batch-delete-confirm-button'),
              child: OutlinedButton.icon(
                key: const Key('product-batch-delete-button'),
                onPressed: selectedCount == 0 ? null : onBatchDeleteProducts,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Batch Delete'),
              ),
            ),
            FilledButton.icon(
              key: const Key('product-add-button'),
              onPressed: onNewProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                key: const Key('product-search-field'),
                controller: searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search title or URL',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    key: const Key('product-clear-search-button'),
                    tooltip: 'Clear search',
                    onPressed: onClearSearch,
                    icon: const Icon(Icons.clear),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<String?>(
                key: const Key('product-platform-filter'),
                initialValue: platformValue,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Platform'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Platforms')),
                  DropdownMenuItem(value: 'taobao', child: Text('Taobao')),
                  DropdownMenuItem(value: 'jd', child: Text('JD')),
                  DropdownMenuItem(value: 'amazon', child: Text('Amazon')),
                ],
                selectedItemBuilder: (context) => const [
                  Text('All', overflow: TextOverflow.ellipsis),
                  Text('Taobao', overflow: TextOverflow.ellipsis),
                  Text('JD', overflow: TextOverflow.ellipsis),
                  Text('Amazon', overflow: TextOverflow.ellipsis),
                ],
                onChanged: onPlatformFilterChanged,
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                key: const Key('product-active-filter'),
                initialValue: activeFilter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                selectedItemBuilder: (context) => const [
                  Text('All', overflow: TextOverflow.ellipsis),
                  Text('Active', overflow: TextOverflow.ellipsis),
                  Text('Inactive', overflow: TextOverflow.ellipsis),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onActiveFilterChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
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
          child: DropdownButtonFormField<int>(
            key: const Key('product-page-size-field'),
            initialValue: _normalizedPageSize(pageSize),
            decoration: const InputDecoration(labelText: 'Page size'),
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
            onPressed: () => onOpen(product),
            icon: const Icon(Icons.open_in_new),
          ),
          IconButton(
            key: Key('product-trend-${product.id}-button'),
            tooltip: 'Trend',
            onPressed: () => onShowTrend(product),
            icon: const Icon(Icons.timeline),
          ),
          IconButton(
            key: Key('product-edit-${product.id}-button'),
            tooltip: 'Edit ${product.title}',
            onPressed: () => onEdit(product),
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            key: Key('product-delete-${product.id}-button'),
            tooltip: 'Delete',
            onPressed: () => onDelete(product.id),
            icon: const Icon(Icons.delete_outline),
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
          onPressed: () => onOpen(product),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open'),
        ),
        TextButton.icon(
          key: Key('product-trend-${product.id}-button'),
          onPressed: () => onShowTrend(product),
          icon: const Icon(Icons.timeline),
          label: const Text('Trend'),
        ),
        TextButton.icon(
          key: Key('product-edit-${product.id}-button'),
          onPressed: () => onEdit(product),
          icon: const Icon(Icons.edit),
          label: Text('Edit ${product.title}'),
        ),
        TextButton.icon(
          key: Key('product-delete-${product.id}-button'),
          onPressed: () => onDelete(product.id),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
        ),
      ],
    );
  }
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
                    _PriceHistoryChart(history: history),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final point in history)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(point.label),
                              trailing: Text(point.price),
                            ),
                        ],
                      ),
                    ),
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

    return MavraTrendChart(
      title: 'Price trend',
      points: [
        for (final point in history)
          MavraChartPoint(label: point.label, value: _parsePrice(point.price)),
      ],
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (actions != null) ...[
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              ],
            ),
            const Divider(height: 20),
            if (children.isEmpty) Text(emptyText) else ...children,
          ],
        ),
      ),
    );
  }
}

double _parsePrice(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(normalized) ?? 0;
}

String _formatStatPrice(double value) {
  if (value == 0) {
    return '-';
  }
  final fixed = value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  return '¥$fixed';
}

String _shortDateTime(DateTime value) {
  return '${value.month}/${value.day} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
