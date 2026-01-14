import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/firebase_inventory_service.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  final _inventoryService = InventoryService();
  final _searchController = TextEditingController();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _sortBy = 'name_asc';
  bool _isLoading = true;  // ADD THIS LINE

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
      setState(() {
        _products = products;
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
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  Future<void> _applyFiltersAndSort() async {
    List<Product> filtered = _products;

    if (_searchController.text.isNotEmpty) {
      filtered = await _inventoryService.searchProducts(_searchController.text);
    }

    filtered = _inventoryService.sortProducts(filtered, _sortBy);

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _showSortOptions() {
    final size = MediaQuery
        .of(context)
        .size;
    final isSmallScreen = size.width < 360;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFEAE0CF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery
                    .of(context)
                    .size
                    .height * 0.7,
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
                          _buildSortOption(
                              'Name (A-Z)', 'name_asc', isSmallScreen),
                          _buildSortOption(
                              'Name (Z-A)', 'name_desc', isSmallScreen),
                          _buildSortOption('Price (Low to High)', 'price_asc',
                              isSmallScreen),
                          _buildSortOption('Price (High to Low)', 'price_desc',
                              isSmallScreen),
                          _buildSortOption(
                              'Quantity (Low to High)', 'quantity_asc',
                              isSmallScreen),
                          _buildSortOption(
                              'Quantity (High to Low)', 'quantity_desc',
                              isSmallScreen),
                          _buildSortOption('Value (Low to High)', 'value_asc',
                              isSmallScreen),
                          _buildSortOption('Value (High to Low)', 'value_desc',
                              isSmallScreen),
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

  void _showAddProductDialog() {
    _showProductFormDialog(null);
  }

  void _showEditProductDialog(Product product) {
    _showProductFormDialog(product);
  }

  void _showProductFormDialog(Product? product) {
    final isEdit = product != null;
    final size = MediaQuery
        .of(context)
        .size;
    final isSmallScreen = size.width < 360;

    final nameController = TextEditingController(text: product?.name ?? '');
    final descController = TextEditingController(
        text: product?.description ?? '');
    final categoryController = TextEditingController(
        text: product?.category ?? '');
    final priceController = TextEditingController(
      text: product != null ? product.price.toString() : '',
    );
    final quantityController = TextEditingController(
      text: product != null ? product.quantity.toString() : '',
    );
    final thresholdController = TextEditingController(
      text: product != null ? product.lowStockThreshold.toString() : '10',
    );
    final barcodeController = TextEditingController(
        text: product?.barcode ?? '');
    final supplierController = TextEditingController(
        text: product?.supplier ?? '');
    final unitController = TextEditingController(text: product?.unit ?? 'pcs');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFFEAE0CF),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              isEdit ? 'Edit Product' : 'Add New Product',
              style: TextStyle(
                color: const Color(0xFF213448),
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : 20,
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: nameController,
                      label: 'Product Name',
                      icon: Icons.inventory_2,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    _buildTextField(
                      controller: descController,
                      label: 'Description',
                      icon: Icons.description,
                      maxLines: 2,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    _buildTextField(
                      controller: categoryController,
                      label: 'Category',
                      icon: Icons.category,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: priceController,
                            label: 'Price (₱)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Required';
                              if (double.tryParse(v!) == null) return 'Invalid';
                              return null;
                            },
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: _buildTextField(
                            controller: quantityController,
                            label: 'Quantity',
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Required';
                              if (int.tryParse(v!) == null) return 'Invalid';
                              return null;
                            },
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: unitController,
                            label: 'Unit',
                            icon: Icons.straighten,
                            validator: (v) =>
                            v?.isEmpty ?? true
                                ? 'Required'
                                : null,
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: _buildTextField(
                            controller: thresholdController,
                            label: 'Low Stock Alert',
                            icon: Icons.warning,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Required';
                              if (int.tryParse(v!) == null) return 'Invalid';
                              return null;
                            },
                            isSmallScreen: isSmallScreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    _buildTextField(
                      controller: barcodeController,
                      label: 'Barcode (Optional)',
                      icon: Icons.qr_code,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    _buildTextField(
                      controller: supplierController,
                      label: 'Supplier (Optional)',
                      icon: Icons.store,
                      isSmallScreen: isSmallScreen,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: const Color(0xFF547792),
                    fontSize: isSmallScreen ? 13 : 15,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newProduct = Product(
                      id: product?.id ?? 'P${DateTime
                          .now()
                          .millisecondsSinceEpoch}',
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      category: categoryController.text.trim(),
                      price: double.parse(priceController.text),
                      quantity: int.parse(quantityController.text),
                      lowStockThreshold: int.parse(thresholdController.text),
                      barcode: barcodeController.text
                          .trim()
                          .isEmpty
                          ? null
                          : barcodeController.text.trim(),
                      supplier: supplierController.text
                          .trim()
                          .isEmpty
                          ? null
                          : supplierController.text.trim(),
                      unit: unitController.text.trim(),
                      lastUpdated: DateTime.now(),
                    );

                    if (isEdit) {
                      _inventoryService.updateProduct(newProduct);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product updated successfully!'),
                          backgroundColor: Color(0xFF547792),
                        ),
                      );
                    } else {
                      _inventoryService.addProduct(newProduct);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product added successfully!'),
                          backgroundColor: Color(0xFF547792),
                        ),
                      );
                    }

                    _loadProducts();
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF213448),
                  foregroundColor: const Color(0xFFEAE0CF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEdit ? 'Update' : 'Add',
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    required bool isSmallScreen,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: const Color(0xFF213448),
        fontSize: isSmallScreen ? 13 : 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: const Color(0xFF547792),
          fontSize: isSmallScreen ? 12 : 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF547792),
            size: isSmallScreen ? 20 : 24),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF94B4C1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF94B4C1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF213448), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 12 : 16,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    final size = MediaQuery
        .of(context)
        .size;
    final isSmallScreen = size.width < 360;

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            backgroundColor: const Color(0xFFEAE0CF),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Delete Product',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : 20,
              ),
            ),
            content: Text(
              'Are you sure you want to delete "${product
                  .name}"? This action cannot be undone.',
              style: TextStyle(
                color: const Color(0xFF213448),
                fontSize: isSmallScreen ? 13 : 15,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: const Color(0xFF547792),
                    fontSize: isSmallScreen ? 13 : 15,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {  // Add async here
                  Navigator.pop(context); // Close confirmation dialog

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Color(0xFF213448)),
                    ),
                  );

                  try {
                    final result = await _inventoryService.deleteProduct(product.id);

                    if (mounted) {
                      Navigator.pop(context); // Close loading

                      if (result['success']) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} deleted'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                        await _loadProducts();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message']),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting product: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
                ),
              ),
            ],
          ),
    );
  }

  Color _getStockColor(Product product) {
    if (product.quantity == 0) return Colors.red;
    if (product.quantity <= product.lowStockThreshold) return Colors.red;
    if (product.quantity <= product.lowStockThreshold * 2) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery
        .of(context)
        .size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width >= 360 && size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFEAE0CF),
      appBar: AppBar(
        title: Text(
          'Manage Inventory',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        backgroundColor: const Color(0xFF213448),
        foregroundColor: const Color(0xFFEAE0CF),
        elevation: 0,
        actions: [
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

          // Product List
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
                        : 'No products available',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      color: const Color(0xFF547792).withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  ElevatedButton.icon(
                    onPressed: _showAddProductDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF213448),
                      foregroundColor: const Color(0xFFEAE0CF),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadProducts,
              color: const Color(0xFF213448),
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : (isMediumScreen ? 16 : 20),
                  isSmallScreen ? 12 : (isMediumScreen ? 16 : 20),
                  isSmallScreen ? 12 : (isMediumScreen ? 16 : 20),
                  isSmallScreen ? 80 : 90, // Extra bottom padding for FAB
                ),
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return _buildProductCard(
                      product, isSmallScreen, isMediumScreen);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: const Color(0xFF213448),
        foregroundColor: const Color(0xFFEAE0CF),
        icon: const Icon(Icons.add),
        label: Text(
          'Add Product',
          style: TextStyle(fontSize: isSmallScreen ? 13 : 15),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen,
      bool isMediumScreen) {
    final cardPadding = isSmallScreen ? 14.0 : (isMediumScreen ? 16.0 : 18.0);
    final nameFontSize = isSmallScreen ? 15.0 : (isMediumScreen ? 16.0 : 18.0);
    final categoryFontSize = isSmallScreen ? 11.0 : (isMediumScreen
        ? 12.0
        : 13.0);
    final detailFontSize = isSmallScreen ? 12.0 : (isMediumScreen
        ? 13.0
        : 14.0);
    final badgeFontSize = isSmallScreen ? 9.0 : (isMediumScreen ? 10.0 : 11.0);

    return Card(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: InkWell(
        onTap: () => _showEditProductDialog(product),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Stock Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                                fontSize: categoryFontSize,
                                color: const Color(0xFF547792),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 10,
                      vertical: isSmallScreen ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStockColor(product),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.quantity == 0
                              ? Icons.cancel
                              : product.quantity <= product.lowStockThreshold
                              ? Icons.warning
                              : Icons.check_circle,
                          color: Colors.white,
                          size: isSmallScreen ? 12 : 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.stockStatus,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: badgeFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 12 : 14),

              // Product Details Grid
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE0CF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.inventory_2,
                        label: 'Quantity',
                        value: '${product.quantity} ${product.unit}',
                        isSmallScreen: isSmallScreen,
                        detailFontSize: detailFontSize,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: isSmallScreen ? 35 : 40,
                      color: const Color(0xFF94B4C1).withOpacity(0.3),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.attach_money,
                        label: 'Price',
                        value: NumberFormat.currency(
                            symbol: '₱', decimalDigits: 2)
                            .format(product.price),
                        isSmallScreen: isSmallScreen,
                        detailFontSize: detailFontSize,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 10 : 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProductDialog(product),
                      icon: Icon(
                        Icons.edit,
                        size: isSmallScreen ? 16 : 18,
                      ),
                      label: Text(
                        'Edit',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF547792),
                        side: const BorderSide(color: Color(0xFF547792)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteConfirmation(product),
                      icon: Icon(
                        Icons.delete,
                        size: isSmallScreen ? 16 : 18,
                      ),
                      label: Text(
                        'Delete',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isSmallScreen,
    required double detailFontSize,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 20 : 24,
          color: const Color(0xFF547792),
        ),
        SizedBox(height: isSmallScreen ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 11,
            color: const Color(0xFF94B4C1),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: detailFontSize,
            color: const Color(0xFF213448),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}