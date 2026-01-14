import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../services/firebase_inventory_service.dart';
import '../services/firebase_order_service.dart';
import '../services/firebase_auth_service.dart';

class OrderingScreen extends StatefulWidget {
  const OrderingScreen({super.key});

  @override
  State<OrderingScreen> createState() => _OrderingScreenState();
}

class _OrderingScreenState extends State<OrderingScreen> {
  final _inventoryService = InventoryService();
  final _orderService = OrderService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final Map<String, int> _cart = {}; // productId -> quantity
  bool _isProcessing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Updated to async Firebase call
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _inventoryService.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = _products.where((p) => p.quantity > 0).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Updated to async Firebase call
  Future<void> _filterProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products.where((p) => p.quantity > 0).toList();
      });
    } else {
      try {
        final searchResults = await _inventoryService.searchProducts(query);
        setState(() {
          _filteredProducts = searchResults.where((p) => p.quantity > 0).toList();
        });
      } catch (e) {
        print('Error searching products: $e');
      }
    }
  }

  void _addToCart(Product product) {
    setState(() {
      final currentQty = _cart[product.id] ?? 0;
      if (currentQty < product.quantity) {
        _cart[product.id] = currentQty + 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            backgroundColor: const Color(0xFF547792),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum stock reached for ${product.name}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      final currentQty = _cart[productId] ?? 0;
      if (currentQty > 1) {
        _cart[productId] = currentQty - 1;
      } else {
        _cart.remove(productId);
      }
    });
  }

  void _updateCartQuantity(String productId, int quantity, int maxStock) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(productId);
      } else if (quantity <= maxStock) {
        _cart[productId] = quantity;
      }
    });
  }

  double _calculateTotal() {
    double total = 0;
    _cart.forEach((productId, quantity) {
      final product = _products.firstWhere((p) => p.id == productId);
      total += product.price * quantity;
    });
    return total;
  }

  int _getTotalItems() {
    return _cart.values.fold(0, (sum, qty) => sum + qty);
  }

  void _showCart() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEAE0CF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF213448),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      color: Color(0xFFEAE0CF),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Cart',
                            style: TextStyle(
                              color: const Color(0xFFEAE0CF),
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_getTotalItems()} items',
                            style: TextStyle(
                              color: const Color(0xFF94B4C1),
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFFEAE0CF)),
                    ),
                  ],
                ),
              ),

              // Cart Items
              Flexible(
                child: _cart.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: const Color(0xFF547792).withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF547792).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  itemCount: _cart.length,
                  itemBuilder: (context, index) {
                    final productId = _cart.keys.elementAt(index);
                    final quantity = _cart[productId]!;
                    final product = _products.firstWhere((p) => p.id == productId);

                    return _buildCartItem(product, quantity, isSmallScreen);
                  },
                ),
              ),

              // Notes Section
              if (_cart.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                  child: TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Add notes (optional)',
                      hintStyle: const TextStyle(color: Color(0xFF547792)),
                      prefixIcon: const Icon(Icons.note, color: Color(0xFF547792)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF94B4C1)),
                      ),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Total and Checkout
              if (_cart.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF213448),
                            ),
                          ),
                          Text(
                            NumberFormat.currency(symbol: '₱', decimalDigits: 2)
                                .format(_calculateTotal()),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF547792),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _processOrder,
                          icon: _isProcessing
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEAE0CF),
                            ),
                          )
                              : const Icon(Icons.check_circle),
                          label: Text(
                            _isProcessing ? 'Processing...' : 'Place Order',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF213448),
                            foregroundColor: const Color(0xFFEAE0CF),
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
        ),
    );
  }

  Widget _buildCartItem(Product product, int quantity, bool isSmallScreen) {
    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
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
                    product.name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF213448),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(product.price),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: const Color(0xFF547792),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _removeFromCart(product.id),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFF547792),
                  iconSize: isSmallScreen ? 20 : 24,
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 12,
                    vertical: isSmallScreen ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF213448).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$quantity',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF213448),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _addToCart(product),
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF213448),
                  iconSize: isSmallScreen ? 20 : 24,
                ),
              ],
            ),
            Text(
              NumberFormat.currency(symbol: '₱', decimalDigits: 0)
                  .format(product.price * quantity),
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF213448),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated to async Firebase call
  Future<void> _processOrder() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // CALCULATE TOTAL AND ITEMS *BEFORE* CLEARING THE CART
      final totalAmount = _calculateTotal();
      final totalItems = _getTotalItems();

      // Create order items
      final orderItems = _cart.entries.map((entry) {
        final product = _products.firstWhere((p) => p.id == entry.key);
        return OrderItem(
          productId: product.id,
          productName: product.name,
          quantity: entry.value,
          price: product.price,
          unit: product.unit ?? 'pcs',
        );
      }).toList();

      // Get current user
      final currentUser = _authService.currentUser;

      // Create order - await the async call
      final result = await _orderService.createOrder(
        userId: currentUser?.id ?? '',
        userName: currentUser?.name ?? 'Guest',
        items: orderItems,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context); // Close cart

        if (result['success']) {
          // Clear cart and notes AFTER saving the values
          setState(() {
            _cart.clear();
            _notesController.clear();
          });

          // Reload products to show updated stock
          await _loadProducts();

          // Show success dialog with the SAVED values
          _showSuccessDialog(
            result['orderId'] as String,
            totalAmount,
            totalItems,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing order: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Updated to show orderId instead of full order object
  void _showSuccessDialog(String orderId, double totalAmount, int totalItems) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEAE0CF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isSmallScreen ? 60 : 80,
              height: isSmallScreen ? 60 : 80,
              decoration: const BoxDecoration(
                color: Color(0xFF547792),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                color: const Color(0xFFEAE0CF),
                size: isSmallScreen ? 40 : 50,
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Text(
              'Order Placed Successfully!',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF213448),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'Order ID: $orderId',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: const Color(0xFF547792),
              ),
            ),
            SizedBox(height: isSmallScreen ? 4 : 8),
            Text(
              NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(totalAmount),
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF213448),
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              '$totalItems items ordered',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                color: const Color(0xFF547792),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF213448),
                foregroundColor: const Color(0xFFEAE0CF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
              ),
              child: Text(
                'Continue',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFEAE0CF),
      appBar: AppBar(
        title: Text(
          'Ordering Simulation',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        backgroundColor: const Color(0xFF213448),
        foregroundColor: const Color(0xFFEAE0CF),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                iconSize: isSmallScreen ? 24 : 28,
                onPressed: _showCart,
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_getTotalItems()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
              onChanged: _filterProducts,
              style: const TextStyle(color: Color(0xFFEAE0CF)),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(
                  color: const Color(0xFFEAE0CF).withOpacity(0.6),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFEAE0CF)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFFEAE0CF)),
                  onPressed: () {
                    _searchController.clear();
                    _filterProducts('');
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFF547792).withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF213448),
              ),
            )
                : _filteredProducts.isEmpty
                ? Center(
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
                        : 'No products available in stock',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      color: const Color(0xFF547792).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadProducts,
              color: const Color(0xFF213448),
              child: ListView.builder(
                padding: EdgeInsets.all(isSmallScreen ? 12 : (isMediumScreen ? 16 : 20)),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return _buildProductCard(product, isSmallScreen, isMediumScreen);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen, bool isMediumScreen) {
    final inCart = _cart.containsKey(product.id);
    final cartQuantity = _cart[product.id] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
      elevation: inCart ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: inCart
            ? const BorderSide(color: Color(0xFF213448), width: 2)
            : BorderSide.none,
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : (isMediumScreen ? 14 : 16)),
        child: Row(
          children: [
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : (isMediumScreen ? 16 : 18),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF213448),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: isSmallScreen ? 14 : 16,
                        color: const Color(0xFF547792),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: const Color(0xFF547792),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.inventory_2,
                        size: isSmallScreen ? 14 : 16,
                        color: const Color(0xFF547792),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.quantity} ${product.unit} left',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: const Color(0xFF547792),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(product.price),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : (isMediumScreen ? 18 : 20),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF547792),
                    ),
                  ),
                ],
              ),
            ),

            // Add to Cart Button
            if (inCart)
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF213448).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF213448),
                      size: isSmallScreen ? 16 : 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'In Cart ($cartQuantity)',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF213448),
                      ),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _addToCart(product),
                icon: Icon(
                  Icons.add_shopping_cart,
                  size: isSmallScreen ? 18 : 20,
                ),
                label: Text(
                  'Add',
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF213448),
                  foregroundColor: const Color(0xFFEAE0CF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}