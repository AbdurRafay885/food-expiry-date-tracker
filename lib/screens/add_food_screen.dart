import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../services/firestore_services.dart';
import '../services/notification_services.dart';

class AddFoodScreen extends StatefulWidget {
  final FoodItem? existingItem; // Allows us to pass an item to edit

  const AddFoodScreen({super.key, this.existingItem});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Vegetables',
    'Dairy',
    'Meat',
    'Fruits',
    'Household',
    'Kitchen Item',
    'Other',
  ];
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // If we are editing, pre-fill the text fields and date
    if (widget.existingItem != null) {
      _nameController.text = widget.existingItem!.name;
      _qtyController.text = widget.existingItem!.quantity.toString();
      if (_categories.contains(widget.existingItem!.category)) {
        _selectedCategory = widget.existingItem!.category;
      } 
      else {
        _selectedCategory = 'Other'; // Safe fallback so it never crashes!
      }
      _selectedDate = widget.existingItem!.expiryDate;
    }
  }

  // Date Picker Logic
  Future<void> _presentDatePicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now, // Use existing date if editing
      firstDate: now,
      lastDate: DateTime(now.year + 5), // Can pick up to 5 years in the future
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  // Save Logic
  void _saveFoodItem() {
    // Basic Validation
    if (_nameController.text.trim().isEmpty ||
        _qtyController.text.trim().isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select a date."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create the FoodItem object
    final item = FoodItem(
      id: widget.existingItem?.id ?? '', // Use existing ID if editing
      userId: widget.existingItem?.userId ?? '',
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      quantity: int.tryParse(_qtyController.text.trim()) ?? 1,
      expiryDate: _selectedDate!,
      isConsumed: widget.existingItem?.isConsumed ?? false,
    );

    // Decide whether to Add or Update based on if we passed an existing item
    Future<void> saveTask = widget.existingItem == null
        ? _firestoreService.addFoodItem(item)
        : _firestoreService.updateFoodItem(item);

    saveTask
        .then((_) {
          if (mounted) {
            NotificationService.scheduleExpiryNotifications(item);
            Navigator.pop(context); // Close the screen immediately
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.existingItem == null
                      ? "Item added to fridge!"
                      : "Item updated!",
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to save item.")),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingItem != null; // Check if we are editing

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditing ? "Edit Item" : "Add New Item"), // Dynamic Title
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Name Input
            const Text(
              "Food Name",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "e.g., Milk, Apples, Chicken",
                prefixIcon: const Icon(Icons.fastfood_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            const Text(
              "Category",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              hint: const Text(
                'Select a Category',
              ), // Shows up before they pick anything
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),

            // Quantity Input
            const Text(
              "Quantity",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g., 2",
                prefixIcon: const Icon(Icons.numbers),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Expiry Date Picker
            const Text(
              "Expiry Date",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _presentDatePicker,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(15),
                  color: _selectedDate == null
                      ? Colors.transparent
                      : Colors.green.withValues(alpha: 0.1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _selectedDate == null ? Colors.grey : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? "Tap to select expiry date"
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null
                            ? Colors.grey.shade600
                            : Colors.green.shade800,
                        fontWeight: _selectedDate == null
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveFoodItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEditing
                            ? "Update Item"
                            : "Add to Fridge", // Dynamic Button Text
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }
}
