import 'package:flutter/material.dart';

/// Common, ready-to-tap values so the user rarely needs to type.
class AppPresets {
  AppPresets._();

  static const List<({String label, IconData icon})> medicineTypes = [
    (label: 'Tablet', icon: Icons.medication_rounded),
    (label: 'Capsule', icon: Icons.medication_liquid_rounded),
    (label: 'Syrup', icon: Icons.local_drink_rounded),
    (label: 'Injection', icon: Icons.vaccines_rounded),
    (label: 'Drops', icon: Icons.water_drop_rounded),
    (label: 'Cream', icon: Icons.soap_rounded),
    (label: 'Inhaler', icon: Icons.air_rounded),
    (label: 'Powder', icon: Icons.grain_rounded),
  ];

  static IconData iconForType(String type) {
    for (final t in medicineTypes) {
      if (t.label == type) return t.icon;
    }
    return Icons.medication_rounded;
  }

  /// Commonly prescribed medicines in Bangladesh (brand + generic).
  static const List<String> commonMedicines = [
    'Napa',
    'Napa Extra',
    'Paracetamol',
    'Seclo',
    'Sergel',
    'Maxpro',
    'Fexo',
    'Alatrol',
    'Monas',
    'Ace',
    'Omeprazole',
    'Esomeprazole',
    'Metformin',
    'Amlodipine',
    'Losartan',
    'Atorvastatin',
    'Aspirin',
    'Calcium + D',
    'Vitamin D',
    'Zinc',
    'Azithromycin',
    'Amoxicillin',
    'Cetirizine',
    'Montelukast',
    'Domperidone',
    'Orsaline',
  ];

  static const List<String> dosagePatterns = [
    '1+0+1',
    '1+1+1',
    '1+0+0',
    '0+0+1',
    '0+1+0',
    '1+1+0',
  ];

  static const List<({String label, IconData icon})> mealTimings = [
    (label: 'After meal', icon: Icons.restaurant_rounded),
    (label: 'Before meal', icon: Icons.no_food_rounded),
    (label: 'With meal', icon: Icons.dinner_dining_rounded),
    (label: 'Empty stomach', icon: Icons.hourglass_empty_rounded),
  ];

  static const List<({String label, IconData icon})> repeats = [
    (label: 'Daily', icon: Icons.today_rounded),
    (label: 'Weekly', icon: Icons.date_range_rounded),
    (label: 'Monthly', icon: Icons.calendar_month_rounded),
  ];

  /// Course duration in days; 0 means continuous (no end date).
  static const List<({String label, int days})> durations = [
    (label: 'Continuous', days: 0),
    (label: '3 days', days: 3),
    (label: '5 days', days: 5),
    (label: '7 days', days: 7),
    (label: '14 days', days: 14),
    (label: '1 month', days: 30),
    (label: '3 months', days: 90),
  ];

  static const List<String> quantities = ['10', '14', '20', '30', '60', '100'];

  static const List<String> slotLabels = ['Morning', 'Noon', 'Night'];

  static const List<IconData> slotIcons = [
    Icons.wb_sunny_rounded,
    Icons.light_mode_rounded,
    Icons.nightlight_round,
  ];
}
