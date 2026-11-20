import '../models/medication_reminder_model.dart';

class MedicationReminderService {
  static final MedicationReminderService _instance = MedicationReminderService._internal();
  factory MedicationReminderService() => _instance;
  MedicationReminderService._internal();

  final List<MedicationReminderModel> _reminders = [
    MedicationReminderModel(
      id: 'm1',
      drugName: 'Amoxicillin 500mg',
      dosage: '1 Capsule',
      timeSlot: '08:00 AM',
      period: 'Morning',
      frequency: 'Twice daily',
      instructions: 'Take after breakfast',
      isTakenToday: true,
    ),
    MedicationReminderModel(
      id: 'm2',
      drugName: 'Atorvastatin 20mg',
      dosage: '1 Tablet',
      timeSlot: '01:30 PM',
      period: 'Afternoon',
      frequency: 'Once daily',
      instructions: 'Take after lunch',
      isTakenToday: false,
    ),
    MedicationReminderModel(
      id: 'm3',
      drugName: 'Paracetamol 500mg',
      dosage: '2 Tablets',
      timeSlot: '08:00 PM',
      period: 'Night',
      frequency: 'As needed',
      instructions: 'Take with full glass of water',
      isTakenToday: false,
    ),
  ];

  List<MedicationReminderModel> get reminders => _reminders;

  void toggleTaken(String id) {
    final index = _reminders.indexWhere((m) => m.id == id);
    if (index != -1) {
      _reminders[index].isTakenToday = !_reminders[index].isTakenToday;
    }
  }

  void addReminder(MedicationReminderModel reminder) {
    _reminders.add(reminder);
  }
}
