class Product {
  final String id;
  final String name;
  final String category;
  final double buyingPrice;
  final double sellingPrice;
  final String imageUrl;
  final int quantity;
  final String? barcode;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.imageUrl,
    this.quantity = 0,
    this.barcode,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'buyingPrice': buyingPrice,
      'sellingPrice': sellingPrice,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'barcode': barcode,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      buyingPrice: (map['buyingPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      barcode: map['barcode'],
    );
  }

  double get profit => sellingPrice - buyingPrice;
}
