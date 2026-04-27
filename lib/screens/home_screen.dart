import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../models/food_item.dart';
import '../services/firestore_services.dart';
import 'add_food_screen.dart';
import '../widgets/food_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        centerTitle: false,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Icon(Icons.kitchen, color: Colors.green, size: 28),
        ),
        leadingWidth: 40,
        title: const Text(
          "ExpiryPulse",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          // Existing Auth StreamBuilder for the AppBar
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                User user = snapshot.data!;
                return Row(
                  children: [
                    Text(
                      "${user.displayName?.trim().split(' ').first ?? 'User'}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                    // --- NOTIFICATION BELL ---
                    StreamBuilder<List<FoodItem>>(
                      stream: FirestoreService().getFoodItems(),
                      builder: (context, foodSnapshot) {
                        if (!foodSnapshot.hasData)
                          return const SizedBox.shrink();

                        // Filter items that need alerts
                        final urgentItems = foodSnapshot.data!
                            .where(
                              (i) =>
                                  i.status == "Expired" ||
                                  i.status == "Expiring Soon",
                            )
                            .toList();

                        return IconButton(
                          icon: Badge(
                            isLabelVisible: urgentItems
                                .isNotEmpty, // Only show red dot if there are alerts
                            label: Text(urgentItems.length.toString()),
                            backgroundColor: Colors.red,
                            child: Icon(
                              urgentItems.isNotEmpty
                                  ? Icons.notifications_active
                                  : Icons.notifications_none,
                              color: urgentItems.isNotEmpty
                                  ? Colors.orange
                                  : Colors.green,
                              size: 28,
                            ),
                          ),
                          onPressed: () {
                            if (urgentItems.isNotEmpty) {
                              _showAlertsSheet(context, urgentItems);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "All good! No items are expiring soon.",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.account_circle,
                        color: Colors.green,
                        size: 30,
                      ),
                      onPressed: () {
                        //Show the Confirmation Dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              title: const Text(
                                "Sign Out",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                "Are you sure you want to sign out of your account?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Closes the dialog
                                  },
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(
                                      context,
                                    ); // Closes the dialog first
                                    await FirebaseAuth.instance
                                        .signOut(); // Then signs out
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    "Sign Out",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, left: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("Sign Up"),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),

      // Body - Switches between your Empty State and the Dashboard
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          // IF NOT LOGGED IN: Show your original empty state
          if (!authSnapshot.hasData) {
            return _buildEmptyState(context, false); // Passed context here
          }

          // IF LOGGED IN: Fetch Firestore Data
          final firestoreService = FirestoreService();
          return StreamBuilder<List<FoodItem>>(
            stream: firestoreService.getFoodItems(),
            builder: (context, foodSnapshot) {
              if (foodSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }

              // IF LOGGED IN BUT NO FOOD: Show empty state with button
              if (!foodSnapshot.hasData || foodSnapshot.data!.isEmpty) {
                return _buildEmptyState(context, true); // Passed context here
              }

              // IF LOGGED IN AND HAS FOOD: Show Dashboard & List
              final items = foodSnapshot.data!;
              int total = items.length;
              int expired = items.where((i) => i.status == "Expired").length;
              int expiringSoon = items
                  .where((i) => i.status == "Expiring Soon")
                  .length;

              return Column(
                children: [
                  // --- DASHBOARD ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard("Total", total.toString(), Colors.blue),
                        _buildStatCard(
                          "Soon",
                          expiringSoon.toString(),
                          Colors.orange,
                        ),
                        _buildStatCard(
                          "Expired",
                          expired.toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                  ),

                  // --- INVENTORY LIST ---
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        // FOOD CARD
                        final item = items[index];

                        return FoodCard(
                          item: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddFoodScreen(existingItem: item),
                            ),
                          ),
                          onDelete: () async {
                            await firestoreService.deleteItem(item.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Item Deleted")),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              // --- MANUAL ADD BUTTON ---
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddFoodScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 24),
                  label: const Text(
                    "Add Items To Fridge",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Method: Empty state UI 
  Widget _buildEmptyState(BuildContext context, bool isLoggedIn) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: Colors.green.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          const Text(
            "Your Fridge is Empty",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLoggedIn
                ? "Start adding items to track freshness!"
                : "Login or Signup to Get Started",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
            const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Helper Method: Dashboard Stat Card
  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Method: Alerts Bottom Sheet
void _showAlertsSheet(BuildContext context, List<FoodItem> urgentItems) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  "Urgent Alerts",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),
            // List of expiring/expired items
            Expanded(
              child: ListView.builder(
                itemCount: urgentItems.length,
                itemBuilder: (context, index) {
                  final item = urgentItems[index];
                  bool isExpired = item.status == "Expired";

                  return ListTile(
                    leading: Icon(
                      isExpired ? Icons.error_outline : Icons.schedule,
                      color: isExpired ? Colors.red : Colors.orange,
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isExpired
                          ? "Expired on ${DateFormat('MMM dd').format(item.expiryDate)}"
                          : "Expiring in ${item.daysRemaining} days!",
                      style: TextStyle(
                        color: isExpired ? Colors.red : Colors.orange,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      );
    },
  );
}
