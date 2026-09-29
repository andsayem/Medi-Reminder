import 'dart:io';

import 'package:flutter/material.dart';

import '../models/medicine_model.dart';
import '../screens/medicine_details_page.dart';
import '../utils/app_colors.dart';
import '../utils/app_presets.dart';
import 'ui_kit.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final ValueChanged<int> onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxHeight.isFinite && constraints.maxHeight < 260;
        final imageHeight = isCompact ? 88.0 : 140.0;

        return PressableScale(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicineDetailsPage(medicine: medicine),
              ),
            );
          },
          onLongPress: () => _confirmDelete(context),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border.withOpacity(0.65)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(imageHeight),
                  Padding(
                    padding: EdgeInsets.all(isCompact ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: TextStyle(
                            fontSize: isCompact ? 15 : 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        _buildMetaRow(isCompact),
                        SizedBox(height: isCompact ? 10 : 16),
                        _buildReminderRow(context, isCompact),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_rounded,
          color: AppColors.accent,
          size: 36,
        ),
        title: Text('Delete ${medicine.name}?'),
        content: const Text('Its reminders will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) onDelete(medicine.id!);
  }

  Widget? _buildExpiryBadge() {
    final date = DateTime.tryParse(medicine.expiryDate);
    if (date == null) return null;
    final days = date.difference(DateTime.now()).inDays;
    if (days > 30) return null;
    final expired = days < 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: expired ? AppColors.accent : AppColors.warning,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            expired ? 'Expired' : 'Expires ${days}d',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(double height) {
    return Stack(
      children: [
        Hero(
          tag: 'medicineImage-${medicine.id}',
          child: SizedBox(
            height: height,
            width: double.infinity,
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
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
        if (_buildExpiryBadge() case final badge?)
          Positioned(top: 10, left: 10, child: badge),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppPresets.iconForType(medicine.type),
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  medicine.type.isNotEmpty ? medicine.type : 'Medicine',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(bool isCompact) {
    return Row(
      children: [
        const Icon(
          Icons.family_restroom_rounded,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            medicine.patient == 'Self' ? 'Me' : medicine.patient,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isCompact) ...[
          const SizedBox(width: 12),
          const Icon(
            Icons.medication_outlined,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              medicine.dosage,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// "Morning · Night" for a 1+0+1 pattern, else the custom reminder time.
  String _scheduleText() {
    final parts = medicine.dosage.split('+').map((p) => p.trim()).toList();
    if (parts.length == 3 && parts.every((p) => int.tryParse(p) != null)) {
      final slots = [
        for (var i = 0; i < 3; i++)
          if (int.parse(parts[i]) > 0) AppPresets.slotLabels[i],
      ];
      if (slots.isNotEmpty) return slots.join(' · ');
    }
    return medicine.formattedReminderTime;
  }

  Widget _buildReminderRow(BuildContext context, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _scheduleText(),
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () => _confirmDelete(context),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
