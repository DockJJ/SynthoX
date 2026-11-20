class VitalsService {
  Future<Map<String, dynamic>> fetchVitals() async {
    // Simulate sensor or Apple HealthKit / Google Fit API sync
    await Future.delayed(const Duration(milliseconds: 600));

    return {
      'heartRate': {
        'value': '72',
        'unit': 'bpm',
        'status': 'Normal',
        'lastUpdated': 'Just now',
        'history': [70, 72, 75, 71, 73, 72],
      },
      'bloodPressure': {
        'value': '120/80',
        'unit': 'mmHg',
        'status': 'Optimal',
        'lastUpdated': 'Today 08:30 AM',
      },
      'spO2': {
        'value': '98',
        'unit': '%',
        'status': 'Healthy',
        'lastUpdated': 'Just now',
      },
      'steps': {
        'current': 7420,
        'goal': 10000,
        'calories': '340 kcal',
        'distance': '5.2 km',
      },
      'sleep': {
        'duration': '7h 45m',
        'quality': 'Deep & Restful',
        'score': '88/100',
      },
    };
  }
}
