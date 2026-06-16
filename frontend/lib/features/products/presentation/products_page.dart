import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/files/file_service.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../domain/product_models.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.repository, this.fileService});

  final ProductRepository repository;
  final FileService? fileService;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  Future<ProductsSnapshot>? _productsFuture;
  ProductsSnapshot? _snapshot;
  Object? _error;
  String? _statusMessage;
  int? _editingProductId;
  bool _showForm = false;

  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _platformController = TextEditingController();

  FileService get _fileService =>
      widget.fileService ??
      FileService.forCapabilities(PlatformCapabilities.current());

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _snapshot = null;
      _load();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _platformController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _error = null;
      _productsFuture = Future.sync(widget.repository.loadProducts)
        ..then((snapshot) {
          if (mounted) {
            setState(() {
              _snapshot = snapshot;
            });
          }
        }).catchError((Object error) {
          if (mounted) {
            setState(() {
              _error = error;
            });
          }
        });
    });
  }

  void _newProduct() {
    setState(() {
      _editingProductId = null;
      _showForm = true;
      _titleController.clear();
      _urlController.clear();
      _platformController.clear();
    });
  }

  void _editProduct(ProductItem product) {
    setState(() {
      _editingProductId = product.id;
      _showForm = true;
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
      setState(() {
        _statusMessage = 'Imported ${file.name}';
      });
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
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
                  statusMessage: _statusMessage,
                  showForm: _showForm,
                  titleController: _titleController,
                  urlController: _urlController,
                  platformController: _platformController,
                  onNewProduct: _newProduct,
                  onImportProducts: _importProducts,
                  onSaveProduct: _saveProduct,
                  onEditProduct: _editProduct,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsContent extends StatelessWidget {
  const _ProductsContent({
    required this.snapshot,
    required this.statusMessage,
    required this.showForm,
    required this.titleController,
    required this.urlController,
    required this.platformController,
    required this.onNewProduct,
    required this.onImportProducts,
    required this.onSaveProduct,
    required this.onEditProduct,
  });

  final ProductsSnapshot snapshot;
  final String? statusMessage;
  final bool showForm;
  final TextEditingController titleController;
  final TextEditingController urlController;
  final TextEditingController platformController;
  final VoidCallback onNewProduct;
  final VoidCallback onImportProducts;
  final Future<void> Function() onSaveProduct;
  final ValueChanged<ProductItem> onEditProduct;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Products',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton.icon(
                onPressed: onImportProducts,
                icon: const Icon(Icons.upload_file),
                label: const Text('Batch import'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onNewProduct,
                icon: const Icon(Icons.add),
                label: const Text('New product'),
              ),
            ],
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
              onSave: onSaveProduct,
            ),
          ],
          const SizedBox(height: 16),
          if (snapshot.products.isEmpty)
            const Center(child: Text('No products yet'))
          else
            for (final product in snapshot.products)
              _ProductTile(product: product, onEdit: onEditProduct),
          const SizedBox(height: 20),
          _Section(
            title: 'Price history',
            emptyText: 'No price history yet',
            children: [
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
                  subtitle: Text(log.status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductForm extends StatelessWidget {
  const _ProductForm({
    required this.titleController,
    required this.urlController,
    required this.platformController,
    required this.onSave,
  });

  final TextEditingController titleController;
  final TextEditingController urlController;
  final TextEditingController platformController;
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

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onEdit});

  final ProductItem product;
  final ValueChanged<ProductItem> onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          product.enabled ? Icons.check_circle : Icons.pause_circle,
        ),
        title: Text(product.title),
        subtitle: Text('${product.platform} - ${product.url}'),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(product.currentPrice),
            TextButton(
              onPressed: () => onEdit(product),
              child: Text('Edit ${product.title}'),
            ),
          ],
        ),
      ),
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
