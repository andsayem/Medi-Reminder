import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../models/blood_pressure_model.dart';
import '../models/doctor_model.dart';
import '../models/medical_document_model.dart';
import '../models/medicine_model.dart';
import '../models/member_model.dart';
import '../models/blood_sugar_model.dart';
import '../services/next_dose_medicine.dart';
import '../services/notification_service.dart';

class MedicineProvider extends ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  final NotificationService _notificationService = NotificationService.instance;

  List<Medicine> _medicines = [];

  List<Medicine> _filteredMedicines = [];

  List<MedicalDocument> _prescriptions = [];

  List<MedicalDocument> _testReports = [];

  List<Doctor> _doctors = [];

  List<Member> _members = [];

  List<BloodPressure> _bloodPressures = [];

  List<BloodSugar> _bloodSugars = [];

  List<NextDoseMedicine> _nextMedicinesCache = [];

  bool _isLoading = false;

  bool _isDarkMode = false;

  bool _isGridView = false;

  String _activeProfile = 'Self';

  // =========================
  // GETTERS
  // =========================

  String get activeProfile => _activeProfile;

  bool get isLoading => _isLoading;

  bool get isDarkMode => _isDarkMode;

  bool get isGridView => _isGridView;

  List<Doctor> get doctors => _doctors;

  List<Member> get members => _members;

  List<NextDoseMedicine> get nextMedicines => _nextMedicinesCache;

  List<Medicine> get medicines =>
      _filteredMedicines.where((m) => m.patient == _activeProfile).toList();

  List<MedicalDocument> get prescriptions =>
      _prescriptions.where((d) => d.patient == _activeProfile).toList();

  List<MedicalDocument> get testReports =>
      _testReports.where((d) => d.patient == _activeProfile).toList();

  List<BloodPressure> get bloodPressures =>
      _bloodPressures.where((b) => b.patient == _activeProfile).toList();

  List<BloodSugar> get bloodSugars =>
      _bloodSugars.where((b) => b.patient == _activeProfile).toList();

  // =========================
  // PROFILE
  // =========================

  void setActiveProfile(String profile) {
    _activeProfile = profile;
    notifyListeners();
    refreshNextDoseMedicines();
  }

  // =========================
  // INIT
  // =========================

  Future<void> initialize() async {
    await fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;

    notifyListeners();

    try {
      _medicines = await _databaseHelper.getAllMedicines();

      _filteredMedicines = List<Medicine>.from(_medicines);

      _prescriptions = await _databaseHelper.getAllDocuments('prescriptions');

      _testReports = await _databaseHelper.getAllDocuments('test_reports');

      _doctors = await _databaseHelper.getAllDoctors();

      _members = await _databaseHelper.getAllMembers();

      _bloodPressures = await _databaseHelper.getAllBloodPressure();

      _bloodSugars = await _databaseHelper.getAllBloodSugar();

      await _notificationService.rescheduleMedicines(_medicines);

      await refreshNextDoseMedicines();
    } catch (e) {
      _medicines = [];

      _filteredMedicines = [];

      _prescriptions = [];

      _testReports = [];

      _doctors = [];

      _members = [];

      _bloodPressures = [];

      _nextMedicinesCache = [];
    }

    _isLoading = false;

    notifyListeners();
  }

  // =========================
  // NEXT DOSE
  // =========================

  Future<List<String>> _getSavedReminderTimes() async {
    final schedule = await NotificationService.instance.getReminderSchedule();

    schedule.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));

    return schedule.map((e) {
      final hour = (e['hour'] as int).toString().padLeft(2, '0');

      final minute = (e['minute'] as int).toString().padLeft(2, '0');

      return '$hour:$minute';
    }).toList();
  }

  List<String> _getDoseTimesSync(Medicine m, List<String> savedTimes) {
    final parts = m.dosage.split('+');

    final times = <String>[];

    /// Morning
    if (parts.length >= 1 && parts[0].trim() != '0') {
      if (savedTimes.isNotEmpty) {
        times.add(savedTimes[0]);
      }
    }

    /// Afternoon
    if (parts.length >= 2 && parts[1].trim() != '0') {
      if (savedTimes.length >= 2) {
        times.add(savedTimes[1]);
      }
    }

    /// Night
    if (parts.length >= 3 && parts[2].trim() != '0') {
      if (savedTimes.length >= 3) {
        times.add(savedTimes[2]);
      }
    }

    /// fallback custom reminder
    if (times.isEmpty && m.reminderTime.isNotEmpty) {
      times.add(m.reminderTime);
    }

    return times;
  }

  Future<void> refreshNextDoseMedicines() async {
    final now = DateTime.now();

    final savedTimes = await _getSavedReminderTimes();

    final upcoming = medicines.where((m) => m.dosage.isNotEmpty).expand((m) {
      final doseTimes = _getDoseTimesSync(m, savedTimes);

      return doseTimes.map((time) {
        final parts = time.split(':');

        if (parts.length < 2) return null;

        final hour = int.tryParse(parts[0]);

        final minute = int.tryParse(parts[1]);

        if (hour == null || minute == null) {
          return null;
        }

        var next = DateTime(now.year, now.month, now.day, hour, minute);

        if (next.isBefore(now)) {
          next = next.add(const Duration(days: 1));
        }

        return NextDoseMedicine(medicine: m, nextDoseTime: next);
      }).whereType<NextDoseMedicine>();
    }).toList();

    if (upcoming.isEmpty) {
      _nextMedicinesCache = [];

      notifyListeners();

      return;
    }

    upcoming.sort((a, b) => a.nextDoseTime.compareTo(b.nextDoseTime));

    final earliest = upcoming.first.nextDoseTime;

    _nextMedicinesCache = upcoming
        .where((e) => e.nextDoseTime == earliest)
        .toList();

    notifyListeners();
  }

  // =========================
  // MEDICINE
  // =========================

  Future<void> addMedicine(Medicine medicine) async {
    final createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final newMedicine = medicine.copyWith(createdAt: createdAt);

    final id = await _databaseHelper.insertMedicine(newMedicine);

    final inserted = newMedicine.copyWith(id: id);

    _medicines.insert(0, inserted);

    _filteredMedicines = List<Medicine>.from(_medicines);

    await _notificationService.scheduleMedicineReminder(inserted);

    await refreshNextDoseMedicines();

    notifyListeners();
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _databaseHelper.updateMedicine(medicine);

    final index = _medicines.indexWhere((item) => item.id == medicine.id);

    if (index >= 0) {
      _medicines[index] = medicine;

      _filteredMedicines = List<Medicine>.from(_medicines);
    }

    await _notificationService.cancelNotification(medicine.id!);

    await _notificationService.scheduleMedicineReminder(medicine);

    await refreshNextDoseMedicines();

    notifyListeners();
  }

  Future<void> deleteMedicine(int id) async {
    await _databaseHelper.deleteMedicine(id);

    _medicines.removeWhere((item) => item.id == id);

    _filteredMedicines = List<Medicine>.from(_medicines);

    await _notificationService.cancelNotification(id);

    await refreshNextDoseMedicines();

    notifyListeners();
  }

  Future<void> searchMedicines(String query) async {
    if (query.trim().isEmpty) {
      _filteredMedicines = List<Medicine>.from(_medicines);

      notifyListeners();

      return;
    }

    _filteredMedicines = await _databaseHelper.searchMedicines(query);

    notifyListeners();
  }

  // =========================
  // THEME
  // =========================

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;

    notifyListeners();
  }

  void toggleView() {
    _isGridView = !_isGridView;

    notifyListeners();
  }

  // =========================
  // PRESCRIPTIONS
  // =========================

  Future<void> addPrescription(MedicalDocument doc) async {
    await _databaseHelper.insertDocument('prescriptions', doc);

    _prescriptions = await _databaseHelper.getAllDocuments('prescriptions');

    notifyListeners();
  }

  Future<void> updatePrescription(MedicalDocument doc) async {
    await _databaseHelper.updateDocument('prescriptions', doc);

    _prescriptions = await _databaseHelper.getAllDocuments('prescriptions');

    notifyListeners();
  }

  Future<void> deletePrescription(int id) async {
    await _databaseHelper.deleteDocument('prescriptions', id);

    _prescriptions = await _databaseHelper.getAllDocuments('prescriptions');

    notifyListeners();
  }

  // =========================
  // TEST REPORTS
  // =========================

  Future<void> addTestReport(MedicalDocument doc) async {
    await _databaseHelper.insertDocument('test_reports', doc);

    _testReports = await _databaseHelper.getAllDocuments('test_reports');

    notifyListeners();
  }

  Future<void> updateTestReport(MedicalDocument doc) async {
    await _databaseHelper.updateDocument('test_reports', doc);

    _testReports = await _databaseHelper.getAllDocuments('test_reports');

    notifyListeners();
  }

  Future<void> deleteTestReport(int id) async {
    await _databaseHelper.deleteDocument('test_reports', id);

    _testReports = await _databaseHelper.getAllDocuments('test_reports');

    notifyListeners();
  }

  // =========================
  // DOCTORS
  // =========================

  Future<void> addDoctor(Doctor doctor) async {
    await _databaseHelper.insertDoctor(doctor);

    _doctors = await _databaseHelper.getAllDoctors();

    notifyListeners();
  }

  Future<void> deleteDoctor(int id) async {
    await _databaseHelper.deleteDoctor(id);

    _doctors = await _databaseHelper.getAllDoctors();

    notifyListeners();
  }

  // =========================
  // MEMBERS
  // =========================

  Future<void> addMember(Member member) async {
    await _databaseHelper.insertMember(member);

    _members = await _databaseHelper.getAllMembers();

    notifyListeners();
  }

  Future<void> deleteMember(int id) async {
    await _databaseHelper.deleteMember(id);

    _members = await _databaseHelper.getAllMembers();

    notifyListeners();
  }

  // =========================
  // BLOOD PRESSURE
  // =========================

  Future<void> addBloodPressure(BloodPressure bp) async {
    final createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final newBP = bp.copyWith(createdAt: createdAt);

    await _databaseHelper.insertBloodPressure(newBP);

    _bloodPressures = await _databaseHelper.getAllBloodPressure();

    notifyListeners();
  }

  Future<void> updateBloodPressure(BloodPressure bp) async {
    await _databaseHelper.updateBloodPressure(bp);

    _bloodPressures = await _databaseHelper.getAllBloodPressure();

    notifyListeners();
  }

  Future<void> deleteBloodPressure(int id) async {
    await _databaseHelper.deleteBloodPressure(id);

    _bloodPressures = await _databaseHelper.getAllBloodPressure();

    notifyListeners();
  }

  // =========================
  // BLOOD SUGAR
  // =========================

  Future<void> addBloodSugar(BloodSugar sugar) async {
    final createdAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final newSugar = sugar.copyWith(createdAt: createdAt);

    await _databaseHelper.insertBloodSugar(newSugar);

    _bloodSugars = await _databaseHelper.getAllBloodSugar();

    notifyListeners();
  }

  Future<void> updateBloodSugar(BloodSugar sugar) async {
    await _databaseHelper.updateBloodSugar(sugar);

    _bloodSugars = await _databaseHelper.getAllBloodSugar();

    notifyListeners();
  }

  Future<void> deleteBloodSugar(int id) async {
    await _databaseHelper.deleteBloodSugar(id);

    _bloodSugars = await _databaseHelper.getAllBloodSugar();

    notifyListeners();
  }
}
