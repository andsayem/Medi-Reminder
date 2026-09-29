import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor_model.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/empty_widget.dart';
import '../widgets/custom_textfield.dart';

class DoctorsPage extends StatelessWidget {
  const DoctorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();
    final doctors = provider.doctors;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Doctors'), centerTitle: true),
      body: doctors.isEmpty
          ? const EmptyWidget(
              title: 'No Doctors Found',
              subtitle: 'Add doctors to keep track of your medical contacts.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: doctors.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return Container(
                  decoration: _premiumCardDecoration(),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        doctor.name.isNotEmpty
                            ? doctor.name[0].toUpperCase()
                            : 'D',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      doctor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      doctor.specialty.isNotEmpty
                          ? doctor.specialty
                          : 'Consulting Doctor',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (doctor.phone.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.call_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            onPressed: () {
                              // Future: launch dialer
                            },
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => provider.deleteDoctor(doctor.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDoctorSheet(context, provider),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Doctor'),
      ),
    );
  }

  void _showAddDoctorSheet(BuildContext context, MedicineProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddDoctorSheet(provider: provider),
    );
  }

  BoxDecoration _premiumCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border.withOpacity(0.7)),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

class _AddDoctorSheet extends StatefulWidget {
  final MedicineProvider provider;

  const _AddDoctorSheet({required this.provider});

  @override
  State<_AddDoctorSheet> createState() => _AddDoctorSheetState();
}

class _AddDoctorSheetState extends State<_AddDoctorSheet> {
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Doctor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _nameController,
              label: 'Doctor Name',
              hintText: 'e.g., Dr. John Doe',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _specialtyController,
              label: 'Specialty',
              hintText: 'e.g., Cardiologist, General Physician',
              prefixIcon: Icon(
                Icons.medical_services_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hintText: 'e.g., +1 234 567 8900',
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) return;
                final doctor = Doctor(
                  name: _nameController.text.trim(),
                  specialty: _specialtyController.text.trim(),
                  phone: _phoneController.text.trim(),
                );
                widget.provider.addDoctor(doctor);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Save Doctor',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
