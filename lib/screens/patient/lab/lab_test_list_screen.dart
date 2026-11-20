import 'package:flutter/material.dart';
import 'lab_test_detail_screen.dart';

class LabTestListScreen extends StatefulWidget {
  const LabTestListScreen({super.key});

  @override
  State<LabTestListScreen> createState() => _LabTestListScreenState();
}

class _LabTestListScreenState extends State<LabTestListScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _labTests = [
    {
      'title': 'Full Blood Count (FBC)',
      'category': 'Blood Tests',
      'parameters': '22 Parameters Included',
      'preparation': 'No Fasting Required',
      'turnaround': 'Results in 12 Hours',
      'price': '\$35.00',
      'description': 'Measures red blood cells, white blood cells, platelets, hemoglobin, and hematocrit to evaluate overall health and detect disorders.',
    },
    {
      'title': 'Lipid Panel & Cardiac Risk',
      'category': 'Cardiac',
      'parameters': '8 Parameters Included',
      'preparation': 'Fasting Required (10-12 hrs)',
      'turnaround': 'Results in 24 Hours',
      'price': '\$45.00',
      'description': 'Assesses Total Cholesterol, HDL, LDL, Triglycerides, and Cardiac Risk Ratio to check cardiovascular wellness.',
    },
    {
      'title': 'Comprehensive Diabetes Profile',
      'category': 'Diabetes',
      'parameters': '12 Parameters Included',
      'preparation': 'Fasting Required (8 hrs)',
      'turnaround': 'Results in 24 Hours',
      'price': '\$50.00',
      'description': 'Includes HbA1c, Fasting Blood Sugar, Postprandial Glucose, and Urine Microalbumin for complete glycemic management.',
    },
    {
      'title': 'Thyroid Profile (T3, T4, TSH)',
      'category': 'Blood Tests',
      'parameters': '5 Parameters Included',
      'preparation': 'No Fasting Required',
      'turnaround': 'Results in 24 Hours',
      'price': '\$40.00',
      'description': 'Evaluates thyroid gland performance and metabolic hormone balance.',
    },
    {
      'title': 'Executive Health Checkup Package',
      'category': 'Full Checkup',
      'parameters': '54 Parameters Included',
      'preparation': 'Fasting Required (12 hrs)',
      'turnaround': 'Results in 36 Hours',
      'price': '\$120.00',
      'description': 'Complete body assessment covering Liver, Kidney, Lipid, Blood, Thyroid, and Essential Vitamin levels.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTests = _labTests.where((test) {
      final matchesCategory = _selectedCategory == 'All' || test['category'] == _selectedCategory;
      final matchesQuery = test['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
        title: const Text(
          'Lab Diagnostics',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Header Search Box
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search lab tests, panels, packages...',
                  hintStyle: TextStyle(color: Colors.grey),
                  icon: Icon(Icons.search, color: Color(0xFF00B8D4)),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Category Chips Row
          Container(
            height: 50,
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: ['All', 'Blood Tests', 'Cardiac', 'Diabetes', 'Full Checkup'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Test Cards List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredTests.length,
              itemBuilder: (context, index) {
                final test = filteredTests[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LabTestDetailScreen(testData: test),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B8D4).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                test['category'],
                                style: const TextStyle(
                                  color: Color(0xFF00B8D4),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              test['price'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          test['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          test['parameters'],
                          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              test['turnaround'],
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.restaurant_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              test['preparation'],
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
