import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/firebase_inventory_service.dart';
import '../services/import_export_mixin.dart';

class ViewInventoryScreen extends StatefulWidget {
  const ViewInventoryScreen({super.key});

  @override
  State<ViewInventoryScreen> createState() => _ViewInventoryScreenState();
}

class _ViewInventoryScreenState extends State<ViewInventoryScreen>  with ImportExportMixin {

  final _inventoryService = InventoryService();
  final _searchController = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isGridView = true;
  String _sortBy = 'name_asc';
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Add this method to reload products after import
  @override
  void onImportComplete() {
    _loadProducts();  // Your existing load method
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _inventoryService.getAllProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
          _applyFiltersAndSort();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    List<Product> filtered = _products;

    // Apply search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query) ||
            product.id.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sort
    filtered = _sortProducts(filtered, _sortBy);

    setState(() {
      _filteredProducts = filtered;
    });
  }

  List<Product> _sortProducts(List<Product> products, String sortBy) {
    final sorted = List<Product>.from(products);

    switch (sortBy.toLowerCase()) {
      case 'name_asc':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'price_asc':
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'quantity_asc':
        sorted.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'quantity_desc':
        sorted.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      case 'value_asc':
        sorted.sort((a, b) => a.totalValue.compareTo(b.totalValue));
        break;
      case 'value_desc':
        sorted.sort((a, b) => b.totalValue.compareTo(a.totalValue));
        break;
      default:
        sorted.sort((a, b) => a.name.compareTo(b.name));
    }

    return sorted;
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _inventoryService.refreshInventory();
      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory refreshed!'),
            backgroundColor: Color(0xFF547792),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showSortOptions() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEAE0CF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sort By',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF213448),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSortOption('Name (A-Z)', 'name_asc', isSmallScreen),
                      _buildSortOption('Name (Z-A)', 'name_desc', isSmallScreen),
                      _buildSortOption('Price (Low to High)', 'price_asc', isSmallScreen),
                      _buildSortOption('Price (High to Low)', 'price_desc', isSmallScreen),
                      _buildSortOption('Quantity (Low to High)', 'quantity_asc', isSmallScreen),
                      _buildSortOption('Quantity (High to Low)', 'quantity_desc', isSmallScreen),
                      _buildSortOption('Value (Low to High)', 'value_asc', isSmallScreen),
                      _buildSortOption('Value (High to Low)', 'value_desc', isSmallScreen),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value, bool isSmallScreen) {
    final isSelected = _sortBy == value;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: 0,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isSmallScreen ? 13 : 15,
          color: isSelected ? const Color(0xFF213448) : const Color(0xFF547792),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
        Icons.check,
        color: const Color(0xFF213448),
        size: isSmallScreen ? 20 : 24,
      )
          : null,
      onTap: () {
        setState(() {
          _sortBy = value;
          _applyFiltersAndSort();
        });
        Navigator.pop(context);
      },
    );
  }

  Color _getStockColor(Product product) {
    if (product.quantity == 0) return Colors.red;
    if (product.quantity <= product.lowStockThreshold) return Colors.red;
    if (product.quantity <= product.lowStockThreshold * 2) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStockBadge(Product product, bool isSmallScreen) {
    final color = _getStockColor(product);
    final status = product.stockStatus;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: isSmallScreen ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'Out of Stock'
                ? Icons.cancel
                : status == 'Low Stock'
                ? Icons.warning
                : Icons.check_circle,
            color: Colors.white,
            size: isSmallScreen ? 12 : 14,
          ),
          SizedBox(width: isSmallScreen ? 3 : 4),
          Text(
            status,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 9 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;
    final isLargeScreen = size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFEAE0CF),
      appBar: AppBar(
        title: Text(
          'View Inventory',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: const Color(0xFF213448),
        foregroundColor: const Color(0xFFEAE0CF),
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            iconSize: isSmallScreen ? 22 : 24,
            onPressed: showImportExportOptions,  // From mixin
            tooltip: 'Import/Export',
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            iconSize: isSmallScreen ? 22 : 24,
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            iconSize: isSmallScreen ? 22 : 24,
            onPressed: _showSortOptions,
            tooltip: 'Sort',
          ),
          SizedBox(width: isSmallScreen ? 4 : 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: const Color(0xFF213448),
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 12 : (isMediumScreen ? 16 : 20),
              0,
              isSmallScreen ? 12 : (isMediumScreen ? 16 : 20),
              isSmallScreen ? 12 : (isMediumScreen ? 16 : 20),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _applyFiltersAndSort(),
              style: TextStyle(
                color: const Color(0xFFEAE0CF),
                fontSize: isSmallScreen ? 14 : 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(
                  color: const Color(0xFFEAE0CF).withOpacity(0.6),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFFEAE0CF),
                  size: isSmallScreen ? 20 : 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: const Color(0xFFEAE0CF),
                    size: isSmallScreen ? 20 : 24,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _applyFiltersAndSort();
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFF547792).withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
            ),
          ),

          // Product List/Grid
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF213448),
              ),
            )
                : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF213448),
              backgroundColor: const Color(0xFFEAE0CF),
              child: _filteredProducts.isEmpty
                  ? LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: isSmallScreen ? 60 : 80,
                              color: const Color(0xFF547792).withOpacity(0.5),
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No products found'
                                  : 'No products available',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                color: const Color(0xFF547792).withOpacity(0.7),
                              ),
                            ),
                            if (_searchController.text.isEmpty) ...[
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Text(
                                'Pull down to refresh',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: const Color(0xFF547792).withOpacity(0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
                  : _isGridView
                  ? _buildGridView(isSmallScreen, isMediumScreen, isLargeScreen)
                  : _buildListView(isSmallScreen, isMediumScreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
    final padding = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 20.0);
    final spacing = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 20.0);

    int crossAxisCount;
    if (isSmallScreen) {
      crossAxisCount = 2;
    } else if (isMediumScreen) {
      crossAxisCount = 2;
    } else if (MediaQuery.of(context).size.width < 900) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 4;
    }

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: isSmallScreen ? 0.72 : 0.75,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product, isSmallScreen, isMediumScreen);
      },
    );
  }

  Widget _buildListView(bool isSmallScreen, bool isMediumScreen) {
    final padding = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 20.0);

    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductListTile(product, isSmallScreen, isMediumScreen);
      },
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen, bool isMediumScreen) {
    final cardPadding = isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 16.0);
    final nameFontSize = isSmallScreen ? 13.0 : (isMediumScreen ? 14.0 : 16.0);
    final categoryFontSize = isSmallScreen ? 10.0 : (isMediumScreen ? 11.0 : 12.0);
    final priceFontSize = isSmallScreen ? 12.0 : (isMediumScreen ? 13.0 : 15.0);
    final quantityFontSize = isSmallScreen ? 11.0 : (isMediumScreen ? 12.0 : 14.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Badge
            _buildStockBadge(product, isSmallScreen),

            SizedBox(height: isSmallScreen ? 8 : 12),

            // Product Name
            Text(
              product.name,
              style: TextStyle(
                fontSize: nameFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF213448),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: isSmallScreen ? 4 : 8),

            // Category
            Text(
              product.category,
              style: TextStyle(
                fontSize: categoryFontSize,
                color: const Color(0xFF547792),
              ),
            ),

            const Spacer(),

            Divider(
              color: const Color(0xFF94B4C1),
              height: isSmallScreen ? 16 : 20,
            ),

            // Quantity
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  size: isSmallScreen ? 14 : 16,
                  color: const Color(0xFF547792),
                ),
                SizedBox(width: isSmallScreen ? 3 : 4),
                Flexible(
                  child: Text(
                    '${product.quantity} ${product.unit}',
                    style: TextStyle(
                      fontSize: quantityFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF213448),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: isSmallScreen ? 3 : 4),

            // Price
            Text(
              NumberFormat.currency(symbol: '₱', decimalDigits: 2)
                  .format(product.price),
              style: TextStyle(
                fontSize: priceFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF547792),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListTile(Product product, bool isSmallScreen, bool isMediumScreen) {
    final tilePadding = isSmallScreen ? 12.0 : (isMediumScreen ? 14.0 : 16.0);
    final iconSize = isSmallScreen ? 48.0 : (isMediumScreen ? 56.0 : 60.0);
    final iconInnerSize = isSmallScreen ? 26.0 : (isMediumScreen ? 30.0 : 32.0);
    final nameFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 17.0);
    final categoryFontSize = isSmallScreen ? 10.0 : (isMediumScreen ? 11.0 : 12.0);
    final quantityFontSize = isSmallScreen ? 11.0 : (isMediumScreen ? 12.0 : 13.0);
    final priceFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 17.0);
    final spacing = isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 16.0);

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(tilePadding),
        child: Row(
          children: [
            // Stock Indicator (circular)
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: _getStockColor(product).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                product.quantity == 0
                    ? Icons.cancel
                    : product.quantity <= product.lowStockThreshold
                    ? Icons.warning
                    : Icons.check_circle,
                color: _getStockColor(product),
                size: iconInnerSize,
              ),
            ),

            SizedBox(width: spacing),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF213448),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 3 : 4),
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: categoryFontSize,
                      color: const Color(0xFF547792),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Wrap(
                    spacing: isSmallScreen ? 8 : 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Qty: ${product.quantity} ${product.unit}',
                        style: TextStyle(
                          fontSize: quantityFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF213448),
                        ),
                      ),
                      _buildStockBadge(product, isSmallScreen),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: spacing),

            // Price
            Text(
              NumberFormat.currency(symbol: '₱', decimalDigits: 2)
                  .format(product.price),
              style: TextStyle(
                fontSize: priceFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF547792),
              ),
            ),
          ],
        ),
      ),
    );
  }
}