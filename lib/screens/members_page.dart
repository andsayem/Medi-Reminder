import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/member_model.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/empty_widget.dart';
import '../widgets/custom_textfield.dart';

class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();
    final members = provider.members;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Family Members'), centerTitle: true),
      body: members.isEmpty
          ? const EmptyWidget(
              title: 'No Members Found',
              subtitle: 'Add family members to associate medicines with them.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final member = members[index];
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
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : 'M',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      member.relation.isNotEmpty
                          ? member.relation
                          : 'Family Member',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () => provider.deleteMember(member.id!),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberSheet(context, provider),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Add Member'),
      ),
    );
  }

  void _showAddMemberSheet(BuildContext context, MedicineProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMemberSheet(provider: provider),
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

class _AddMemberSheet extends StatefulWidget {
  final MedicineProvider provider;

  const _AddMemberSheet({required this.provider});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _nameController = TextEditingController();
  final _relationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
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
              'Add Family Member',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _nameController,
              label: 'Member Name',
              hintText: 'e.g., Emily, Dad, etc.',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _relationController,
              label: 'Relation (Optional)',
              hintText: 'e.g., Daughter, Father, Spouse',
              prefixIcon: Icon(
                Icons.family_restroom_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) return;
                final member = Member(
                  name: _nameController.text.trim(),
                  relation: _relationController.text.trim(),
                );
                widget.provider.addMember(member);
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
                'Save Member',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
