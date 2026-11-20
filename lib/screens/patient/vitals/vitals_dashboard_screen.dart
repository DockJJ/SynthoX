import 'package:flutter/material.dart';
import '../../../services/vitals_service.dart';

class VitalsDashboardScreen extends StatefulWidget {
  const VitalsDashboardScreen({super.key});

  @override
  State<VitalsDashboardScreen> createState() => _VitalsDashboardScreenState();
}

class _VitalsDashboardScreenState extends State<VitalsDashboardScreen> {
  final VitalsService _vitalsService = VitalsService();
  bool _isSyncing = false;
  Map<String, dynamic>? _vitalsData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isSyncing = true);
    final data = await _vitalsService.fetchVitals();
    if (mounted) {
      setState(() {
        _vitalsData = data;
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
        title: const Text(
          'Vitals & Wearables',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D47A1)),
                  )
                : const Icon(Icons.sync, color: Color(0xFF0D47A1)),
            onPressed: _isSyncing ? null : _loadData,
          ),
        ],
      ),
      body: _vitalsData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Health Score Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D47A1), Color(0xFF00B8D4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 36),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overall Health Index',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '92% Excellent',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Synced with Apple Health & Smart Watch',
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Live Vital Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                  ),
                  const SizedBox(height: 16),

                  // 2x2 Grid of Vital Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Heart Rate',
                          value: _vitalsData!['heartRate']['value'],
                          unit: _vitalsData!['heartRate']['unit'],
                          status: _vitalsData!['heartRate']['status'],
                          icon: Icons.favorite_border,
                          iconColor: Colors.redAccent,
                          bgColor: const Color(0xFFFFEBEE),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Blood Pressure',
                          value: _vitalsData!['bloodPressure']['value'],
                          unit: _vitalsData!['bloodPressure']['unit'],
                          status: _vitalsData!['bloodPressure']['status'],
                          icon: Icons.speed,
                          iconColor: const Color(0xFF1976D2),
                          bgColor: const Color(0xFFE3F2FD),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Blood Oxygen (SpO2)',
                          value: _vitalsData!['spO2']['value'],
                          unit: _vitalsData!['spO2']['unit'],
                          status: _vitalsData!['spO2']['status'],
                          icon: Icons.water_drop_outlined,
                          iconColor: const Color(0xFF0097A7),
                          bgColor: const Color(0xFFE0F7FA),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Sleep Duration',
                          value: _vitalsData!['sleep']['duration'],
                          unit: _vitalsData!['sleep']['quality'],
                          status: 'Score: ${_vitalsData!['sleep']['score']}',
                          icon: Icons.nightlight_round,
                          iconColor: Colors.purple,
                          bgColor: const Color(0xFFF3E5F5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Daily Step Goal Progress Bar Card
                  const Text(
                    'Activity & Steps',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.directions_walk, color: Color(0xFF00B8D4)),
                                SizedBox(width: 8),
                                Text(
                                  'Daily Step Tracker',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D47A1)),
                                ),
                              ],
                            ),
                            Text(
                              '${_vitalsData!['steps']['current']} / ${_vitalsData!['steps']['goal']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B8D4)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _vitalsData!['steps']['current'] / _vitalsData!['steps']['goal'],
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xFF00B8D4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Calories: ${_vitalsData!['steps']['calories']}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            Text(
                              'Distance: ${_vitalsData!['steps']['distance']}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required String status,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
