import 'package:flutter/material.dart';
import '../../../models/medication_reminder_model.dart';
import '../../../services/medication_reminder_service.dart';

class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key});

  @override
  State<MedicationRemindersScreen> createState() => _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState extends State<MedicationRemindersScreen> {
  final MedicationReminderService _reminderService = MedicationReminderService();

  final _drugNameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _selectedFrequency = 'Once daily';
  String _selectedInstruction = 'After meal';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void dispose() {
    _drugNameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _showAddReminderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Set Medication Reminder',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(height: 20),

                // Drug Name
                TextField(
                  controller: _drugNameController,
                  decoration: InputDecoration(
                    labelText: 'Medication Name',
                    hintText: 'e.g. Amoxicillin 500mg',
                    prefixIcon: const Icon(Icons.medication_outlined, color: Color(0xFF00B8D4)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Dosage
                TextField(
                  controller: _dosageController,
                  decoration: InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g. 1 Tablet / 5ml',
                    prefixIcon: const Icon(Icons.vaccines_outlined, color: Color(0xFF00B8D4)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Slot Selector
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: Color(0xFF0D47A1)),
                  title: const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    _selectedTime.format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B8D4), fontSize: 16),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                    if (picked != null) {
                      setSheetState(() => _selectedTime = picked);
                    }
                  },
                ),
                const Divider(),

                // Frequency Choice
                const Text('Frequency', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Once daily', 'Twice daily', 'Every 8 hrs', 'As needed'].map((freq) {
                    final isSelected = _selectedFrequency == freq;
                    return ChoiceChip(
                      label: Text(freq),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00B8D4),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      onSelected: (val) {
                        if (val) setSheetState(() => _selectedFrequency = freq);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Instructions Choice
                const Text('Meal Instructions', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D47A1))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['After meal', 'Before meal', 'With food'].map((inst) {
                    final isSelected = _selectedInstruction == inst;
                    return ChoiceChip(
                      label: Text(inst),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0D47A1),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      onSelected: (val) {
                        if (val) setSheetState(() => _selectedInstruction = inst);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: () {
                    if (_drugNameController.text.trim().isEmpty) return;

                    final newReminder = MedicationReminderModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      drugName: _drugNameController.text.trim(),
                      dosage: _dosageController.text.trim().isEmpty ? '1 Tablet' : _dosageController.text.trim(),
                      timeSlot: _selectedTime.format(context),
                      period: _selectedTime.hour < 12 ? 'Morning' : (_selectedTime.hour < 17 ? 'Afternoon' : 'Night'),
                      frequency: _selectedFrequency,
                      instructions: _selectedInstruction,
                    );

                    _reminderService.addReminder(newReminder);
                    _drugNameController.clear();
                    _dosageController.clear();

                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Medication Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = _reminderService.reminders;
    final takenCount = reminders.where((r) => r.isTakenToday).length;
    final double progress = reminders.isEmpty ? 0 : takenCount / reminders.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D47A1)),
        title: const Text(
          'Medication Reminders',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Header Progress Card
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.white24,
                          color: const Color(0xFF00B8D4),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Dose Progress",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$takenCount of ${reminders.length} Doses Taken',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Keep up your active care schedule!',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Daily Timeline Header
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Dose Timeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                ),
                Text(
                  'Today',
                  style: TextStyle(color: Color(0xFF00B8D4), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Dose Timeline List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final item = reminders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: item.isTakenToday ? Colors.green.shade200 : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Checkbox
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _reminderService.toggleTaken(item.id);
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: item.isTakenToday ? Colors.green : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.isTakenToday ? Colors.green : Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: item.isTakenToday ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.drugName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: item.isTakenToday ? Colors.grey : const Color(0xFF0D47A1),
                                decoration: item.isTakenToday ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.dosage} • ${item.instructions}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      // Time Slot Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Color(0xFF0D47A1)),
                            const SizedBox(width: 4),
                            Text(
                              item.timeSlot,
                              style: const TextStyle(color: Color(0xFF0D47A1), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderSheet,
        backgroundColor: const Color(0xFF0D47A1),
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: const Text('Add Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
