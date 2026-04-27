import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  String id;
  String userId;
  String name;
  String category;
  int quantity;
  DateTime expiryDate;
  bool isConsumed;

  FoodItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.quantity,
    required this.expiryDate,
    this.isConsumed = false,
  });

  // Calculate remaining days
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  // Determine Status
  String get status {
    if (daysRemaining < 0) return "Expired";
    if (daysRemaining <= 2) return "Expiring Soon";
    return "Fresh";
  }

  // Convert Firebase Document to Object
  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? 1,
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      isConsumed: data['isConsumed'] ?? false,
    );
  }

  // Convert Object to Firebase Data
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'expiryDate': expiryDate,
      'isConsumed': isConsumed,
    };
  }
}