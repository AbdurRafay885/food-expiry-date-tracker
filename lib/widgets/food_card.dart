import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';

class FoodCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const FoodCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    
    DateTime now = DateTime.now();
    // Normalize both dates to exactly midnight to avoid time-of-day bugs
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);
    DateTime expiryMidnight = DateTime(item.expiryDate.year, item.expiryDate.month, item.expiryDate.day);

    String displayStatus = "Fresh";
    Color statusColor = Colors.green;

    if (expiryMidnight.isBefore(todayMidnight)) {
      displayStatus = "Expired";
      statusColor = Colors.red;
    } 
    else if (expiryMidnight.isAtSameMomentAs(todayMidnight)) {
      displayStatus = "Expiring Today";
      statusColor = Colors.blue; 
    } 
    else if (expiryMidnight.difference(todayMidnight).inDays <= 2) {
      displayStatus = "Expiring Soon";
      statusColor = Colors.orange;
    } 
    else {
      displayStatus = "Fresh";
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias, 
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.2),
                child: Icon(Icons.fastfood, color: statusColor),
              ),
              title: Text(
                item.name, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text("Quantity: ${item.quantity}"),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM dd').format(item.expiryDate),
                    style: TextStyle(
                      color: statusColor, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                    ),
                  ),
                  const SizedBox(height: 4), 
                  Text(
                    displayStatus,
                    style: TextStyle(
                      color: statusColor, 
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),
            // Delete Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    label: const Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}