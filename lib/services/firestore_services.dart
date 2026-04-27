import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/food_item.dart';

class FirestoreService {
  final CollectionReference _foodCollection = FirebaseFirestore.instance.collection('food_items');
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Add Food Item
  Future<void> addFoodItem(FoodItem item) async {
    item.userId = userId; // Ensure it's tied to the logged-in user
    await _foodCollection.add(item.toMap());
  }

// Update Item
  Future<void> updateFoodItem(FoodItem item) async {
    await _foodCollection.doc(item.id).update(item.toMap());
  }

  // Delete Item
  Future<void> deleteItem(String id) async {
    await _foodCollection.doc(id).delete();
  }

  // View Inventory (Sorted by nearest expiry)
  Stream<List<FoodItem>> getFoodItems() {
    return _foodCollection
        .where('userId', isEqualTo: userId) // Assumes you have a userId variable available
        .snapshots()
        .map((snapshot) {
          
      List<FoodItem> validItems = [];

      for (var doc in snapshot.docs) {
        FoodItem item = FoodItem.fromFirestore(doc);
        
        // Keep everything in the list as long as it hasn't been consumed
        if (item.isConsumed == false) {
          validItems.add(item);
        }
      }
      
      // Sort nearest expiry to the top
      validItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      
      return validItems;
    });
  }
}