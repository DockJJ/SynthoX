class MedicationReminderModel {
  final String id;
  final String drugName;
  final String dosage;
  final String timeSlot; // e.g. "08:00 AM"
  final String period; // Morning, Afternoon, Evening, Night
  final String frequency; // Once daily, Twice daily, Every 8 hrs
  final String instructions; // Before meal, After meal
  bool isTakenToday;

  MedicationReminderModel({
    required this.id,
    required this.drugName,
    required this.dosage,
    required this.timeSlot,
    required this.period,
    required this.frequency,
    required this.instructions,
    this.isTakenToday = false,
  });
}
