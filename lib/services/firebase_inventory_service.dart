import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'products';

  // Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs
          .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  // Get products as stream (real-time updates)
  Stream<List<Product>> getProductsStream() {
    return _firestore.collection(_collection).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
          .toList(),
    );
  }

  // Get product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Product.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Add new product
  Future<Map<String, dynamic>> addProduct(Product product) async {
    try {
      // Generate custom ID if needed, or let Firestore auto-generate
      final docRef = product.id.isNotEmpty
          ? _firestore.collection(_collection).doc(product.id)
          : _firestore.collection(_collection).doc();

      await docRef.set(product.toMap());

      return {
        'success': true,
        'message': 'Product added successfully',
        'id': docRef.id,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error adding product: ${e.toString()}',
      };
    }
  }

  // Update existing product
  Future<Map<String, dynamic>> updateProduct(Product product) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(product.id)
          .update(product.toMap());

      return {
        'success': true,
        'message': 'Product updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating product: ${e.toString()}',
      };
    }
  }

  // Delete product
  Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();

      return {
        'success': true,
        'message': 'Product deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting product: ${e.toString()}',
      };
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return getAllProducts();

    try {
      final snapshot = await _firestore.collection(_collection).get();
      final lowerQuery = query.toLowerCase();

      return snapshot.docs
          .map((doc) => Product.fromMap({...doc.data(), 'id': doc.id}))
          .where((product) =>
      product.name.toLowerCase().contains(lowerQuery) ||
          product.description.toLowerCase().contains(lowerQuery) ||
          product.category.toLowerCase().contains(lowerQuery) ||
          product.id.toLowerCase().contains(lowerQuery) ||
          (product.barcode?.toLowerCase().contains(lowerQuery) ?? false))
          .toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Sort products
  List<Product> sortProducts(List<Product> products, String sortBy) {
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

  // Calculate total inventory value
  Future<double> getTotalInventoryValue() async {
    try {
      final products = await getAllProducts();
      return products.fold<double>(
        0.0,
            (sum, product) => sum + product.totalValue,
      );
    } catch (e) {
      return 0.0;
    }
  }


  // Get low stock products
  Future<List<Product>> getLowStockProducts() async {
    try {
      final products = await getAllProducts();
      return products
          .where((p) => p.quantity <= p.lowStockThreshold && p.quantity > 0)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get out of stock products
  Future<List<Product>> getOutOfStockProducts() async {
    try {
      final products = await getAllProducts();
      return products.where((p) => p.quantity == 0).toList();
    } catch (e) {
      return [];
    }
  }

  // Refresh inventory (for pull to refresh)
  Future<void> refreshInventory() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Just a delay, Firebase handles real-time sync
  }

  // Batch update quantities (useful for order processing)
  Future<Map<String, dynamic>> batchUpdateQuantities(
      Map<String, int> productQuantities) async {
    try {
      final batch = _firestore.batch();

      for (var entry in productQuantities.entries) {
        final docRef = _firestore.collection(_collection).doc(entry.key);
        batch.update(docRef, {
          'quantity': entry.value,
          'lastUpdated': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();

      return {
        'success': true,
        'message': 'Quantities updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating quantities: ${e.toString()}',
      };
    }
  }
}