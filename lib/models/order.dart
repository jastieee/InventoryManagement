import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String unit;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.unit,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'unit': unit,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0) is int
          ? map['quantity']
          : (map['quantity'] as num).toInt(),
      price: (map['price'] ?? 0.0) is double
          ? map['price']
          : (map['price'] as num).toDouble(),
      unit: map['unit'] ?? 'pcs',
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime createdAt;
  final String status; // 'pending', 'completed', 'cancelled'
  final String? notes;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
    this.status = 'completed',
    this.notes,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    // Handle createdAt - can be Timestamp, String, or DateTime
    DateTime parsedCreatedAt;

    if (map['createdAt'] == null) {
      parsedCreatedAt = DateTime.now();
    } else if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt = DateTime.parse(map['createdAt']);
    } else if (map['createdAt'] is DateTime) {
      parsedCreatedAt = map['createdAt'];
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0.0) is double
          ? map['totalAmount']
          : (map['totalAmount'] as num).toDouble(),
      createdAt: parsedCreatedAt,
      status: map['status'] ?? 'completed',
      notes: map['notes'],
    );
  }

  Order copyWith({
    String? id,
    String? userId,
    String? userName,
    List<OrderItem>? items,
    double? totalAmount,
    DateTime? createdAt,
    String? status,
    String? notes,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}