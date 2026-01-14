class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int quantity;
  final int lowStockThreshold;
  final String? barcode;
  final String? imageUrl;
  final DateTime lastUpdated;
  final String? supplier;
  final String? unit; // e.g., "pcs", "box", "kg"

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    this.lowStockThreshold = 10,
    this.barcode,
    this.imageUrl,
    required this.lastUpdated,
    this.supplier,
    this.unit = 'pcs',
  });

  // Calculate total value (price × quantity)
  double get totalValue => price * quantity;

  // Stock status
  String get stockStatus {
    if (quantity == 0) return 'Out of Stock';
    if (quantity <= lowStockThreshold) return 'Low Stock';
    if (quantity <= lowStockThreshold * 2) return 'Warning';
    return 'In Stock';
  }

  // Stock status color
  String get stockStatusColor {
    if (quantity == 0) return 'red';
    if (quantity <= lowStockThreshold) return 'red';
    if (quantity <= lowStockThreshold * 2) return 'orange';
    return 'green';
  }

  // Category icon
  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'electronics':
        return '💻';
      case 'food':
        return '🍔';
      case 'tools':
        return '🔧';
      case 'furniture':
        return '🪑';
      case 'clothing':
        return '👕';
      case 'office':
        return '📎';
      case 'medical':
        return '💊';
      case 'automotive':
        return '🚗';
      default:
        return '📦';
    }
  }

  // Convert Product to Map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'quantity': quantity,
      'lowStockThreshold': lowStockThreshold,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'lastUpdated': lastUpdated.toIso8601String(),
      'supplier': supplier,
      'unit': unit,
    };
  }

  // Create Product from Map (for database retrieval)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      lowStockThreshold: map['lowStockThreshold'] ?? 10,
      barcode: map['barcode'],
      imageUrl: map['imageUrl'],
      lastUpdated: DateTime.parse(map['lastUpdated']),
      supplier: map['supplier'],
      unit: map['unit'] ?? 'pcs',
    );
  }

  // Create a copy with some fields updated
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? quantity,
    int? lowStockThreshold,
    String? barcode,
    String? imageUrl,
    DateTime? lastUpdated,
    String? supplier,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      supplier: supplier ?? this.supplier,
      unit: unit ?? this.unit,
    );
  }

  // For CSV export
  String toCsvRow() {
    return '$id,$name,$category,$quantity,$price,${totalValue.toStringAsFixed(2)},$stockStatus';
  }

  // CSV Header
  static String csvHeader() {
    return 'ID,Name,Category,Quantity,Price,Total Value,Status';
  }
}