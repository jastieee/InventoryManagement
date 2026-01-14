import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../services/firebase_inventory_service.dart';
import '../services/firebase_order_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _inventoryService = InventoryService();
  final _orderService = OrderService();

  List<Product> _products = [];
  List<Order> _orders = [];
  String _selectedPeriod = '7days'; // 7days, 30days, all
  bool _isLoading = true;  // ADD THIS LINE

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _inventoryService.getAllProducts();
      final orders = await _orderService.getAllOrders();

      setState(() {
        _products = products;
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dashboard refreshed!'),
          backgroundColor: Color(0xFF547792),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  List<Order> _getFilteredOrders() {
    if (_selectedPeriod == 'all') return _orders;

    final now = DateTime.now();
    final cutoffDate = _selectedPeriod == '7days'
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    return _orders.where((order) => order.createdAt.isAfter(cutoffDate)).toList();
  }

  double _getTotalRevenue() {
    return _getFilteredOrders()
        .where((order) => order.status == 'completed')
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  int _getTotalItemsSold() {
    return _getFilteredOrders()
        .where((order) => order.status == 'completed')
        .fold(0, (sum, order) => sum + order.totalItems);
  }

  List<Product> _getLowStockProducts() {
    return _products
        .where((p) => p.quantity <= p.lowStockThreshold && p.quantity > 0)
        .toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
  }

  List<Product> _getOutOfStockProducts() {
    return _products.where((p) => p.quantity == 0).toList();
  }

  List<Product> _getTopProducts() {
    // Count product quantities in orders
    final Map<String, int> productSales = {};

    for (var order in _getFilteredOrders()) {
      if (order.status == 'completed') {
        for (var item in order.items) {
          productSales[item.productId] =
              (productSales[item.productId] ?? 0) + item.quantity;
        }
      }
    }

    // Sort products by sales
    final topProductIds = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Filter to only include products that exist
    return topProductIds
        .take(5)
        .map((entry) {
      try {
        return _products.firstWhere((p) => p.id == entry.key);
      } catch (e) {
        return null;
      }
    })
        .where((product) => product != null)
        .cast<Product>()
        .toList();
  }

  void _showPeriodSelector() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEAE0CF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Period',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF213448),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildPeriodOption('Last 7 Days', '7days', isSmallScreen),
              _buildPeriodOption('Last 30 Days', '30days', isSmallScreen),
              _buildPeriodOption('All Time', 'all', isSmallScreen),
              SizedBox(height: isSmallScreen ? 8 : 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodOption(String title, String value, bool isSmallScreen) {
    final isSelected = _selectedPeriod == value;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
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
          _selectedPeriod = value;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;
    final isLargeScreen = size.width >= 600;
    final isExtraLargeScreen = size.width >= 900;

    final padding = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 20.0);

    return Scaffold(
      backgroundColor: const Color(0xFFEAE0CF),
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        backgroundColor: const Color(0xFF213448),
        foregroundColor: const Color(0xFFEAE0CF),
        elevation: 0,
        actions: [
          // Period Selector
          Container(
            margin: EdgeInsets.only(right: isSmallScreen ? 8 : 12),
            child: TextButton.icon(
              onPressed: _showPeriodSelector,
              icon: Icon(
                Icons.calendar_today,
                size: isSmallScreen ? 16 : 18,
                color: const Color(0xFFEAE0CF),
              ),
              label: Text(
                _selectedPeriod == '7days'
                    ? '7D'
                    : _selectedPeriod == '30days'
                    ? '30D'
                    : 'All',
                style: TextStyle(
                  color: const Color(0xFFEAE0CF),
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF547792).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 6,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF213448),
        ),
      )
          : RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF213448),
        backgroundColor: const Color(0xFFEAE0CF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: isExtraLargeScreen
              ? _buildExtraLargeLayout(padding)
              : isLargeScreen
              ? _buildLargeLayout(padding)
              : _buildSmallMediumLayout(padding, isSmallScreen, isMediumScreen),
        ),
      ),
    );
  }

  // Layout for extra large screens (desktop)
  Widget _buildExtraLargeLayout(double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Stats Grid - 4 columns
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Revenue',
                value: NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                    .format(_getTotalRevenue()),
                icon: Icons.attach_money,
                color: const Color(0xFF547792),
                isSmallScreen: false,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildStatCard(
                title: 'Total Orders',
                value: '${_getFilteredOrders().length}',
                icon: Icons.shopping_cart,
                color: const Color(0xFF94B4C1),
                isSmallScreen: false,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildStatCard(
                title: 'Items Sold',
                value: '${_getTotalItemsSold()}',
                icon: Icons.inventory_2,
                color: const Color(0xFF213448),
                isSmallScreen: false,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildStatCard(
                title: 'Products',
                value: '${_products.length}',
                icon: Icons.category,
                color: const Color(0xFF547792),
                isSmallScreen: false,
              ),
            ),
          ],
        ),
        SizedBox(height: padding),

        // Middle Row - Charts
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildCategorySalesCard(false, false),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildInventoryHealthCard(false, false),
            ),
          ],
        ),
        SizedBox(height: padding),

        // Bottom Row - Lists
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTopProductsCard(false, false),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildLowStockCard(false, false),
            ),
          ],
        ),
      ],
    );
  }

  // Layout for large screens (tablet)
  Widget _buildLargeLayout(double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Grid - 2x2
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Revenue',
                value: NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                    .format(_getTotalRevenue()),
                icon: Icons.attach_money,
                color: const Color(0xFF547792),
                isSmallScreen: false,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildStatCard(
                title: 'Total Orders',
                value: '${_getFilteredOrders().length}',
                icon: Icons.shopping_cart,
                color: const Color(0xFF94B4C1),
                isSmallScreen: false,
              ),
            ),
          ],
        ),
        SizedBox(height: padding),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Items Sold',
                value: '${_getTotalItemsSold()}',
                icon: Icons.inventory_2,
                color: const Color(0xFF213448),
                isSmallScreen: false,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildStatCard(
                title: 'Products',
                value: '${_products.length}',
                icon: Icons.category,
                color: const Color(0xFF547792),
                isSmallScreen: false,
              ),
            ),
          ],
        ),
        SizedBox(height: padding),

        // Two column layout for cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildCategorySalesCard(false, false),
                  SizedBox(height: padding),
                  _buildTopProductsCard(false, false),
                ],
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: Column(
                children: [
                  _buildInventoryHealthCard(false, false),
                  SizedBox(height: padding),
                  _buildLowStockCard(false, false),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Layout for small and medium screens (mobile)
  Widget _buildSmallMediumLayout(double padding, bool isSmallScreen, bool isMediumScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Grid - 2x2
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Revenue',
                value: NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                    .format(_getTotalRevenue()),
                icon: Icons.attach_money,
                color: const Color(0xFF547792),
                isSmallScreen: isSmallScreen,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildStatCard(
                title: 'Orders',
                value: '${_getFilteredOrders().length}',
                icon: Icons.shopping_cart,
                color: const Color(0xFF94B4C1),
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        ),
        SizedBox(height: padding),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Items Sold',
                value: '${_getTotalItemsSold()}',
                icon: Icons.inventory_2,
                color: const Color(0xFF213448),
                isSmallScreen: isSmallScreen,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildStatCard(
                title: 'Products',
                value: '${_products.length}',
                icon: Icons.category,
                color: const Color(0xFF547792),
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        ),
        SizedBox(height: padding),

        // Single column layout for cards
        _buildInventoryHealthCard(isSmallScreen, isMediumScreen),
        SizedBox(height: padding),
        _buildCategorySalesCard(isSmallScreen, isMediumScreen),
        SizedBox(height: padding),
        _buildTopProductsCard(isSmallScreen, isMediumScreen),
        SizedBox(height: padding),
        _buildLowStockCard(isSmallScreen, isMediumScreen),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                color: const Color(0xFF94B4C1),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 6),
            Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF213448),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryHealthCard(bool isSmallScreen, bool isMediumScreen) {
    final lowStock = _getLowStockProducts();
    final outOfStock = _getOutOfStockProducts();
    final inStock = _products.length - lowStock.length - outOfStock.length;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: const Color(0xFF213448),
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Inventory Health',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF213448),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildHealthItem(
              'In Stock',
              inStock,
              Colors.green,
              isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            _buildHealthItem(
              'Low Stock',
              lowStock.length,
              Colors.orange,
              isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            _buildHealthItem(
              'Out of Stock',
              outOfStock.length,
              Colors.red,
              isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String label, int count, Color color, bool isSmallScreen) {
    final total = _products.length;
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                color: const Color(0xFF547792),
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF213448),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: isSmallScreen ? 8 : 10,
          ),
        ),
      ],
    );
  }

  Map<String, double> _getCategorySales() {
    final Map<String, double> categorySales = {};

    for (var order in _getFilteredOrders()) {
      if (order.status == 'completed') {
        for (var item in order.items) {
          try {
            final product = _products.firstWhere((p) => p.id == item.productId);
            categorySales[product.category] =
                (categorySales[product.category] ?? 0) + item.totalPrice;
          } catch (e) {
            // Product not found, skip
            continue;
          }
        }
      }
    }

    return categorySales;
  }

  Widget _buildCategorySalesCard(bool isSmallScreen, bool isMediumScreen) {
    final categorySales = _getCategorySales();
    final sortedCategories = categorySales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFF547792),
      const Color(0xFF94B4C1),
      const Color(0xFF213448),
      Colors.orange,
      Colors.green,
      Colors.purple,
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: const Color(0xFF213448),
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sales by Category',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF213448),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            if (sortedCategories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No sales data available',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      color: const Color(0xFF547792),
                    ),
                  ),
                ),
              )
            else
              ...sortedCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final total = categorySales.values.fold(0.0, (sum, val) => sum + val);
                final percentage = (category.value / total * 100);

                return Padding(
                  padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              category.key,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 15,
                                color: const Color(0xFF547792),
                              ),
                            ),
                          ),
                          Text(
                            NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                                .format(category.value),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF213448),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: colors[index % colors.length]
                                    .withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    colors[index % colors.length]),
                                minHeight: isSmallScreen ? 8 : 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 13,
                              fontWeight: FontWeight.w600,
                              color: colors[index % colors.length],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsCard(bool isSmallScreen, bool isMediumScreen) {
    final topProducts = _getTopProducts();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.orange,
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Top Products',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF213448),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            if (topProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No sales data available',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      color: const Color(0xFF547792),
                    ),
                  ),
                ),
              )
            else
              ...topProducts.asMap().entries.map((entry) {
                final index = entry.key;
                final product = entry.value;

                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE0CF).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isSmallScreen ? 28 : 32,
                        height: isSmallScreen ? 28 : 32,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? Colors.amber
                              : index == 1
                              ? Colors.grey.shade400
                              : index == 2
                              ? Colors.brown.shade300
                              : const Color(0xFF94B4C1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF213448),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              product.category,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: const Color(0xFF547792),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                            .format(product.price),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF547792),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockCard(bool isSmallScreen, bool isMediumScreen) {
    final lowStockProducts = _getLowStockProducts().take(5).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.orange,
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Low Stock Alert',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF213448),
                    ),
                  ),
                ),
                if (lowStockProducts.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${lowStockProducts.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            if (lowStockProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: isSmallScreen ? 40 : 48,
                        color: Colors.green.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All products are well stocked!',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15,
                          color: const Color(0xFF547792),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...lowStockProducts.map((product) {
                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: Colors.orange,
                        size: isSmallScreen ? 18 : 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF213448),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              product.category,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: const Color(0xFF547792),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 10,
                          vertical: isSmallScreen ? 4 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.quantity} ${product.unit}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}