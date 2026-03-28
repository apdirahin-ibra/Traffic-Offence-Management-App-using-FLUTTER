import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/mobile_nav.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';
import '../../../models/user_model.dart';
import '../../../models/vehicle_model.dart';

class DriverSearchScreen extends StatefulWidget {
  const DriverSearchScreen({super.key});

  @override
  State<DriverSearchScreen> createState() => _DriverSearchScreenState();
}

class _DriverSearchScreenState extends State<DriverSearchScreen> {
  final _db = FirestoreService();
  final _searchCtrl = TextEditingController();

  bool _searched = false;
  bool _loading = false;
  String? _error;
  UserModel? _driver;
  VehicleModel? _matchedVehicle;
  List<VehicleModel> _vehicles = const [];
  List<FineModel> _fines = const [];

  static const _navItems = [
    MobileNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/police/dashboard'),
    MobileNavItem(label: 'Search', icon: Icons.search, route: '/police/search'),
    MobileNavItem(label: 'Issue Fine', icon: Icons.description_outlined, route: '/police/issue-fine'),
    MobileNavItem(label: 'History', icon: Icons.history, route: '/police/history'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searched = false;
        _error = 'Enter a plate number or national ID.';
      });
      return;
    }

    setState(() {
      _searched = true;
      _loading = true;
      _error = null;
      _driver = null;
      _matchedVehicle = null;
      _vehicles = const [];
      _fines = const [];
    });

    try {
      UserModel? driver = await _db.getUserByNationalId(query);
      VehicleModel? matchedVehicle;

      if (driver == null) {
        matchedVehicle = await _db.getVehicleByPlate(query.toUpperCase());
        if (matchedVehicle != null) {
          driver = await _db.getUser(matchedVehicle.ownerId);
        }
      }

      if (driver == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'No driver found for "$query".';
        });
        return;
      }

      final vehicles = await _db.vehiclesByOwnerStream(driver.uid).first;
      final fines = await _db.finesByDriverStream(driver.uid).first;

      if (!mounted) return;
      setState(() {
        _loading = false;
        _driver = driver;
        _matchedVehicle = matchedVehicle;
        _vehicles = vehicles;
        _fines = fines;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Search failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final suspended = _driver?.isSuspended ?? false;
    final points = _driver?.demeritPoints ?? 0;
    const maxPoints = FirestoreService.suspensionThreshold;
    final recentFineCount = _fines.length;
    final remaining = (maxPoints - points).clamp(0, maxPoints);
    final displayVehicles = _vehicles.isNotEmpty
        ? _vehicles
        : (_matchedVehicle != null ? [_matchedVehicle!] : <VehicleModel>[]);

    return Scaffold(
      body: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [
          Container(
            decoration: const BoxDecoration(gradient: TomsColors.policeGradient),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 32),
            child: Row(children: [
              _backBtn(context),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Search Driver', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Look up by plate or ID', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
              ]),
            ]),
          ),
          Transform.translate(
            offset: const Offset(0, -16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                GlassCard(elevated: true, padding: const EdgeInsets.all(12), child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onSubmitted: (_) => _performSearch(),
                      decoration: InputDecoration(
                        hintText: 'Plate number or National ID...',
                        prefixIcon: const Icon(Icons.search, size: 18, color: TomsColors.mutedForeground),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        fillColor: TomsColors.secondary.withValues(alpha: 0.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _performSearch,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search, size: 20),
                    ),
                  ),
                ])),
                const SizedBox(height: 12),
                Row(children: ['Plate Number', 'National ID'].map((label) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: TomsColors.secondary, borderRadius: BorderRadius.circular(100), border: Border.all(color: TomsColors.border.withValues(alpha: 0.5))),
                    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TomsColors.mutedForeground)),
                  ),
                )).toList()),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TomsColors.destructive.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: TomsColors.destructive.withValues(alpha: 0.2)),
                    ),
                    child: Text(_error!, style: const TextStyle(fontSize: 12, color: TomsColors.destructive)),
                  ),
                ],
                if (_searched && !_loading && _driver != null) ...[
                  const SizedBox(height: 16),
                  if (suspended)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [TomsColors.destructive.withValues(alpha: 0.1), TomsColors.destructive.withValues(alpha: 0.05)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TomsColors.destructive.withValues(alpha: 0.3)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(gradient: TomsColors.dangerGradient, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.warning, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('License Suspended', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TomsColors.destructive)),
                          const SizedBox(height: 2),
                          Text("This driver's license is currently suspended.", style: TextStyle(fontSize: 11, color: TomsColors.destructive.withValues(alpha: 0.7))),
                        ])),
                      ]),
                    ),
                  if (suspended) const SizedBox(height: 12),
                  GlassCard(elevated: true, child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: TomsColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.person, size: 28, color: TomsColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_driver!.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          Text(_driver!.phone.isEmpty ? _driver!.email : _driver!.phone, style: TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
                        ])),
                        StatusBadge.fromStatus(_driver!.licenseStatus),
                      ]),
                    ),
                    Divider(height: 1, color: TomsColors.border.withValues(alpha: 0.5)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: _infoField('National ID', _driver!.nationalId, mono: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _infoField('License Status', _driver!.licenseStatus.toUpperCase())),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _infoField('Recent Fines', '$recentFineCount violations')),
                          const SizedBox(width: 16),
                          Expanded(child: _infoField('Matched Plate', _matchedVehicle?.plateNumber ?? (displayVehicles.isNotEmpty ? displayVehicles.first.plateNumber : 'N/A'), mono: true)),
                        ]),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: TomsColors.secondary.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Demerit Points', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text('$points/$maxPoints', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: points >= maxPoints ? TomsColors.destructive : TomsColors.primary)),
                          ]),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (points / maxPoints).clamp(0, 1),
                              minHeight: 12,
                              backgroundColor: TomsColors.borderLight,
                              valueColor: AlwaysStoppedAnimation(
                                points >= maxPoints ? TomsColors.destructive : points >= 18 ? TomsColors.accent : TomsColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            suspended ? 'Suspended due to demerit points' : '$remaining points remaining before suspension',
                            style: TextStyle(fontSize: 10, color: TomsColors.mutedForeground),
                          ),
                        ]),
                      ),
                    ),
                  ])),
                  const SizedBox(height: 16),
                  _sectionLabel('Registered Vehicles (${displayVehicles.length})'),
                  const SizedBox(height: 8),
                  if (displayVehicles.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No registered vehicles found', style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
                      ),
                    )
                  else
                    ...displayVehicles.map((vehicle) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _vehicleItem(vehicle),
                    )),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/police/issue-fine'),
                      icon: const Icon(Icons.credit_card, size: 20),
                      label: const Text('Issue Fine to This Driver'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: TomsColors.primary.withValues(alpha: 0.25),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ]))),
        MobileNav(items: _navItems, currentRoute: '/police/search', onNavigate: (r) => context.push(r)),
      ]),
    );
  }

  Widget _backBtn(BuildContext ctx) {
    return GestureDetector(
      onTap: () => ctx.pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
      ),
    );
  }

  Widget _infoField(String label, String value, {bool mono = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: TomsColors.mutedForeground, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null)),
    ]);
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TomsColors.mutedForeground, letterSpacing: 1.5)),
    );
  }

  Widget _vehicleItem(VehicleModel vehicle) {
    final description = [
      if (vehicle.year != null && vehicle.year!.isNotEmpty) vehicle.year!,
      if (vehicle.color.isNotEmpty) vehicle.color,
      vehicle.make,
      vehicle.model,
    ].where((part) => part.isNotEmpty).join(' ');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: TomsColors.secondary, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.directions_car, size: 20, color: TomsColors.mutedForeground),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(vehicle.plateNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
          Text(description.isEmpty ? 'Vehicle details unavailable' : description, style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
        ])),
      ]),
    );
  }
}
