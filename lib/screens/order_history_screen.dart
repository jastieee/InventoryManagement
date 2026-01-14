import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/firebase_order_service.dart';
import '../services/firebase_auth_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _orderService = OrderService();
  final _authService = AuthService();
  final _searchController = TextEditingController();

  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  String _filterStatus = 'all';
  String _sortBy = 'date_desc';
  bool _isLoading = true;
  double _totalSales = 0.0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      List<Order> orders;

      if (currentUser?.role == 'admin') {
        orders = await _orderService.getAllOrders();
        _totalSales = await _orderService.getTotalSales();
      } else {
        final userId = currentUser?.id ?? '';
        if (userId.isNotEmpty) {
          orders = await _orderService.getOrdersByUserId(userId);
        } else {
          orders = [];
        }
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });

      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    List<Order> filtered = _orders;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        return order.id.toLowerCase().contains(query) ||
            order.userName.toLowerCase().contains(query) ||
            order.items.any((item) =>
                item.productName.toLowerCase().contains(query));
      }).toList();
    }

    if (_filterStatus != 'all') {
      filtered = filtered.where((order) => order.status == _filterStatus).toList();
    }

    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }

    setState(() {
      _filteredOrders = filtered;
    });
  }

  void _showFilterOptions() {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Responsive sizing
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    final isLargeScreen = screenWidth >= 600;

    final horizontalPadding = isSmallScreen ? 16.0 : (isMediumScreen ? 20.0 : 24.0);
    final verticalPadding = isSmallScreen ? 12.0 : 16.0;
    final titleSize = isSmallScreen ? 18.0 : (isMediumScreen ? 20.0 : 22.0);
    final sectionTitleSize = isSmallScreen ? 14.0 : (isMediumScreen ? 15.0 : 16.0);
    final chipFontSize = isSmallScreen ? 11.0 : (isMediumScreen ? 12.0 : 13.0);
    final sortItemFontSize = isSmallScreen ? 12.5 : (isMediumScreen ? 14.0 : 15.0);

    // Calculate max height based on screen size
    final maxHeight = screenHeight * (isSmallScreen ? 0.75 : 0.7);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEAE0CF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            maxWidth: isLargeScreen ? 500 : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF213448).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF213448),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF547792)),
                      iconSize: isSmallScreen ? 20 : 24,
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status Filter Section
                      Row(
                        children: [
                          Icon(
                            Icons.filter_alt_outlined,
                            size: isSmallScreen ? 16 : 18,
                            color: const Color(0xFF547792),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status Filter',
                            style: TextStyle(
                              fontSize: sectionTitleSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF547792),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 10 : 12),
                      Wrap(
                        spacing: isSmallScreen ? 6 : 8,
                        runSpacing: isSmallScreen ? 6 : 8,
                        children: [
                          _buildFilterChip('All', 'all', chipFontSize),
                          _buildFilterChip('Completed', 'completed', chipFontSize),
                          _buildFilterChip('Cancelled', 'cancelled', chipFontSize),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Sort Options Section
                      Row(
                        children: [
                          Icon(
                            Icons.sort,
                            size: isSmallScreen ? 16 : 18,
                            color: const Color(0xFF547792),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sort By',
                            style: TextStyle(
                              fontSize: sectionTitleSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF547792),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),

                      // Sort options as compact list
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF94B4C1).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildSortOption(
                              'Date (Newest First)',
                              'date_desc',
                              Icons.arrow_downward,
                              sortItemFontSize,
                              isFirst: true,
                            ),
                            _buildDivider(),
                            _buildSortOption(
                              'Date (Oldest First)',
                              'date_asc',
                              Icons.arrow_upward,
                              sortItemFontSize,
                            ),
                            _buildDivider(),
                            _buildSortOption(
                              'Amount (High to Low)',
                              'amount_desc',
                              Icons.trending_down,
                              sortItemFontSize,
                            ),
                            _buildDivider(),
                            _buildSortOption(
                              'Amount (Low to High)',
                              'amount_asc',
                              Icons.trending_up,
                              sortItemFontSize,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: verticalPadding),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFF94B4C1).withOpacity(0.2),
    );
  }

  Widget _buildFilterChip(String label, String value, double fontSize) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: isSelected ? const Color(0xFFEAE0CF) : const Color(0xFF213448),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
          _applyFiltersAndSort();
        });
        Navigator.pop(context);
      },
      selectedColor: const Color(0xFF213448),
      backgroundColor: Colors.white,
      checkmarkColor: const Color(0xFFEAE0CF),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSortOption(
      String title,
      String value,
      IconData icon,
      double fontSize, {
        bool isFirst = false,
        bool isLast = false,
      }) {
    final isSelected = _sortBy == value;
    return InkWell(
      onTap: () {
        setState(() {
          _sortBy = value;
          _applyFiltersAndSort();
        });
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(12) : Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: fontSize + 2,
              color: isSelected ? const Color(0xFF213448) : const Color(0xFF547792),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: fontSize,
                  color: isSelected ? const Color(0xFF213448) : const Color(0xFF547792),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF213448),
                size: fontSize + 4,
              ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    final padding = isSmallScreen ? 14.0 : (isMediumScreen ? 16.0 : 20.0);
    final titleSize = isSmallScreen ? 18.0 : (isMediumScreen ? 20.0 : 22.0);
    final subtitleSize = isSmallScreen ? 12.0 : 14.0;
    final maxHeight = screenHeight * 0.85;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEAE0CF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            maxWidth: screenWidth >= 600 ? 500 : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(padding),
                decoration: const BoxDecoration(
                  color: Color(0xFF213448),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Details',
                            style: TextStyle(
                              color: const Color(0xFFEAE0CF),
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 3 : 4),
                          Text(
                            order.id,
                            style: TextStyle(
                              color: const Color(0xFF94B4C1),
                              fontSize: subtitleSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFFEAE0CF)),
                      iconSize: isSmallScreen ? 20 : 24,
                    ),
                  ],
                ),
              ),

              // Order Info
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Order Summary Card
                      _buildOrderSummaryCard(order, isSmallScreen),
                      SizedBox(height: padding),

                      // Items Title
                      Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF213448),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // Order Items
                      ...order.items.map((item) => _buildOrderItemCard(item, isSmallScreen)),
                      SizedBox(height: isSmallScreen ? 10 : 12),

                      // Total Amount Card
                      _buildTotalCard(order.totalAmount, isSmallScreen),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(Order order, bool isSmallScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              icon: Icons.person,
              label: 'Customer',
              value: order.userName,
              isSmallScreen: isSmallScreen,
            ),
            const Divider(height: 20),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt),
              isSmallScreen: isSmallScreen,
            ),
            const Divider(height: 20),
            _buildInfoRow(
              icon: Icons.shopping_bag,
              label: 'Items',
              value: '${order.totalItems} items',
              isSmallScreen: isSmallScreen,
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: isSmallScreen ? 16 : 18,
                  color: const Color(0xFF547792),
                ),
                const SizedBox(width: 12),
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: const Color(0xFF547792),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 10,
                    vertical: isSmallScreen ? 4 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: order.status == 'completed' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 10 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const Divider(height: 20),
              _buildInfoRow(
                icon: Icons.note,
                label: 'Notes',
                value: order.notes!,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item, bool isSmallScreen) {
    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF213448),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 3 : 4),
                  Text(
                    '${item.quantity} ${item.unit} × ${NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(item.price)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 13,
                      color: const Color(0xFF547792),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(item.totalPrice),
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF213448),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(double totalAmount, bool isSmallScreen) {
    return Card(
      elevation: 3,
      color: const Color(0xFF213448),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEAE0CF),
              ),
            ),
            Text(
              NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(totalAmount),
              style: TextStyle(
                fontSize: isSmallScreen ? 17 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF94B4C1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 16 : 18,
          color: const Color(0xFF547792),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: const Color(0xFF547792),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF213448),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;
    final currentUser = _authService.currentUser;
    final isAdmin = currentUser?.role == 'admin';

    final padding = isSmallScreen ? 12.0 : (isMediumScreen ? 16.0 : 20.0);

    return Scaffold(
      backgroundColor: const Color(0xFFEAE0CF),
      appBar: AppBar(
        title: Text(
          'Order History',
          style: TextStyle(fontSize: isSmallScreen ? 17 : 19),
        ),
        backgroundColor: const Color(0xFF213448),
        foregroundColor: const Color(0xFFEAE0CF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            iconSize: isSmallScreen ? 20 : 22,
            onPressed: _showFilterOptions,
            tooltip: 'Filter & Sort',
          ),
          SizedBox(width: isSmallScreen ? 4 : 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: const Color(0xFF213448),
            padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _applyFiltersAndSort(),
              style: TextStyle(
                color: const Color(0xFFEAE0CF),
                fontSize: isSmallScreen ? 13 : 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search orders...',
                hintStyle: TextStyle(
                  color: const Color(0xFFEAE0CF).withOpacity(0.6),
                  fontSize: isSmallScreen ? 13 : 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: const Color(0xFFEAE0CF),
                  size: isSmallScreen ? 18 : 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: const Color(0xFFEAE0CF),
                    size: isSmallScreen ? 18 : 20,
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
                  horizontal: isSmallScreen ? 10 : 14,
                  vertical: isSmallScreen ? 10 : 12,
                ),
              ),
            ),
          ),

          // Summary Stats (for admin)
          if (isAdmin && _orders.isNotEmpty && !_isLoading)
            Container(
              margin: EdgeInsets.fromLTRB(padding, padding * 0.8, padding, padding * 0.6),
              padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${_orders.length}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 17 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF213448),
                          ),
                        ),
                        Text(
                          'Total Orders',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: const Color(0xFF547792),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: isSmallScreen ? 32 : 36,
                    color: const Color(0xFF94B4C1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                                .format(_totalSales),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF547792),
                            ),
                          ),
                        ),
                        Text(
                          'Total Sales',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: const Color(0xFF547792),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF213448)),
            )
                : _filteredOrders.isEmpty
                ? Center(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: isSmallScreen ? 50 : 70,
                      color: const Color(0xFF547792).withOpacity(0.5),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 14),
                    Text(
                      _searchController.text.isNotEmpty
                          ? 'No orders found'
                          : 'No orders yet',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 17,
                        color: const Color(0xFF547792).withOpacity(0.7),
                      ),
                    ),
                    if (_searchController.text.isEmpty) ...[
                      SizedBox(height: isSmallScreen ? 6 : 10),
                      Text(
                        'Your order history will appear here',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: const Color(0xFF547792).withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadOrders,
              color: const Color(0xFF213448),
              child: ListView.builder(
                padding: EdgeInsets.all(padding),
                itemCount: _filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = _filteredOrders[index];
                  return _buildOrderCard(order, isSmallScreen, isMediumScreen, isAdmin);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, bool isSmallScreen, bool isMediumScreen, bool isAdmin) {
    final cardPadding = isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 14.0);

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.id,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF213448),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 3 : 4),
                        Text(
                          DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: const Color(0xFF547792),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 7 : 9,
                      vertical: isSmallScreen ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: order.status == 'completed' ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 8.5 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 8 : 10),

              // Customer Name (for admin)
              if (isAdmin) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: isSmallScreen ? 13 : 15,
                      color: const Color(0xFF547792),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        order.userName,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          color: const Color(0xFF547792),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
              ],

              // Order Details
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE0CF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 9 : 10,
                              color: const Color(0xFF94B4C1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.totalItems} items',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF213448),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: isSmallScreen ? 28 : 32,
                      color: const Color(0xFF94B4C1).withOpacity(0.3),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: const Color(0xFF94B4C1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              NumberFormat.currency(symbol: '₱', decimalDigits: 2)
                                  .format(order.totalAmount),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF547792),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}