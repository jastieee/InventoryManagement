import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as models;
import 'firebase_inventory_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _inventoryService = InventoryService();
  final String _collection = 'orders';

  // Create new order with enhanced debugging
  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String userName,
    required List<models.OrderItem> items,
    String? notes,
  }) async {
    try {
      print('=== ORDER CREATION STARTED ===');
      print('User ID: $userId');
      print('User Name: $userName');
      print('Items count: ${items.length}');
      print('Notes: $notes');

      // Validate inputs
      if (userId.isEmpty) {
        print('ERROR: User ID is empty');
        return {
          'success': false,
          'message': 'User ID is required',
        };
      }

      if (items.isEmpty) {
        print('ERROR: No items in order');
        return {
          'success': false,
          'message': 'Order must contain at least one item',
        };
      }

      // Validate stock availability for all items
      print('Validating stock...');
      for (var item in items) {
        print('Checking product: ${item.productId} - ${item.productName}');

        final product = await _inventoryService.getProductById(item.productId);

        if (product == null) {
          print('ERROR: Product not found: ${item.productId}');
          return {
            'success': false,
            'message': 'Product ${item.productName} not found',
          };
        }

        print('Product found: ${product.name}, Stock: ${product.quantity}, Needed: ${item.quantity}');

        if (product.quantity < item.quantity) {
          print('ERROR: Insufficient stock');
          return {
            'success': false,
            'message': 'Insufficient stock for ${item.productName}. Available: ${product.quantity} ${product.unit}',
          };
        }
      }

      print('Stock validation passed!');

      // Calculate total amount
      final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      print('Total amount: ₱$totalAmount');

      // Create order document reference
      final orderRef = _firestore.collection(_collection).doc();
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      print('Generated Order ID: $orderId');

      final orderData = {
        'id': orderId,
        'userId': userId,
        'userName': userName,
        'items': items.map((item) => item.toMap()).toList(),
        'totalAmount': totalAmount,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
        'notes': notes,
      };

      print('Order data prepared, starting transaction...');

      // Use transaction to ensure atomicity
      // CRITICAL: In Firestore transactions, ALL READS must happen BEFORE ALL WRITES
      await _firestore.runTransaction((transaction) async {
        print('Transaction started');

        // STEP 1: DO ALL READS FIRST
        print('Reading all product documents...');
        final Map<String, DocumentSnapshot> productDocs = {};

        for (var item in items) {
          final productRef = _firestore.collection('products').doc(item.productId);
          final productDoc = await transaction.get(productRef);

          if (!productDoc.exists) {
            print('ERROR: Product document not found in transaction');
            throw Exception('Product ${item.productName} not found');
          }

          productDocs[item.productId] = productDoc;
          print('Read product: ${item.productName}');
        }

        print('All reads completed. Starting writes...');

        // STEP 2: NOW DO ALL WRITES

        // Add order
        transaction.set(orderRef, orderData);
        print('Order document set in transaction');

        // Update product quantities
        for (var item in items) {
          print('Updating stock for: ${item.productId}');

          final productRef = _firestore.collection('products').doc(item.productId);
          final productDoc = productDocs[item.productId]!;

          // Cast data() to Map<String, dynamic>
          final productData = productDoc.data() as Map<String, dynamic>;
          final currentQty = productData['quantity'] as int;
          final newQty = currentQty - item.quantity;

          print('Current qty: $currentQty, Ordering: ${item.quantity}, New qty: $newQty');

          transaction.update(productRef, {
            'quantity': newQty,
            'lastUpdated': DateTime.now().toIso8601String(),
          });

          print('Stock updated for ${item.productName}');
        }

        print('Transaction updates completed');
      });

      print('Transaction committed successfully!');
      print('=== ORDER CREATION SUCCESSFUL ===');

      return {
        'success': true,
        'message': 'Order placed successfully!',
        'orderId': orderId,
      };

    } on FirebaseException catch (e) {
      print('=== FIREBASE ERROR ===');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Details: ${e.toString()}');

      return {
        'success': false,
        'message': 'Firebase error: ${e.message ?? e.code}',
      };

    } catch (e, stackTrace) {
      print('=== GENERAL ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      return {
        'success': false,
        'message': 'Error creating order: ${e.toString()}',
      };
    }
  }

  // Get all orders
  Future<List<models.Order>> getAllOrders() async {
    try {
      print('Fetching all orders...');
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${snapshot.docs.length} orders');

      final orders = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          print('Order doc ID: ${doc.id}');
          print('Order data: $data');
          return models.Order.fromMap({...data, 'id': doc.id});
        } catch (e) {
          print('Error parsing order ${doc.id}: $e');
          rethrow;
        }
      }).toList();

      print('Successfully parsed ${orders.length} orders');
      return orders;
    } catch (e) {
      print('Error getting orders: $e');
      return [];
    }
  }

  // Get orders as stream
  Stream<List<models.Order>> getOrdersStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return models.Order.fromMap({...data, 'id': doc.id});
    }).toList());
  }

  // Get orders by user ID
  Future<List<models.Order>> getOrdersByUserId(String userId) async {
    try {
      print('Fetching orders for user: $userId');
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${snapshot.docs.length} orders for user');

      final orders = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return models.Order.fromMap({...data, 'id': doc.id});
        } catch (e) {
          print('Error parsing order ${doc.id}: $e');
          rethrow;
        }
      }).toList();

      return orders;
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  // Get order by ID
  Future<models.Order?> getOrderById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        return models.Order.fromMap({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Cancel order and restore inventory
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) {
        return {
          'success': false,
          'message': 'Order not found',
        };
      }

      if (order.status == 'cancelled') {
        return {
          'success': false,
          'message': 'Order is already cancelled',
        };
      }

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // Update order status
        final orderRef = _firestore.collection(_collection).doc(orderId);
        transaction.update(orderRef, {'status': 'cancelled'});

        // Restore product quantities
        for (var item in order.items) {
          final productRef = _firestore.collection('products').doc(item.productId);
          final productDoc = await transaction.get(productRef);

          if (productDoc.exists) {
            final currentQty = productDoc.data()!['quantity'] as int;
            transaction.update(productRef, {
              'quantity': currentQty + item.quantity,
              'lastUpdated': DateTime.now().toIso8601String(),
            });
          }
        }
      });

      return {
        'success': true,
        'message': 'Order cancelled and stock restored',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error cancelling order: ${e.toString()}',
      };
    }
  }

  // Get total sales
  Future<double> getTotalSales() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'completed')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final amount = doc.data()['totalAmount'];
        if (amount != null) {
          total += (amount as num).toDouble();
        }
      }
      return total;
    } catch (e) {
      print('Error getting total sales: $e');
      return 0.0;
    }
  }

  // Get orders count
  Future<int> getTotalOrdersCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Get recent orders
  Future<List<models.Order>> getRecentOrders({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return models.Order.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting recent orders: $e');
      return [];
    }
  }

  // Delete order
  Future<Map<String, dynamic>> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(_collection).doc(orderId).delete();
      return {
        'success': true,
        'message': 'Order deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting order: ${e.toString()}',
      };
    }
  }

  // Get orders by date range
  Future<List<models.Order>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return models.Order.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting orders by date range: $e');
      return [];
    }
  }

  // Get orders by status
  Future<List<models.Order>> getOrdersByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return models.Order.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Error getting orders by status: $e');
      return [];
    }
  }
}