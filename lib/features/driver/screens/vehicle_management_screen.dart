import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/mobile_nav.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();

  static const _navItems = [
    MobileNavItem(label: 'Home', icon: Icons.dashboard_outlined, route: '/driver/dashboard'),
    MobileNavItem(label: 'Vehicles', icon: Icons.directions_car, route: '/driver/vehicles'),
    MobileNavItem(label: 'Fines', icon: Icons.list_alt, route: '/driver/fines'),
    MobileNavItem(label: 'Appeals', icon: Icons.message_outlined, route: '/driver/appeals'),
    MobileNavItem(label: 'Profile', icon: Icons.person_outline, route: '/driver/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUid = _auth.currentUid;

    if (currentUid == null || currentUid.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 48, color: TomsColors.mutedForeground),
                  const SizedBox(height: 16),
                  const Text(
                    'Please sign in again to view your vehicles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: TomsColors.mutedForeground),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/driver/login'),
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<VehicleModel>>(
      stream: _db.vehiclesByOwnerStream(currentUid),
      builder: (context, vehicleSnapshot) {
        final vehicles = vehicleSnapshot.data ?? const <VehicleModel>[];

        return StreamBuilder<List<FineModel>>(
          stream: _db.finesByDriverStream(currentUid),
          builder: (context, finesSnapshot) {
            final fines = finesSnapshot.data ?? const <FineModel>[];

            return Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            decoration: const BoxDecoration(gradient: TomsColors.driverGradient),
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 12,
                              left: 20,
                              right: 20,
                              bottom: 32,
                            ),
                            child: Row(
                              children: [
                                _backBtn(context),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'My Vehicles',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '${vehicles.length} registered vehicle${vehicles.length == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showAddSheet(context, currentUid),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: vehicleSnapshot.connectionState == ConnectionState.waiting
                                  ? const Padding(
                                      padding: EdgeInsets.only(top: 64),
                                      child: Center(child: CircularProgressIndicator()),
                                    )
                                  : vehicles.isEmpty
                                      ? _emptyState(context, currentUid)
                                      : Column(
                                          children: [
                                            ...vehicles.map(
                                              (vehicle) => Padding(
                                                padding: const EdgeInsets.only(bottom: 12),
                                                child: _vehicleCard(
                                                  vehicle,
                                                  _fineCountForPlate(vehicle.plateNumber, fines),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 60),
                                          ],
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  MobileNav(
                    items: _navItems,
                    currentRoute: '/driver/vehicles',
                    onNavigate: (route) => context.push(route),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(BuildContext context, String ownerId) {
    return Column(
      children: [
        GlassCard(
          elevated: true,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: TomsColors.secondary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.directions_car_outlined, size: 30, color: TomsColors.mutedForeground),
              ),
              const SizedBox(height: 16),
              const Text(
                'No vehicles added yet',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Only vehicles linked to your own driver account appear here. Add your first vehicle to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground, height: 1.4),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddSheet(context, ownerId),
                  icon: const Icon(Icons.add),
                  label: const Text('Add My Vehicle'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _vehicleCard(VehicleModel vehicle, int fineCount) {
    return GlassCard(
      elevated: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: TomsColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.directions_car, size: 28, color: TomsColors.mutedForeground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.plateNumber,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        _vehicleSubtitle(vehicle),
                        style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _chip('Registration', Icons.calendar_today, _formatRegistrationExpiry(vehicle.registrationExpiry)),
                const SizedBox(width: 8),
                _chip('Color', Icons.palette, vehicle.color.isEmpty ? 'Not set' : vehicle.color),
                const SizedBox(width: 8),
                _finesChip(fineCount.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backBtn(BuildContext ctx) {
    return GestureDetector(
      onTap: () => ctx.pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _chip(String label, IconData icon, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: TomsColors.secondary.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: TomsColors.mutedForeground,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _finesChip(String count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: TomsColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'FINES',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: TomsColors.mutedForeground,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TomsColors.accent),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, String ownerId) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddVehicleSheet(
        ownerId: ownerId,
        onSubmit: (vehicle) async {
          await _db.addVehicle(vehicle);
          await _db.logAction(ownerId, 'vehicle_added', 'Added vehicle ${vehicle.plateNumber}.');
        },
      ),
    );

    if (!context.mounted || result != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vehicle added successfully.')),
    );
  }

  int _fineCountForPlate(String plateNumber, List<FineModel> fines) {
    return fines.where((fine) => fine.vehiclePlate.trim().toUpperCase() == plateNumber.trim().toUpperCase()).length;
  }

  String _vehicleSubtitle(VehicleModel vehicle) {
    final parts = <String>[
      if (vehicle.color.trim().isNotEmpty) vehicle.color.trim(),
      if ((vehicle.year ?? '').trim().isNotEmpty) vehicle.year!.trim(),
      vehicle.make.trim(),
      vehicle.model.trim(),
    ];
    return parts.join(' ');
  }

  String _formatRegistrationExpiry(DateTime? expiry) {
    if (expiry == null) return 'Not set';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[expiry.month - 1]} ${expiry.year}';
  }
}

class _AddVehicleSheet extends StatefulWidget {
  const _AddVehicleSheet({
    required this.ownerId,
    required this.onSubmit,
  });

  final String ownerId;
  final Future<void> Function(VehicleModel vehicle) onSubmit;

  @override
  State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<_AddVehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  final _expiryController = TextEditingController();

  DateTime? _registrationExpiry;
  bool _saving = false;

  @override
  void dispose() {
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: TomsColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: TomsColors.border)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Vehicle', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: _saving ? null : () => context.pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: TomsColors.secondary),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(hintText: 'Plate Number'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter plate number.' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makeController,
                    decoration: const InputDecoration(hintText: 'Make'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter make.' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(hintText: 'Model'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter model.' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(hintText: 'Color'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Year'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final normalized = value.trim();
                      if (normalized.length != 4 || int.tryParse(normalized) == null) {
                        return 'Use 4 digits.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _expiryController,
              readOnly: true,
              onTap: _saving ? null : _pickExpiryDate,
              decoration: const InputDecoration(
                hintText: 'Registration Expiry',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TomsColors.success,
                  elevation: 4,
                  shadowColor: TomsColors.success.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add Vehicle', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationExpiry ?? DateTime(now.year, now.month, 1),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );

    if (picked == null) return;
    setState(() {
      _registrationExpiry = DateTime(picked.year, picked.month, picked.day);
      _expiryController.text = '${picked.day}/${picked.month}/${picked.year}';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final vehicle = VehicleModel(
        id: '',
        ownerId: widget.ownerId,
        plateNumber: _plateController.text.trim().toUpperCase(),
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        color: _colorController.text.trim(),
        year: _yearController.text.trim().isEmpty ? null : _yearController.text.trim(),
        registrationExpiry: _registrationExpiry,
      );

      await widget.onSubmit(vehicle);
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      setState(() => _saving = false);
    }
  }
}
