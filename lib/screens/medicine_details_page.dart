import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/medicine_model.dart';
import '../providers/medicine_provider.dart';
import 'edit_medicine_page.dart';
import '../utils/app_colors.dart';
import '../widgets/ui_kit.dart';

class MedicineDetailsPage extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailsPage({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    // Show the latest saved version so edits appear immediately.
    final latest = context.select<MedicineProvider, Medicine?>(
      (p) => p.medicines.where((m) => m.id == medicine.id).firstOrNull,
    );
    return _MedicineDetailsView(medicine: latest ?? medicine);
  }
}

class _MedicineDetailsView extends StatelessWidget {
  final Medicine medicine;

  const _MedicineDetailsView({required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'medicineImage-${medicine.id}',
                    child: medicine.image.isNotEmpty
                        ? Image.file(File(medicine.image), fit: BoxFit.cover)
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryLight,
                                  AppColors.secondaryLight,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.medication_liquid_outlined,
                              size: 80,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.3, 1],
                        colors: [
                          Colors.black.withValues(alpha: 0.18),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditMedicinePage(medicine: medicine),
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.accent,
                  ),
                  onPressed: () => _confirmDelete(context),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine.name,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medicine.type.isNotEmpty
                                  ? medicine.type
                                  : 'Medicine',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Dosage & Schedule'),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    Icons.medication_outlined,
                    'Dosage',
                    medicine.dosage,
                  ),
                  _buildInfoTile(
                    Icons.repeat,
                    'Repeat',
                    medicine.recurrence.isNotEmpty
                        ? medicine.recurrence
                        : 'Daily',
                  ),
                  _buildInfoTile(
                    Icons.calendar_month,
                    'Start Date',
                    medicine.scheduleStartDate.isNotEmpty
                        ? medicine.scheduleStartDate
                        : 'Not set',
                  ),
                  _buildInfoTile(
                    Icons.event_available,
                    'End Date',
                    medicine.scheduleEndDate.isNotEmpty
                        ? medicine.scheduleEndDate
                        : 'Not set',
                  ),
                  _buildInfoTile(
                    Icons.access_time_rounded,
                    'Reminder Time',
                    medicine.formattedReminderTime,
                  ),
                  _buildInfoTile(
                    Icons.inventory_2_outlined,
                    'Quantity',
                    medicine.quantity,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Additional Info'),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    Icons.family_restroom_rounded,
                    'Patient',
                    medicine.patient,
                  ),
                  _buildInfoTile(
                    Icons.description_outlined,
                    'Related Prescription',
                    medicine.prescription,
                  ),
                  _buildInfoTile(
                    Icons.calendar_today_outlined,
                    'Expiry Date',
                    medicine.expiryDate,
                  ),
                  _buildInfoTile(
                    Icons.history_rounded,
                    'Created At',
                    _formatCreatedAt(medicine.createdAt),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Notes'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      medicine.notes.isNotEmpty
                          ? medicine.notes
                          : 'No notes added.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    const icons = {
      'Dosage & Schedule': Icons.schedule_rounded,
      'Additional Info': Icons.info_rounded,
      'Notes': Icons.sticky_note_2_rounded,
    };
    return SectionHeader(
      icon: icons[title] ?? Icons.label_rounded,
      title: title,
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not Specified',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCreatedAt(String createdAt) {
    try {
      final parsed = DateTime.parse(createdAt);
      return DateFormat('yyyy-MM-dd hh:mm a').format(parsed);
    } catch (_) {
      return createdAt;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete medicine'),
          content: const Text(
            'Do you want to delete this medicine? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<MedicineProvider>(
                  context,
                  listen: false,
                ).deleteMedicine(medicine.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
