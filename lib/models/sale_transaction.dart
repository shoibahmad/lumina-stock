import 'package:cloud_firestore/cloud_firestore.dart';

class SaleTransaction {
  final String id;
  final String productId;
  final String productName;
  final String category;
  final int quantity;
  final double totalPrice;
  final double totalProfit;
  final DateTime date;

  SaleTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.totalPrice,
    required this.totalProfit,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'category': category,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'totalProfit': totalProfit,
      'date': Timestamp.fromDate(date),
    };
  }

  factory SaleTransaction.fromMap(Map<String, dynamic> map, String id) {
    return SaleTransaction(
      id: id,
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      category: map['category'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (map['totalProfit'] as num?)?.toDouble() ?? 0.0,
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}
