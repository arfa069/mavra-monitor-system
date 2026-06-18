import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/files/file_service.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_chart.dart';
import '../../../core/widgets/mavra_confirm.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../domain/product_models.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    required this.repository,
    this.fileService,
    this.permissions,
  });

  final ProductRepository repository;
  final FileService? fileService;
  final Set<String>? permissions;

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
  bool _showForm = false;
  bool _alertEnabled = false;
  final Set<int> _selectedProductIds = {};

  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _platformController = TextEditingController();
  final _searchController = TextEditingController();
  final _filterPlatformController = TextEditingController();
  final _pageSizeController = TextEditingController(text: '20');
  String _activeFilter = 'all';

  FileService get _fileService =>
      widget.fileService ??
      FileService.forCapabilities(PlatformCapabilities.current());

  bool get _canRequestCrawlNow =>
      widget.permissions == null ||
      widget.permissions!.contains('crawl:execute');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
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
    _titleController.dispose();
    _urlController.dispose();
    _platformController.dispose();
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
            _page = snapshot.page.items.isEmpty
                ? ProductPageState(
                    items: snapshot.products,
                    page: 1,
                    pageSize: snapshot.products.length,
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
    setState(() {
      _editingProductId = null;
      _showForm = true;
      _alertEnabled = false;
      _titleController.clear();
      _urlController.clear();
      _platformController.clear();
    });
  }

  void _editProduct(ProductItem product) {
    setState(() {
      _editingProductId = product.id;
      _showForm = true;
      _alertEnabled = false;
      _titleController.text = product.title;
      _urlController.text = product.url;
      _platformController.text = product.platform;
    });
  }

  Future<void> _saveProduct() async {
    final draft = ProductDraft(
      title: _titleController.text.trim(),
      url: _urlController.text.trim(),
      platform: _platformController.text.trim(),
    );

    try {
      await widget.repository.saveProduct(draft, productId: _editingProductId);
      final productId = _editingProductId;
      if (productId != null) {
        await widget.repository.saveAlert(
          productId,
          ProductAlertDraft(
            enabled: _alertEnabled,
            alertType: 'price_change',
            thresholdPercent: 5,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Saved ${draft.title}';
        _showForm = false;
      });
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _applyFilters() async {
    final pageSize = int.tryParse(_pageSizeController.text.trim()) ?? 20;
    final active = switch (_activeFilter) {
      'active' => true,
      'inactive' => false,
      _ => null,
    };

    final query = ProductListQuery(
      keyword: _emptyToNull(_searchController.text),
      platform: _emptyToNull(_filterPlatformController.text),
      active: active,
      pageSize: pageSize,
    );

    try {
      final page = await widget.repository.listProducts(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _page = page;
        _statusMessage = 'Loaded ${page.total} products';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _importProducts() async {
    try {
      final file = await _fileService.pickFile();
      if (file == null) {
        return;
      }
      await widget.repository.importProducts(file);
      if (!mounted) {
        return;
      }
      setState(() => _statusMessage = 'Imported ${file.name}');
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

  Future<void> _saveProfileBinding(ProductProfileBinding binding) async {
    try {
      await widget.repository.saveProfileBinding(
        platform: binding.platform,
        profileKey: binding.profileName,
      );
      if (mounted) {
        setState(() => _statusMessage = 'Saved ${binding.platform} binding');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _saveProductCron(ProductCronConfig cron) async {
    try {
      await widget.repository.saveProductSchedule(
        platform: cron.platform,
        cronExpression: cron.cron,
      );
      if (mounted) {
        setState(() => _statusMessage = 'Saved ${cron.platform} cron');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
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
  }

  void _showPriceTrend(ProductItem product) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Price trend: ${product.title}'),
        content: SizedBox(
          width: 420,
          child: _PriceHistoryChart(history: _snapshot?.history ?? const []),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
                  showForm: _showForm,
                  alertEnabled: _alertEnabled,
                  titleController: _titleController,
                  urlController: _urlController,
                  platformController: _platformController,
                  searchController: _searchController,
                  filterPlatformController: _filterPlatformController,
                  pageSizeController: _pageSizeController,
                  activeFilter: _activeFilter,
                  selectedProductIds: _selectedProductIds,
                  onActiveFilterChanged: (value) =>
                      setState(() => _activeFilter = value),
                  onAlertEnabledChanged: (value) =>
                      setState(() => _alertEnabled = value),
                  onApplyFilters: _applyFilters,
                  onNewProduct: _newProduct,
                  onImportProducts: _importProducts,
                  onSaveProduct: _saveProduct,
                  onEditProduct: _editProduct,
                  onDeleteProduct: _deleteProduct,
                  onBatchDeleteProducts: _batchDeleteProducts,
                  onRequestCrawlNow: _requestCrawlNow,
                  onProductSelected: _toggleProductSelection,
                  onClearSearch: _clearSearch,
                  onShowTrend: _showPriceTrend,
                  onSaveProfileBinding: _saveProfileBinding,
                  onSaveProductCron: _saveProductCron,
                  onDeleteProductCron: _deleteProductCron,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _ProductsContent extends StatelessWidget {
  const _ProductsContent({
    required this.snapshot,
    required this.page,
    required this.statusMessage,
    required this.canRequestCrawlNow,
    required this.showForm,
    required this.alertEnabled,
    required this.titleController,
    required this.urlController,
    required this.platformController,
    required this.searchController,
    required this.filterPlatformController,
    required this.pageSizeController,
    required this.activeFilter,
    required this.selectedProductIds,
    required this.onActiveFilterChanged,
    required this.onAlertEnabledChanged,
    required this.onApplyFilters,
    required this.onNewProduct,
    required this.onImportProducts,
    required this.onSaveProduct,
    required this.onEditProduct,
    required this.onDeleteProduct,
    required this.onBatchDeleteProducts,
    required this.onRequestCrawlNow,
    required this.onProductSelected,
    required this.onClearSearch,
    required this.onShowTrend,
    required this.onSaveProfileBinding,
    required this.onSaveProductCron,
    required this.onDeleteProductCron,
  });

  final ProductsSnapshot snapshot;
  final ProductPageState? page;
  final String? statusMessage;
  final bool canRequestCrawlNow;
  final bool showForm;
  final bool alertEnabled;
  final TextEditingController titleController;
  final TextEditingController urlController;
  final TextEditingController platformController;
  final TextEditingController searchController;
  final TextEditingController filterPlatformController;
  final TextEditingController pageSizeController;
  final String activeFilter;
  final Set<int> selectedProductIds;
  final ValueChanged<String> onActiveFilterChanged;
  final ValueChanged<bool> onAlertEnabledChanged;
  final Future<void> Function() onApplyFilters;
  final VoidCallback onNewProduct;
  final VoidCallback onImportProducts;
  final Future<void> Function() onSaveProduct;
  final ValueChanged<ProductItem> onEditProduct;
  final ValueChanged<int> onDeleteProduct;
  final Future<void> Function() onBatchDeleteProducts;
  final Future<void> Function() onRequestCrawlNow;
  final void Function(int productId, bool selected) onProductSelected;
  final VoidCallback onClearSearch;
  final ValueChanged<ProductItem> onShowTrend;
  final ValueChanged<ProductProfileBinding> onSaveProfileBinding;
  final ValueChanged<ProductCronConfig> onSaveProductCron;
  final ValueChanged<ProductCronConfig> onDeleteProductCron;

  @override
  Widget build(BuildContext context) {
    final products = _filterProducts(page?.items ?? snapshot.products);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductsHeader(
            canRequestCrawlNow: canRequestCrawlNow,
            onImportProducts: onImportProducts,
            onRequestCrawlNow: onRequestCrawlNow,
            onNewProduct: onNewProduct,
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(statusMessage!),
          ],
          if (showForm) ...[
            const SizedBox(height: 12),
            _ProductForm(
              titleController: titleController,
              urlController: urlController,
              platformController: platformController,
              alertEnabled: alertEnabled,
              onAlertEnabledChanged: onAlertEnabledChanged,
              onSave: onSaveProduct,
            ),
          ],
          const SizedBox(height: 16),
          _ProductFilters(
            searchController: searchController,
            platformController: filterPlatformController,
            pageSizeController: pageSizeController,
            activeFilter: activeFilter,
            selectedCount: selectedProductIds.length,
            onActiveFilterChanged: onActiveFilterChanged,
            onApplyFilters: onApplyFilters,
            onClearSearch: onClearSearch,
            onBatchDeleteProducts: onBatchDeleteProducts,
          ),
          const SizedBox(height: 12),
          if (snapshot.products.isEmpty)
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
              onShowTrend: onShowTrend,
            ),
          const SizedBox(height: 20),
          _Section(
            title: 'Price history',
            emptyText: 'No price history yet',
            children: [
              if (snapshot.history.isNotEmpty)
                _PriceHistoryChart(history: snapshot.history),
              for (final point in snapshot.history)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timeline),
                  title: Text('${point.label}: ${point.price}'),
                ),
            ],
          ),
          _Section(
            title: 'Profile binding',
            emptyText: 'No profile binding yet',
            children: [
              for (final binding in snapshot.bindings)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.account_tree),
                  title: Text(binding.profileName),
                  subtitle: Text(binding.platform),
                  trailing: FilledButton.tonalIcon(
                    key: Key(
                      'product-profile-binding-${binding.platform}-button',
                    ),
                    onPressed: () => onSaveProfileBinding(binding),
                    icon: const Icon(Icons.link),
                    label: const Text('Bind'),
                  ),
                ),
            ],
          ),
          _Section(
            title: 'Platform cron',
            emptyText: 'No platform cron yet',
            children: [
              for (final cron in snapshot.cronConfigs)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(cron.cron),
                  subtitle: Text(cron.platform),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        key: Key('product-cron-${cron.platform}-edit-button'),
                        tooltip: 'Edit ${cron.platform} cron',
                        onPressed: () => onSaveProductCron(cron),
                        icon: const Icon(Icons.edit_calendar),
                      ),
                      IconButton(
                        key: Key('product-cron-${cron.platform}-delete-button'),
                        tooltip: 'Delete ${cron.platform} cron',
                        onPressed: () => onDeleteProductCron(cron),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _Section(
            title: 'Crawl logs',
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

class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader({
    required this.canRequestCrawlNow,
    required this.onImportProducts,
    required this.onRequestCrawlNow,
    required this.onNewProduct,
  });

  final bool canRequestCrawlNow;
  final VoidCallback onImportProducts;
  final Future<void> Function() onRequestCrawlNow;
  final VoidCallback onNewProduct;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: Text(
            'Products',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        TextButton.icon(
          key: const Key('product-import-open-button'),
          onPressed: onImportProducts,
          icon: const Icon(Icons.upload_file),
          label: const Text('Batch import'),
        ),
        OutlinedButton.icon(
          key: const Key('product-crawl-now-button'),
          onPressed: canRequestCrawlNow ? onRequestCrawlNow : null,
          icon: const Icon(Icons.travel_explore),
          label: const Text('Crawl now'),
        ),
        FilledButton.icon(
          onPressed: onNewProduct,
          icon: const Icon(Icons.add),
          label: const Text('New product'),
        ),
      ],
    );
  }
}

class _ProductFilters extends StatelessWidget {
  const _ProductFilters({
    required this.searchController,
    required this.platformController,
    required this.pageSizeController,
    required this.activeFilter,
    required this.selectedCount,
    required this.onActiveFilterChanged,
    required this.onApplyFilters,
    required this.onClearSearch,
    required this.onBatchDeleteProducts,
  });

  final TextEditingController searchController;
  final TextEditingController platformController;
  final TextEditingController pageSizeController;
  final String activeFilter;
  final int selectedCount;
  final ValueChanged<String> onActiveFilterChanged;
  final Future<void> Function() onApplyFilters;
  final VoidCallback onClearSearch;
  final Future<void> Function() onBatchDeleteProducts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            key: const Key('product-search-field'),
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search products',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          width: 180,
          child: TextField(
            key: const Key('product-platform-filter'),
            controller: platformController,
            decoration: const InputDecoration(labelText: 'Platform'),
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            key: const Key('product-page-size-field'),
            controller: pageSizeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Page size'),
          ),
        ),
        SegmentedButton<String>(
          key: const Key('product-active-filter'),
          segments: const [
            ButtonSegment(value: 'all', label: Text('All')),
            ButtonSegment(value: 'active', label: Text('Active')),
            ButtonSegment(value: 'inactive', label: Text('Inactive')),
          ],
          selected: {activeFilter},
          onSelectionChanged: (selection) =>
              onActiveFilterChanged(selection.first),
        ),
        IconButton(
          key: const Key('product-clear-search-button'),
          tooltip: 'Clear search',
          onPressed: onClearSearch,
          icon: const Icon(Icons.clear),
        ),
        FilledButton.icon(
          key: const Key('product-apply-filters-button'),
          onPressed: onApplyFilters,
          icon: const Icon(Icons.filter_alt),
          label: const Text('Apply'),
        ),
        KeyedSubtree(
          key: const Key('product-batch-delete-confirm-button'),
          child: FilledButton.icon(
            key: const Key('product-batch-delete-button'),
            onPressed: onBatchDeleteProducts,
            icon: const Icon(Icons.delete_sweep),
            label: Text('Delete selected ($selectedCount)'),
          ),
        ),
      ],
    );
  }
}

class _ProductForm extends StatelessWidget {
  const _ProductForm({
    required this.titleController,
    required this.urlController,
    required this.platformController,
    required this.alertEnabled,
    required this.onAlertEnabledChanged,
    required this.onSave,
  });

  final TextEditingController titleController;
  final TextEditingController urlController;
  final TextEditingController platformController;
  final bool alertEnabled;
  final ValueChanged<bool> onAlertEnabledChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product form',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
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
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('product-platform-field'),
              controller: platformController,
              decoration: const InputDecoration(labelText: 'Platform'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('product-alert-enabled-field'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Price alert enabled'),
              value: alertEnabled,
              onChanged: onAlertEnabledChanged,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('Save product'),
            ),
          ],
        ),
      ),
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
    required this.onShowTrend,
  });

  final List<ProductItem> products;
  final Set<int> selectedProductIds;
  final void Function(int productId, bool selected) onSelected;
  final ValueChanged<ProductItem> onEdit;
  final ValueChanged<int> onDelete;
  final ValueChanged<ProductItem> onShowTrend;

  @override
  Widget build(BuildContext context) {
    return MavraResponsiveDataView<ProductItem>(
      rows: products,
      wideBreakpoint: 960,
      columns: const [
        DataColumn(label: Text('Select')),
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Platform')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Status')),
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
        DataCell(Text(product.currentPrice)),
        DataCell(Text(product.enabled ? 'Active' : 'Paused')),
        DataCell(
          _ProductActionButtons(
            product: product,
            dense: true,
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
                    children: [
                      Text(product.currentPrice),
                      Text(product.enabled ? 'Active' : 'Paused'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ProductActionButtons(
                product: product,
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
    required this.onEdit,
    required this.onDelete,
    required this.onShowTrend,
    this.dense = false,
  });

  final ProductItem product;
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
            onPressed: () {},
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
          onPressed: () {},
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
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (children.isEmpty) Text(emptyText) else ...children,
        ],
      ),
    );
  }
}

double _parsePrice(String value) {
  final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(normalized) ?? 0;
}

String _shortDateTime(DateTime value) {
  return '${value.month}/${value.day} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
