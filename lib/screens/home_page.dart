import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medicine_model.dart';
import '../providers/medicine_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_presets.dart';
import '../widgets/empty_widget.dart';
import '../widgets/medicine_card.dart';
import '../widgets/ui_kit.dart';
import 'add_medicine_page.dart';
import 'blood_pressure_history_page.dart';
import 'blood_sugar_history_page.dart';
import 'doctors_page.dart';
import 'members_page.dart';
import 'prescriptions/medical_documents_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  String _typeFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  static const _prescriptionsPage = MedicalDocumentsPage(
    title: 'My Prescriptions',
    table: 'prescriptions',
  );
  static const _reportsPage = MedicalDocumentsPage(
    title: 'Medical Test Reports',
    table: 'test_reports',
  );

  List<({String label, IconData icon, Color color, Widget page})>
  get _shortcuts => const [
    (
      label: 'Prescription',
      icon: Icons.description_rounded,
      color: Color(0xFF6366F1),
      page: _prescriptionsPage,
    ),
    (
      label: 'Reports',
      icon: Icons.assignment_rounded,
      color: Color(0xFF0EA5E9),
      page: _reportsPage,
    ),
    (
      label: 'Pressure',
      icon: Icons.favorite_rounded,
      color: AppColors.primary,
      page: BloodPressureHistoryPage(),
    ),
    (
      label: 'Sugar',
      icon: Icons.water_drop_rounded,
      color: Color(0xFFF59E0B),
      page: BloodSugarHistoryPage(),
    ),
    (
      label: 'Doctors',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF10B981),
      page: DoctorsPage(),
    ),
    (
      label: 'Family',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFF8B5CF6),
      page: MembersPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: provider.fetchData,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(provider),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  AnimatedEntry(index: 0, child: _buildShortcuts()),
                  _buildExpiryAlert(provider),
                  const SizedBox(height: 22),
                  AnimatedEntry(
                    index: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SectionHeader(
                        icon: Icons.medication_rounded,
                        title: 'My Medicines',
                        trailing: _buildCountBadge(provider.medicines.length),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedEntry(index: 2, child: _buildSearchBar(provider)),
                  const SizedBox(height: 12),
                  _buildTypeFilter(provider),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            _buildMedicineContent(provider),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_main',
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData get _greetingIcon {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 17) return Icons.wb_sunny_rounded;
    return Icons.nightlight_round;
  }

  Widget _buildSliverAppBar(MedicineProvider provider) {
    final nextMedicines = provider.nextMedicines;

    String formatNextDose(DateTime dateTime) {
      final diff = dateTime.difference(DateTime.now());
      if (diff.inSeconds <= 0) return 'Due now';
      if (diff.inHours > 0) {
        return 'in ${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
      }
      return 'in ${diff.inMinutes}m';
    }

    final profileName = provider.activeProfile == 'Self'
        ? 'you'
        : provider.activeProfile;

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      title: const Text(
        'Medi Reminder',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [_buildProfileButton(provider), const SizedBox(width: 8)],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
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
          child: Stack(
            children: [
              Positioned(right: -54, top: -44, child: _bubble(180)),
              Positioned(left: -30, bottom: -40, child: _bubble(120)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(_greetingIcon, color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '$_greeting, today for $profileName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _buildNextDoseCard(
                          key: ValueKey(
                            '${provider.activeProfile}-${nextMedicines.length}',
                          ),
                          names: nextMedicines
                              .map((n) => n.medicine.name)
                              .join(', '),
                          subtitle: nextMedicines.isEmpty
                              ? null
                              : 'Next dose '
                                    '${formatNextDose(nextMedicines.first.nextDoseTime)}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildHeaderMetric(
                            icon: Icons.medication_liquid_rounded,
                            value: '${provider.medicines.length}',
                            label: 'Medicines',
                          ),
                          const SizedBox(width: 8),
                          _buildHeaderMetric(
                            icon: Icons.group_rounded,
                            value: '${provider.members.length + 1}',
                            label: 'Profiles',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(double size) => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.08),
    ),
  );

  Widget _buildNextDoseCard({
    required Key key,
    required String names,
    required String? subtitle,
  }) {
    final hasNext = subtitle != null;
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasNext ? Icons.alarm_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasNext ? names : 'No upcoming dose',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ?? 'Tap Add to set up a reminder',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
            duration: const Duration(milliseconds: 700),
            builder: (_, v, _) => Text(
              '$v',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile switcher (bottom sheet instead of dropdown)
  // ---------------------------------------------------------------------------

  Widget _buildProfileButton(MedicineProvider provider) {
    final name = provider.activeProfile == 'Self'
        ? 'Me'
        : provider.activeProfile;
    return PressableScale(
      onTap: () => _showProfileSheet(provider),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.only(left: 4, right: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: Colors.white,
              child: Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                name,
                key: ValueKey(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfileSheet(MedicineProvider provider) async {
    const addNew = '__add_member__';
    final result = await showOptionSheet<String>(
      context: context,
      title: 'Whose medicines?',
      icon: Icons.switch_account_rounded,
      selected: provider.activeProfile,
      options: [
        const SheetOption(
          value: 'Self',
          label: 'Me',
          subtitle: 'My own medicines',
          icon: Icons.person_rounded,
        ),
        ...provider.members.map(
          (m) => SheetOption(
            value: m.name,
            label: m.name,
            subtitle: m.relation.isEmpty ? null : m.relation,
            icon: Icons.family_restroom_rounded,
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SheetOption(
          value: addNew,
          label: 'Add family member',
          icon: Icons.group_add_rounded,
          color: AppColors.success,
        ),
      ],
    );
    if (result == null) return;
    if (result == addNew) {
      _open(const MembersPage());
    } else {
      provider.setActiveProfile(result);
    }
  }

  // ---------------------------------------------------------------------------
  // Quick shortcuts
  // ---------------------------------------------------------------------------

  Widget _buildShortcuts() {
    final items = _shortcuts;
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return PressableScale(
            onTap: () => _open(item.page),
            child: SizedBox(
              width: 70,
              child: Column(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(item.icon, color: item.color, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Expiry alert
  // ---------------------------------------------------------------------------

  Widget _buildExpiryAlert(MedicineProvider provider) {
    final today = DateTime.now();
    final soon = provider.medicines.where((m) {
      final date = DateTime.tryParse(m.expiryDate);
      if (date == null) return false;
      return date.difference(today).inDays <= 30;
    }).toList();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: soon.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        soon.length == 1
                            ? '${soon.first.name} expires soon '
                                  '(${soon.first.expiryDate})'
                            : '${soon.length} medicines expire within 30 days',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search + filter
  // ---------------------------------------------------------------------------

  Widget _buildCountBadge(int count) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(MedicineProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ListenableBuilder(
                listenable: _searchController,
                builder: (context, _) => TextField(
                  controller: _searchController,
                  onChanged: provider.searchMedicines,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search medicine...',
                    filled: false,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              provider.searchMedicines('');
                            },
                          ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PressableScale(
            onTap: provider.toggleView,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) =>
                    RotationTransition(turns: a, child: c),
                child: Icon(
                  provider.isGridView
                      ? Icons.view_agenda_rounded
                      : Icons.grid_view_rounded,
                  key: ValueKey(provider.isGridView),
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter(MedicineProvider provider) {
    final types = provider.medicines
        .map((m) => m.type)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    if (types.length < 2) return const SizedBox.shrink();
    if (_typeFilter != 'All' && !types.contains(_typeFilter)) {
      _typeFilter = 'All';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ChipScroller(
        children: [
          IconChoiceChip(
            label: 'All',
            icon: Icons.apps_rounded,
            selected: _typeFilter == 'All',
            onTap: () => setState(() => _typeFilter = 'All'),
          ),
          ...types.map(
            (t) => IconChoiceChip(
              label: t,
              icon: AppPresets.iconForType(t),
              selected: _typeFilter == t,
              onTap: () => setState(() => _typeFilter = t),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Medicine list
  // ---------------------------------------------------------------------------

  Widget _buildMedicineContent(MedicineProvider provider) {
    if (provider.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Medicine> medicines = _typeFilter == 'All'
        ? provider.medicines
        : provider.medicines.where((m) => m.type == _typeFilter).toList();

    if (medicines.isEmpty) {
      final searching = _searchController.text.isNotEmpty;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          children: [
            EmptyWidget(
              title: searching ? 'No match found' : 'All clear!',
              subtitle: searching
                  ? 'Try a different name.'
                  : "You haven't added any medicines yet.",
            ),
            if (!searching)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: ElevatedButton.icon(
                  onPressed: () => _open(const AddMedicinePage()),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add your first medicine'),
                ),
              ),
          ],
        ),
      );
    }

    Widget card(int index) => AnimatedEntry(
      key: ValueKey('${medicines[index].id}-${provider.isGridView}'),
      index: index,
      child: MedicineCard(
        medicine: medicines[index],
        onDelete: provider.deleteMedicine,
      ),
    );

    if (provider.isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.70,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => card(index),
            childCount: medicines.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: card(index),
          ),
          childCount: medicines.length,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // "Add" sheet — slides up from the footer
  // ---------------------------------------------------------------------------

  Future<void> _showAddSheet() async {
    final page = await showOptionSheet<Widget>(
      context: context,
      title: 'What do you want to add?',
      icon: Icons.add_circle_rounded,
      options: const [
        SheetOption(
          value: AddMedicinePage(),
          label: 'Medicine',
          subtitle: 'With reminder & dosage',
          icon: Icons.medication_rounded,
        ),
        SheetOption(
          value: _prescriptionsPage,
          label: 'Prescription',
          subtitle: 'Photo of doctor\'s prescription',
          icon: Icons.description_rounded,
          color: Color(0xFF6366F1),
        ),
        SheetOption(
          value: _reportsPage,
          label: 'Test report',
          icon: Icons.assignment_rounded,
          color: Color(0xFF0EA5E9),
        ),
        SheetOption(
          value: BloodPressureHistoryPage(),
          label: 'Blood pressure',
          icon: Icons.favorite_rounded,
          color: AppColors.accent,
        ),
        SheetOption(
          value: BloodSugarHistoryPage(),
          label: 'Blood sugar',
          icon: Icons.water_drop_rounded,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
    if (page != null) _open(page);
  }

  // ---------------------------------------------------------------------------
  // Drawer
  // ---------------------------------------------------------------------------

  Widget _buildDrawer() {
    Widget item(IconData icon, String title, Widget? page, [Color? color]) {
      return ListTile(
        leading: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color ?? AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (page != null) _open(page);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      );
    }

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                item(Icons.home_rounded, 'Home', null),
                for (final s in _shortcuts)
                  item(s.icon, s.label, s.page, s.color),
              ],
            ),
          ),
          const Divider(indent: 24, endIndent: 24),
          item(Icons.settings_rounded, 'Settings', const SettingsPage()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 32),
      margin: const EdgeInsets.only(bottom: 8),
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
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Medi Reminder',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Keep your health on track',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
