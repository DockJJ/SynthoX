import 'package:flutter/material.dart';

class PharmacyOrdersScreen extends StatelessWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Orders Management',
            style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF0D47A1),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF0D47A1),
            tabs: [
              Tab(text: 'Incoming'),
              Tab(text: 'Active'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _IncomingOrdersTab(),
            _ActiveOrdersTab(),
          ],
        ),
      ),
    );
  }
}

class _IncomingOrdersTab extends StatelessWidget {
  const _IncomingOrdersTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) {
        final orders = [
          {'id': '#OR-9912', 'name': 'James Wilson', 'items': 'Metformin (500mg) x2', 'time': '5 mins ago'},
          {'id': '#OR-9913', 'name': 'Anna White', 'items': 'Lisinopril (10mg) x1', 'time': '12 mins ago'},
        ];
        return _buildIncomingCard(context, orders[index]);
      },
    );
  }

  Widget _buildIncomingCard(BuildContext context, Map<String, String> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order['id']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 18)),
              Text(order['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Patient: ${order['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Items: ${order['items']}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveOrdersTab extends StatelessWidget {
  const _ActiveOrdersTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) {
        final orders = [
          {'id': '#OR-5522', 'name': 'Michael Chen', 'status': 'Preparing'},
          {'id': '#OR-5523', 'name': 'Emily Davis', 'status': 'Ready for Pickup'},
        ];
        return _buildActiveCard(context, orders[index]);
      },
    );
  }

  Widget _buildActiveCard(BuildContext context, Map<String, String> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Color(0xFF1976D2)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    Text(order['id']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text(
                order['status']!,
                style: const TextStyle(color: Color(0xFF00B8D4), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Delivered!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mark as Delivered', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
