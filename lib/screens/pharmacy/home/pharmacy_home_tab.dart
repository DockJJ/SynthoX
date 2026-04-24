import 'package:flutter/material.dart';

class PharmacyHomeTab extends StatelessWidget {
  final VoidCallback onSeeAllOrders;

  const PharmacyHomeTab({super.key, required this.onSeeAllOrders});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          SizedBox(height: 4),
                          Text(
                            'City Pharma 🏥',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B8D4).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00B8D4), width: 2),
                        ),
                        child: const Icon(Icons.local_pharmacy, color: Color(0xFF0D47A1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quick Stats
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Total Orders', '142', Icons.shopping_bag_outlined, Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildStatCard('Today Revenue', '\$1,240', Icons.payments_outlined, Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stock Alerts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '3 items are running low in stock!',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent Orders
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Orders',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                  ),
                  GestureDetector(
                    onTap: onSeeAllOrders,
                    child: const Text(
                      'See All',
                      style: TextStyle(fontSize: 14, color: Color(0xFF00B8D4), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 3,
              itemBuilder: (context, index) {
                final orders = [
                  {'id': '#OR-5521', 'name': 'Sarah Jenkins', 'status': 'Pending', 'items': 'Paracetamol, Amoxicillin'},
                  {'id': '#OR-5522', 'name': 'Michael Chen', 'status': 'Preparing', 'items': 'Vitamin C, Omega 3'},
                  {'id': '#OR-5523', 'name': 'Emily Davis', 'status': 'Ready', 'items': 'Insulin Syringe'},
                ];
                return _buildOrderCard(orders[index]);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade700),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color.shade900)),
          Text(title, style: TextStyle(fontSize: 12, color: color.shade700)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, String> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, spreadRadius: 1)],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long, color: Color(0xFF1976D2)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['id']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                Text(order['name']!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(order['items']!, style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(order['status']!).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order['status']!,
              style: TextStyle(color: _getStatusColor(order['status']!), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return Colors.orange;
      case 'Preparing': return Colors.blue;
      case 'Ready': return Colors.green;
      default: return Colors.grey;
    }
  }
}
