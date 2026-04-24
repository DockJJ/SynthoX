import 'package:flutter/material.dart';

class PharmacyInventoryScreen extends StatelessWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Inventory',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF00B8D4), size: 30),
            onPressed: () {
              _showAddDrugDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00B8D4)),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 5,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final drugs = [
                  {'name': 'Paracetamol', 'stock': '120 units', 'price': '\$5.50', 'low': false},
                  {'name': 'Amoxicillin', 'stock': '8 units', 'price': '\$12.00', 'low': true},
                  {'name': 'Vitamin C', 'stock': '45 units', 'price': '\$8.20', 'low': false},
                  {'name': 'Lisinopril', 'stock': '3 units', 'price': '\$15.00', 'low': true},
                  {'name': 'Metformin', 'stock': '60 units', 'price': '\$10.50', 'low': false},
                ];
                return _buildDrugItem(context, drugs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrugItem(BuildContext context, Map<String, dynamic> drug) {
    final isLow = drug['low'] as bool;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(drug['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
      subtitle: Row(
        children: [
          Text('Stock: ${drug['stock']}', style: TextStyle(color: isLow ? Colors.red : Colors.grey, fontWeight: isLow ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(width: 12),
          Text('Price: ${drug['price']}', style: const TextStyle(color: Color(0xFF00B8D4))),
        ],
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
        onSelected: (val) {
          if (val == 'delete') {
            _showDeleteConfirmation(context, drug['name']);
          }
        },
      ),
    );
  }

  void _showAddDrugDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add New Drug', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
            const SizedBox(height: 24),
            _buildDialogField('Drug Name'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDialogField('Price (\$)')),
                const SizedBox(width: 16),
                Expanded(child: _buildDialogField('Stock Quantity')),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Save Drug', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete $name from inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
