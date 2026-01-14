// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
//
// /// ONE-TIME SETUP SCRIPT
// /// Run this ONCE to populate your Firebase with initial data
// /// After running once, you can delete this file or comment it out
//
// class FirebaseSeeder {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
//
//   /// Call this method once to seed all data
//   Future<void> seedAllData(BuildContext context) async {
//     try {
//       // Show loading dialog
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const Center(
//           child: Card(
//             child: Padding(
//               padding: EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text('Seeding database...'),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//
//       print('🌱 Starting database seeding...');
//
//       // 1. Create users
//       await _seedUsers();
//       print('✅ Users created');
//
//       // 2. Create products
//       await _seedProducts();
//       print('✅ Products created');
//
//       // 3. Create sample orders (optional)
//       await _seedOrders();
//       print('✅ Sample orders created');
//
//       Navigator.pop(context); // Close loading dialog
//
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('🎉 Database seeded successfully!'),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 3),
//         ),
//       );
//
//       print('🎉 Database seeding completed successfully!');
//     } catch (e) {
//       Navigator.pop(context); // Close loading dialog
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error seeding database: $e'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 5),
//         ),
//       );
//
//       print('❌ Error seeding database: $e');
//     }
//   }
//
//   /// Seed Users
//   Future<void> _seedUsers() async {
//     final users = [
//       {
//         'email': 'admin@inventory.com',
//         'password': 'admin123',
//         'name': 'Admin User',
//         'username': 'admin',
//         'role': 'admin',
//       },
//       {
//         'email': 'user@inventory.com',
//         'password': 'user123',
//         'name': 'Regular User',
//         'username': 'user',
//         'role': 'user',
//       },
//       {
//         'email': 'test@test.com',
//         'password': '123456',
//         'name': 'Test User',
//         'username': 'test',
//         'role': 'user',
//       },
//       {
//         'email': 'john@inventory.com',
//         'password': 'john123',
//         'name': 'John Doe',
//         'username': 'john',
//         'role': 'user',
//       },
//     ];
//
//     for (var userData in users) {
//       try {
//         // Create Firebase Auth user
//         final userCredential = await _auth.createUserWithEmailAndPassword(
//           email: userData['email']!,
//           password: userData['password']!,
//         );
//
//         final uid = userCredential.user!.uid;
//
//         // Create Firestore user document
//         await _firestore.collection('users').doc(uid).set({
//           'email': userData['email'],
//           'name': userData['name'],
//           'username': userData['username'],
//           'role': userData['role'],
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//
//         // Create username mapping
//         await _firestore.collection('usernames').doc(userData['username']!).set({
//           'uid': uid,
//         });
//
//         print('✓ Created user: ${userData['email']}');
//       } catch (e) {
//         if (e.toString().contains('email-already-in-use')) {
//           print('⚠ User ${userData['email']} already exists, skipping...');
//         } else {
//           print('✗ Error creating user ${userData['email']}: $e');
//         }
//       }
//     }
//   }
//
//   /// Seed Products
//   Future<void> _seedProducts() async {
//     final products = [
//       // Electronics
//       {
//         'id': 'P001',
//         'name': 'Dell Laptop',
//         'description': 'High-performance laptop for business use',
//         'category': 'Electronics',
//         'price': 45000.0,
//         'quantity': 5,
//         'lowStockThreshold': 10,
//         'barcode': '123456789001',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Dell Inc.',
//         'unit': 'pcs',
//       },
//       {
//         'id': 'P002',
//         'name': 'Wireless Mouse',
//         'description': 'Ergonomic wireless mouse',
//         'category': 'Electronics',
//         'price': 350.0,
//         'quantity': 50,
//         'lowStockThreshold': 20,
//         'barcode': '123456789002',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Logitech',
//         'unit': 'pcs',
//       },
//       {
//         'id': 'P003',
//         'name': 'Mechanical Keyboard',
//         'description': 'RGB mechanical gaming keyboard',
//         'category': 'Electronics',
//         'price': 2500.0,
//         'quantity': 15,
//         'lowStockThreshold': 10,
//         'barcode': '123456789003',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Razer',
//         'unit': 'pcs',
//       },
//       {
//         'id': 'P004',
//         'name': 'LED Monitor 24"',
//         'description': 'Full HD LED monitor',
//         'category': 'Electronics',
//         'price': 8500.0,
//         'quantity': 25,
//         'lowStockThreshold': 15,
//         'barcode': '123456789004',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Samsung',
//         'unit': 'pcs',
//       },
//       {
//         'id': 'P005',
//         'name': 'USB-C Cable',
//         'description': 'Fast charging USB-C cable',
//         'category': 'Electronics',
//         'price': 150.0,
//         'quantity': 0,
//         'lowStockThreshold': 30,
//         'barcode': '123456789005',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Anker',
//         'unit': 'pcs',
//       },
//
//       // Office Supplies
//       {
//         'id': 'P006',
//         'name': 'Printer Paper A4',
//         'description': 'Premium white printing paper',
//         'category': 'Office',
//         'price': 250.0,
//         'quantity': 100,
//         'lowStockThreshold': 50,
//         'barcode': '123456789006',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'PaperCo',
//         'unit': 'ream',
//       },
//       {
//         'id': 'P007',
//         'name': 'Ballpen Blue',
//         'description': 'Smooth writing ballpoint pen',
//         'category': 'Office',
//         'price': 10.0,
//         'quantity': 500,
//         'lowStockThreshold': 100,
//         'barcode': '123456789007',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Pilot',
//         'unit': 'pcs',
//       },
//       {
//         'id': 'P008',
//         'name': 'Stapler',
//         'description': 'Heavy-duty office stapler',
//         'category': 'Office',
//         'price': 120.0,
//         'quantity': 8,
//         'lowStockThreshold': 10,
//         'barcode': '123456789008',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Swingline',
//         'unit': 'pcs',
//       },
//
//       // Tools
//       {
//         'id': 'P009',
//         'name': 'Screwdriver Set',
//         'description': 'Professional screwdriver set with 10 pieces',
//         'category': 'Tools',
//         'price': 850.0,
//         'quantity': 20,
//         'lowStockThreshold': 15,
//         'barcode': '123456789009',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Stanley',
//         'unit': 'set',
//       },
//       {
//         'id': 'P010',
//         'name': 'Hammer',
//         'description': 'Steel claw hammer',
//         'category': 'Tools',
//         'price': 450.0,
//         'quantity': 12,
//         'lowStockThreshold': 10,
//         'barcode': '123456789010',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'DeWalt',
//         'unit': 'pcs',
//       },
//
//       // Furniture
//       {
//         'id': 'P011',
//         'name': 'Office Chair',
//         'description': 'Ergonomic office chair with lumbar support',
//         'category': 'Furniture',
//         'price': 3500.0,
//         'quantity': 30,
//         'lowStockThreshold': 20,
//         'barcode': '123456789011',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Herman Miller',
//         'unit': 'pcs',
//       },
//       {
//         'id': 'P012',
//         'name': 'Desk Lamp',
//         'description': 'LED desk lamp with adjustable brightness',
//         'category': 'Furniture',
//         'price': 650.0,
//         'quantity': 5,
//         'lowStockThreshold': 8,
//         'barcode': '123456789012',
//         'lastUpdated': DateTime.now().toIso8601String(),
//         'supplier': 'Philips',
//         'unit': 'pcs',
//       },
//     ];
//
//     for (var product in products) {
//       try {
//         await _firestore.collection('products').doc(product['id'] as String).set(product);
//         print('✓ Created product: ${product['name']}');
//       } catch (e) {
//         print('✗ Error creating product ${product['name']}: $e');
//       }
//     }
//   }
//
//   /// Seed Sample Orders (Optional)
//   Future<void> _seedOrders() async {
//     // Get admin user for orders
//     final usersSnapshot = await _firestore
//         .collection('users')
//         .where('role', isEqualTo: 'admin')
//         .limit(1)
//         .get();
//
//     if (usersSnapshot.docs.isEmpty) {
//       print('⚠ No admin user found, skipping order seeding');
//       return;
//     }
//
//     final adminDoc = usersSnapshot.docs.first;
//     final adminUid = adminDoc.id;
//     final adminName = adminDoc.data()['name'] as String;
//
//     final sampleOrders = [
//       {
//         'id': 'ORD${DateTime.now().millisecondsSinceEpoch - 86400000}', // Yesterday
//         'userId': adminUid,
//         'userName': adminName,
//         'items': [
//           {
//             'productId': 'P002',
//             'productName': 'Wireless Mouse',
//             'quantity': 5,
//             'price': 350.0,
//             'unit': 'pcs',
//           },
//           {
//             'productId': 'P007',
//             'productName': 'Ballpen Blue',
//             'quantity': 50,
//             'price': 10.0,
//             'unit': 'pcs',
//           },
//         ],
//         'totalAmount': 2250.0,
//         'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
//         'status': 'completed',
//         'notes': 'Sample order for office supplies',
//       },
//       {
//         'id': 'ORD${DateTime.now().millisecondsSinceEpoch}',
//         'userId': adminUid,
//         'userName': adminName,
//         'items': [
//           {
//             'productId': 'P003',
//             'productName': 'Mechanical Keyboard',
//             'quantity': 2,
//             'price': 2500.0,
//             'unit': 'pcs',
//           },
//         ],
//         'totalAmount': 5000.0,
//         'createdAt': FieldValue.serverTimestamp(),
//         'status': 'completed',
//         'notes': 'Sample keyboard order',
//       },
//     ];
//
//     for (var order in sampleOrders) {
//       try {
//         await _firestore.collection('orders').add(order);
//         print('✓ Created sample order: ${order['id']}');
//       } catch (e) {
//         print('✗ Error creating order ${order['id']}: $e');
//       }
//     }
//   }
//
//   /// Delete all seeded data (useful for testing)
//   Future<void> clearAllData() async {
//     print('🗑️ Clearing all data...');
//
//     // Delete products
//     final productsSnapshot = await _firestore.collection('products').get();
//     for (var doc in productsSnapshot.docs) {
//       await doc.reference.delete();
//     }
//
//     // Delete orders
//     final ordersSnapshot = await _firestore.collection('orders').get();
//     for (var doc in ordersSnapshot.docs) {
//       await doc.reference.delete();
//     }
//
//     // Delete users (Firestore only, not Auth)
//     final usersSnapshot = await _firestore.collection('users').get();
//     for (var doc in usersSnapshot.docs) {
//       await doc.reference.delete();
//     }
//
//     // Delete usernames
//     final usernamesSnapshot = await _firestore.collection('usernames').get();
//     for (var doc in usernamesSnapshot.docs) {
//       await doc.reference.delete();
//     }
//
//     print('✅ All data cleared');
//   }
// }
//
// /// Example usage in your app:
// /// Add a button in your admin screen or login screen to run this once
// ///
// /// Example:
// ///
// /// ElevatedButton(
// ///   onPressed: () async {
// ///     final seeder = FirebaseSeeder();
// ///     await seeder.seedAllData(context);
// ///   },
// ///   child: Text('Seed Database (Run Once)'),
// /// ),