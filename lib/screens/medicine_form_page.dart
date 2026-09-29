import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/medicine_model.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_presets.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/ui_kit.dart';
import 'prescriptions/medical_documents_page.dart';

/// Shared add / edit form. Pass [medicine] to edit an existing one.
class MedicineFormPage extends StatefulWidget {
  final Medicine? medicine;

  const MedicineFormPage({super.key, this.medicine});

  @override
  State<MedicineFormPage> createState() => _MedicineFormPageState();
}

class _MedicineFormPageState extends State<MedicineFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;

  late String _selectedType;
  late String _selectedPrescription;
  late String _selectedReminder;
  late String _selectedRecurrence;
  late String _selectedStartDate;
  late String _selectedEndDate;
  late String _selectedExpiry;
  late String _imagePath;
  int? _durationDays;

  int _morning = 1;
  int _afternoon = 0;
  int _evening = 1;
  bool _useQuickDosage = true;
  bool _showMore = false;

  bool get _isEdit => widget.medicine != null;

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final m = widget.medicine;
    _nameController = TextEditingController(text: m?.name ?? '');
    _dosageController = TextEditingController(text: m?.dosage ?? '');
    _quantityController = TextEditingController(text: m?.quantity ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');
    _selectedType = (m?.type.isNotEmpty ?? false)
        ? m!.type
        : AppPresets.medicineTypes.first.label;
    _selectedPrescription = m?.prescription ?? '';
    _selectedReminder = m?.reminderTime ?? '';
    _selectedRecurrence = (m?.recurrence.isNotEmpty ?? false)
        ? m!.recurrence
        : 'Daily';
    // New medicines start today by default.
    _selectedStartDate =
        m?.scheduleStartDate ?? _dateFormat.format(DateTime.now());
    _selectedEndDate = m?.scheduleEndDate ?? '';
    _selectedExpiry = m?.expiryDate ?? '';
    _imagePath = m?.image ?? '';
    _durationDays = _selectedEndDate.isEmpty ? 0 : null;

    if (m != null) {
      _useQuickDosage = false;
      _morning = 0;
      _evening = 0;
      _applyPattern(m.dosage);
      // Open extra section if the medicine already has data there.
      _showMore = [
        m.quantity,
        m.notes,
        m.prescription,
        m.expiryDate,
        m.reminderTime,
      ].any((v) => v.isNotEmpty);
    }
  }

  bool _applyPattern(String dosage) {
    final match = RegExp(
      r'^\s*(\d+)\s*\+\s*(\d+)\s*\+\s*(\d+)\s*$',
    ).firstMatch(dosage);
    if (match == null) return false;
    _morning = int.parse(match.group(1)!);
    _afternoon = int.parse(match.group(2)!);
    _evening = int.parse(match.group(3)!);
    _useQuickDosage = true;
    return true;
  }

  String get _pattern => '$_morning+$_afternoon+$_evening';

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Pickers
  // ---------------------------------------------------------------------------

  Future<void> _pickImage() async {
    final source = await showOptionSheet<ImageSource>(
      context: context,
      title: 'Medicine photo',
      icon: Icons.add_a_photo_rounded,
      options: const [
        SheetOption(
          value: ImageSource.camera,
          label: 'Take a photo',
          subtitle: 'Use camera',
          icon: Icons.camera_alt_rounded,
        ),
        SheetOption(
          value: ImageSource.gallery,
          label: 'Choose from gallery',
          icon: Icons.photo_library_rounded,
          color: AppColors.secondary,
        ),
      ],
      footer: _imagePath.isEmpty
          ? null
          : TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _imagePath = '');
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remove photo'),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (picked != null) setState(() => _imagePath = picked.path);
    } catch (_) {
      // ignore image picker failure and remain stable
    }
  }

  TimeOfDay _initialReminderTime() {
    if (_selectedReminder.isEmpty) return TimeOfDay.now();
    try {
      final parsed = _selectedReminder.contains(' ')
          ? DateFormat.jm().parse(_selectedReminder)
          : DateFormat('HH:mm').parse(_selectedReminder);
      return TimeOfDay.fromDateTime(parsed);
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  Future<void> _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _initialReminderTime(),
    );
    if (time == null) return;
    setState(() {
      _selectedReminder = DateFormat(
        'HH:mm',
      ).format(DateTime(0, 0, 0, time.hour, time.minute));
    });
  }

  Future<void> _selectStartDate() async {
    final initial = DateTime.tryParse(_selectedStartDate) ?? DateTime.now();
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.isBefore(now) ? initial : now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null) return;
    setState(() {
      _selectedStartDate = _dateFormat.format(date);
      if (_durationDays != null && _durationDays! > 0) {
        _setDuration(_durationDays!);
      } else {
        final end = DateTime.tryParse(_selectedEndDate);
        if (end != null && end.isBefore(date)) _selectedEndDate = '';
      }
    });
  }

  Future<void> _selectEndDate() async {
    final first = DateTime.tryParse(_selectedStartDate) ?? DateTime.now();
    final current = DateTime.tryParse(_selectedEndDate);
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? first.add(const Duration(days: 1)),
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;
    setState(() {
      _selectedEndDate = _dateFormat.format(date);
      _durationDays = null;
    });
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final current = DateTime.tryParse(_selectedExpiry);
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now.add(const Duration(days: 180)),
      firstDate: current != null && current.isBefore(now) ? current : now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null) return;
    setState(() => _selectedExpiry = _dateFormat.format(date));
  }

  void _setDuration(int days) {
    _durationDays = days;
    if (days == 0) {
      _selectedEndDate = '';
      return;
    }
    final start = DateTime.tryParse(_selectedStartDate) ?? DateTime.now();
    _selectedEndDate = _dateFormat.format(start.add(Duration(days: days - 1)));
  }

  Future<void> _selectPrescription(MedicineProvider provider) async {
    if (provider.prescriptions.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MedicalDocumentsPage(
            title: 'My Prescriptions',
            table: 'prescriptions',
          ),
        ),
      );
      return;
    }
    final titles = provider.prescriptions
        .map((d) => d.title)
        .where((t) => t.trim().isNotEmpty)
        .toSet();
    final result = await showOptionSheet<String>(
      context: context,
      title: 'Link a prescription',
      icon: Icons.description_rounded,
      selected: _selectedPrescription,
      options: [
        const SheetOption(
          value: '',
          label: 'No prescription',
          icon: Icons.link_off_rounded,
          color: AppColors.textSecondary,
        ),
        ...titles.map(
          (t) =>
              SheetOption(value: t, label: t, icon: Icons.description_outlined),
        ),
      ],
    );
    if (result != null) setState(() => _selectedPrescription = result);
  }

  void _appendNote(String text) {
    final current = _notesController.text.trim();
    if (current.contains(text)) return;
    _notesController.text = current.isEmpty ? text : '$current, $text';
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    final provider = context.read<MedicineProvider>();
    final dosage = _useQuickDosage ? _pattern : _dosageController.text.trim();

    if (_useQuickDosage && _morning + _afternoon + _evening == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Set at least one dose')));
      return;
    }

    final base =
        widget.medicine ??
        Medicine(
          name: '',
          type: '',
          dosage: '',
          quantity: '',
          doctor: '',
          notes: '',
          image: '',
          reminderTime: '',
          recurrence: 'Daily',
          scheduleStartDate: '',
          scheduleEndDate: '',
          expiryDate: '',
          createdAt: DateTime.now().toIso8601String(),
        );

    final medicine = base.copyWith(
      name: _nameController.text.trim(),
      type: _selectedType,
      dosage: dosage,
      quantity: _quantityController.text.trim(),
      doctor: '',
      prescription: _selectedPrescription,
      patient: provider.activeProfile,
      notes: _notesController.text.trim(),
      image: _imagePath,
      reminderTime: _selectedReminder,
      recurrence: _selectedRecurrence,
      scheduleStartDate: _selectedStartDate,
      scheduleEndDate: _selectedEndDate,
      expiryDate: _selectedExpiry,
    );

    if (_isEdit) {
      await provider.updateMedicine(medicine);
    } else {
      await provider.addMedicine(medicine);
    }
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          _isEdit
              ? '${medicine.name} updated'
              : '${medicine.name} added to your list',
        ),
      ),
    );
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();
    var section = 0;

    Widget block(Widget child) => AnimatedEntry(
      index: section++,
      child: Padding(padding: const EdgeInsets.only(bottom: 26), child: child),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    block(_buildNameSection(provider)),
                    block(_buildTypeSection()),
                    block(_buildDosageSection()),
                    block(_buildScheduleSection()),
                    block(_buildMoreSection(provider)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSaveBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Text(_isEdit ? 'Edit Medicine' : 'Add Medicine'),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPhotoButton(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _imagePath.isEmpty
                          ? 'Tap the camera to add a photo\n(optional)'
                          : 'Photo added. Tap to change',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoButton() {
    return PressableScale(
      onTap: _pickImage,
      child: Hero(
        tag: 'medicineImage-${widget.medicine?.id ?? 'new'}',
        child: Container(
          height: 78,
          width: 78,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _imagePath.isEmpty
                ? const Icon(
                    Icons.add_a_photo_rounded,
                    key: ValueKey('empty'),
                    color: Colors.white,
                    size: 30,
                  )
                : Image.file(
                    File(_imagePath),
                    key: ValueKey(_imagePath),
                    fit: BoxFit.cover,
                    width: 78,
                    height: 78,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameSection(MedicineProvider provider) {
    // Names the user already added come first, then common ones.
    final used = provider.medicines.map((m) => m.name).toList();
    final all = {...used, ...AppPresets.commonMedicines}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          icon: Icons.medication_rounded,
          title: 'Medicine name',
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _nameController,
          label: 'Medicine Name',
          hintText: 'e.g., Napa',
          validator: (value) => value?.trim().isEmpty ?? true
              ? 'Medicine name is required'
              : null,
        ),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: _nameController,
          builder: (context, _) {
            final q = _nameController.text.trim().toLowerCase();
            final matches = all
                .where(
                  (n) => n.toLowerCase().contains(q) && n.toLowerCase() != q,
                )
                .take(12)
                .toList();
            return AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: matches.isEmpty
                  ? const SizedBox(width: double.infinity)
                  : ChipScroller(
                      children: matches
                          .map(
                            (n) => IconChoiceChip(
                              label: n,
                              icon: used.contains(n)
                                  ? Icons.history_rounded
                                  : Icons.add_rounded,
                              selected: false,
                              onTap: () {
                                _nameController.text = n;
                                _nameController.selection =
                                    TextSelection.collapsed(offset: n.length);
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          )
                          .toList(),
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypeSection() {
    final types = [
      ...AppPresets.medicineTypes,
      if (!AppPresets.medicineTypes.any((t) => t.label == _selectedType))
        (label: _selectedType, icon: Icons.medication_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(icon: Icons.category_rounded, title: 'Type'),
        const SizedBox(height: 12),
        ChipScroller(
          children: types
              .map(
                (t) => IconChoiceChip(
                  label: t.label,
                  icon: t.icon,
                  selected: _selectedType == t.label,
                  onTap: () => setState(() => _selectedType = t.label),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDosageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: Icons.schedule_rounded,
          title: 'How many & when',
          trailing: TextButton(
            onPressed: () => setState(() => _useQuickDosage = !_useQuickDosage),
            child: Text(_useQuickDosage ? 'Custom' : 'Pattern'),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(sizeFactor: anim, child: child),
          ),
          child: _useQuickDosage
              ? Column(
                  key: const ValueKey('pattern'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ChipScroller(
                      children: AppPresets.dosagePatterns
                          .map(
                            (p) => IconChoiceChip(
                              label: p,
                              selected: _pattern == p,
                              onTap: () => setState(() => _applyPattern(p)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    _buildDosageSteppers(),
                  ],
                )
              : CustomTextField(
                  key: const ValueKey('custom'),
                  controller: _dosageController,
                  label: 'Custom Dosage',
                  hintText: 'e.g., 500mg - 1 pill',
                  validator: (value) =>
                      !_useQuickDosage && (value?.trim().isEmpty ?? true)
                      ? 'Dosage is required'
                      : null,
                ),
        ),
      ],
    );
  }

  Widget _buildDosageSteppers() {
    final values = [_morning, _afternoon, _evening];
    void update(int slot, int value) {
      if (value < 0 || value > 9) return;
      HapticFeedback.selectionClick();
      setState(() {
        if (slot == 0) _morning = value;
        if (slot == 1) _afternoon = value;
        if (slot == 2) _evening = value;
      });
    }

    return Row(
      children: List.generate(3, (slot) {
        final active = values[slot] > 0;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.only(left: slot == 0 ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  AppPresets.slotIcons[slot],
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  AppPresets.slotLabels[slot],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepButton(
                      Icons.remove_rounded,
                      () => update(slot, values[slot] - 1),
                    ),
                    SizedBox(
                      width: 30,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Text(
                          '${values[slot]}',
                          key: ValueKey(values[slot]),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    _stepButton(
                      Icons.add_rounded,
                      () => update(slot, values[slot] + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          icon: Icons.event_repeat_rounded,
          title: 'Repeat & duration',
        ),
        const SizedBox(height: 12),
        ChipScroller(
          children: AppPresets.repeats
              .map(
                (r) => IconChoiceChip(
                  label: r.label,
                  icon: r.icon,
                  selected: _selectedRecurrence == r.label,
                  onTap: () => setState(() => _selectedRecurrence = r.label),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        ChipScroller(
          children: AppPresets.durations
              .map(
                (d) => IconChoiceChip(
                  label: d.label,
                  icon: d.days == 0 ? Icons.all_inclusive_rounded : null,
                  selected: _durationDays == d.days,
                  onTap: () => setState(() => _setDuration(d.days)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PickerTile(
                label: 'Start',
                value: _selectedStartDate,
                icon: Icons.play_circle_outline_rounded,
                onTap: _selectStartDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PickerTile(
                label: 'End',
                value: _selectedEndDate,
                placeholder: 'No end',
                icon: Icons.flag_outlined,
                onTap: _selectEndDate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoreSection(MedicineProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PressableScale(
          onTap: () => setState(() => _showMore = !_showMore),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: SectionHeader(
              icon: Icons.tune_rounded,
              title: 'More details (optional)',
              trailing: AnimatedRotation(
                turns: _showMore ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_showMore
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _PickerTile(
                              label: 'Custom reminder',
                              value: _selectedReminder,
                              placeholder: 'Optional',
                              icon: Icons.alarm_rounded,
                              onTap: _selectReminderTime,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PickerTile(
                              label: 'Expiry date',
                              value: _selectedExpiry,
                              placeholder: 'Optional',
                              icon: Icons.event_busy_rounded,
                              onTap: _selectExpiryDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(
                        icon: Icons.inventory_2_rounded,
                        title: 'Quantity',
                      ),
                      const SizedBox(height: 10),
                      ChipScroller(
                        children: AppPresets.quantities
                            .map(
                              (q) => IconChoiceChip(
                                label: q,
                                selected: _quantityController.text.trim() == q,
                                onTap: () => setState(
                                  () => _quantityController.text = q,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _quantityController,
                        label: 'Total Quantity',
                        hintText: 'e.g., 30 pills',
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(
                        icon: Icons.description_rounded,
                        title: 'Prescription',
                      ),
                      const SizedBox(height: 10),
                      _PickerTile(
                        label: 'Linked prescription',
                        value: _selectedPrescription,
                        placeholder: provider.prescriptions.isEmpty
                            ? 'None yet. Tap to add one'
                            : 'Tap to choose',
                        icon: Icons.link_rounded,
                        onTap: () => _selectPrescription(provider),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(
                        icon: Icons.sticky_note_2_rounded,
                        title: 'Notes',
                      ),
                      const SizedBox(height: 10),
                      ChipScroller(
                        children: AppPresets.mealTimings
                            .map(
                              (m) => IconChoiceChip(
                                label: m.label,
                                icon: m.icon,
                                selected: _notesController.text.contains(
                                  m.label,
                                ),
                                onTap: () => _appendNote(m.label),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      CustomTextField(
                        controller: _notesController,
                        label: 'Additional Notes',
                        hintText: 'Special instructions...',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSaveBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _save,
          icon: Icon(_isEdit ? Icons.check_rounded : Icons.add_rounded),
          label: Text(_isEdit ? 'Save Changes' : 'Add Medicine'),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.placeholder = 'Select',
  });

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    empty ? placeholder : value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: empty ? FontWeight.w500 : FontWeight.w700,
                      color: empty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
