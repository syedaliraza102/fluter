import 'dart:async';

import 'package:flutter/material.dart';

import 'models/product.dart';
import 'product_service.dart';
import 'widgets/product_form_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.productService});

  final ProductService? productService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ProductService _productService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _loadError;
  List<Product> _products = [];
  bool _loadingProducts = true;
  StreamSubscription<List<Product>>? _productsSub;
  Timer? _loadTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _startListening();
  }

  void _startListening() {
    _productsSub?.cancel();
    _loadTimeoutTimer?.cancel();
    setState(() {
      _loadingProducts = true;
      _loadError = null;
    });

    _productsSub = _productService.watchProducts().listen(
      (products) {
        if (!mounted) return;
        setState(() {
          _products = products;
          _loadingProducts = false;
          _loadError = null;
        });
        _loadTimeoutTimer?.cancel();
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _loadError = e is ProductServiceException ? e.message : e.toString();
          _loadingProducts = false;
        });
        _loadTimeoutTimer?.cancel();
      },
    );

    _loadTimeoutTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted || !_loadingProducts) return;
      setState(() {
        _loadingProducts = false;
        _loadError =
            'Firestore connection timed out.\n\n'
            '1. Firebase Console → Build → Firestore Database\n'
            '2. Create database if missing (not Realtime Database)\n'
            '3. Rules → allow read/write on "products"\n'
            '4. Stop app and run: flutter run -d chrome';
      });
    });
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _loadTimeoutTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    return products
        .where((p) => p.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  Future<void> _showProductDialog({Product? product}) async {
    final isEditing = product != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ProductFormDialog(
        product: product,
        productService: _productService,
        onSaved: () {
          if (!mounted) return;
          setState(() => _loadError = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Product updated successfully'
                    : 'Product added successfully',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || product.id == null) return;

    try {
      await _productService.deleteProduct(product.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
      }
    } on ProductServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        centerTitle: true,
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_loadingProducts)
            const LinearProgressIndicator(minHeight: 2),
          if (_loadError != null)
            MaterialBanner(
              content: Text(_loadError!),
              leading: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              actions: [
                TextButton(
                  onPressed: _startListening,
                  child: const Text('Retry'),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by product name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_loadingProducts && _loadError == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to Firestore...'),
          ],
        ),
      );
    }

    if (_loadError != null && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Cannot load products',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final products = _filterProducts(_products);

    if (products.isEmpty) {
      final hasSearch = _searchQuery.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No products match your search' : 'No products yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 8),
              Text(
                'Tap + to add your first product',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          onEdit: () => _showProductDialog(product: product),
          onDelete: () => _confirmDelete(product),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderImage(theme),
                ),
              )
            else
              _placeholderImage(theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.attach_money,
                        label: product.price.toStringAsFixed(2),
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.inventory,
                        label: 'Stock: ${product.stock}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage(ThemeData theme) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_outlined, color: theme.colorScheme.outline),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
