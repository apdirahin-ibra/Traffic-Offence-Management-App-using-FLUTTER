import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/fine_model.dart';
import '../../../models/offence_model.dart';
import '../../../widgets/fine_location_map.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/mobile_nav.dart';

class IssueFineScreen extends StatefulWidget {
  const IssueFineScreen({super.key});

  @override
  State<IssueFineScreen> createState() => _IssueFineScreenState();
}

class _IssueFineScreenState extends State<IssueFineScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();
  final _driverNidCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  List<OffenceModel> _offences = [];
  OffenceModel? _selectedOffence;
  bool _issued = false;
  bool _loading = false;
  String? _fineId;
  String? _driverName;
  String? _driverId;
  int _photos = 0;
  LatLng _selectedLocation = const LatLng(9.5624, 44.0770);

  static const _navItems = [
    MobileNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/police/dashboard'),
    MobileNavItem(label: 'Search', icon: Icons.search, route: '/police/search'),
    MobileNavItem(label: 'Issue Fine', icon: Icons.description_outlined, route: '/police/issue-fine'),
    MobileNavItem(label: 'History', icon: Icons.history, route: '/police/history'),
  ];

  @override
  void initState() {
    super.initState();
    _loadOffences();
  }

  @override
  void dispose() {
    _driverNidCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOffences() async {
    final list = await _db.getActiveOffences();
    if (mounted) {
      setState(() => _offences = list);
    }
  }

  Future<void> _lookupDriver() async {
    final nid = _driverNidCtrl.text.trim();
    if (nid.isEmpty) return;
    final user = await _db.getUserByNationalId(nid);
    if (mounted) {
      setState(() {
        _driverName = user?.name;
        _driverId = user?.uid;
      });
    }
  }

  Future<void> _issueFine() async {
    if (_selectedOffence == null || _plateCtrl.text.isEmpty) return;
    setState(() => _loading = true);

    try {
      final officerProfile = await _auth.getCurrentUserProfile();
      final fine = FineModel(
        id: '',
        driverId: _driverId ?? '',
        officerId: _auth.currentUid ?? '',
        vehiclePlate: _plateCtrl.text.trim(),
        offenceType: _selectedOffence!.name,
        amount: _selectedOffence!.amount,
        demeritPoints: _selectedOffence!.demeritPoints,
        status: 'pending',
        lat: _selectedLocation.latitude,
        lng: _selectedLocation.longitude,
        issuedAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 14)),
        driverName: _driverName,
        officerName: officerProfile?.name,
      );

      final id = await _db.createFine(fine);
      DemeritUpdateResult? demeritResult;

      if (_driverId != null && _selectedOffence!.demeritPoints > 0) {
        demeritResult = await _db.updateDemeritPoints(
          _driverId!,
          _selectedOffence!.demeritPoints,
          actorUserId: _auth.currentUid,
        );
      }

      await _db.logAction(
        _auth.currentUid ?? '',
        'issue_fine',
        'Issued fine $id for ${_selectedOffence!.name} to ${_driverName ?? _plateCtrl.text} at ${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
      );

      if (mounted) {
        setState(() {
          _fineId = id;
          _issued = true;
          _loading = false;
        });
        if (demeritResult?.autoSuspended ?? false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_driverName ?? 'Driver'} has been automatically suspended after reaching ${demeritResult!.currentPoints} demerit points.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_issued) return _confirmationView(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _header(context, 'Issue Fine', 'Record a new traffic violation'),
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          GlassCard(
                            elevated: true,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Driver Details'),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _driverNidCtrl,
                                        decoration: const InputDecoration(
                                          hintText: 'National ID',
                                          prefixIcon: Icon(Icons.badge_outlined, size: 18),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _lookupDriver,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Lookup'),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_driverName != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: TomsColors.success.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: TomsColors.success.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person, size: 16, color: TomsColors.success),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _driverName!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TomsColors.success),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _plateCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'Vehicle Plate Number',
                                    prefixIcon: Icon(Icons.directions_car, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassCard(
                            elevated: true,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Offence Details'),
                                const SizedBox(height: 12),
                                if (_offences.isEmpty)
                                  const Center(child: CircularProgressIndicator())
                                else
                                  DropdownButtonFormField<String>(
                                    value: _selectedOffence?.id,
                                    isExpanded: true,
                                    onChanged: (v) => setState(() => _selectedOffence = _offences.firstWhere((o) => o.id == v)),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      hintText: 'Select offence type',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    selectedItemBuilder: (context) => _offences.map((o) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${o.name} - \$${o.amount.toStringAsFixed(0)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    items: _offences.map((o) {
                                      return DropdownMenuItem<String>(
                                        value: o.id,
                                        child: Text(
                                          '${o.name} - \$${o.amount.toStringAsFixed(0)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                if (_selectedOffence != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _amountTile(
                                          'FINE AMOUNT',
                                          '\$${_selectedOffence!.amount.toStringAsFixed(0)}',
                                          TomsColors.primary.withValues(alpha: 0.08),
                                          TomsColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _amountTile(
                                          'DEMERIT POINTS',
                                          '-${_selectedOffence!.demeritPoints}',
                                          TomsColors.destructive.withValues(alpha: 0.08),
                                          TomsColors.destructive,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassCard(
                            elevated: true,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Evidence & Location'),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: TomsColors.success.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: TomsColors.success.withValues(alpha: 0.15)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: TomsColors.success),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Issue Location Selected', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: TomsColors.success)),
                                            Text(
                                              '${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                                              style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground, fontFamily: 'monospace'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FineLocationMap(
                                  latitude: _selectedLocation.latitude,
                                  longitude: _selectedLocation.longitude,
                                  interactive: true,
                                  height: 190,
                                  helperText: 'Tap anywhere on the map or drag the marker to set the exact violation location.',
                                  onTap: (point) => setState(() => _selectedLocation = point),
                                ),
                                const SizedBox(height: 12),
                                Text('EVIDENCE PHOTOS ($_photos/3)', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: TomsColors.mutedForeground, letterSpacing: 1)),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(3, (i) {
                                    final ok = i < _photos;
                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            if (_photos < 3) _photos++;
                                          }),
                                          child: Container(
                                            height: 96,
                                            decoration: BoxDecoration(
                                              color: ok ? TomsColors.success.withValues(alpha: 0.08) : TomsColors.secondary.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: ok ? TomsColors.success : TomsColors.border.withValues(alpha: 0.6), width: 2),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(ok ? Icons.check_circle : Icons.camera_alt, size: 20, color: ok ? TomsColors.success : TomsColors.mutedForeground),
                                                const SizedBox(height: 4),
                                                Text(ok ? 'Captured' : 'Tap to add', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: ok ? TomsColors.success : TomsColors.mutedForeground)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (_selectedOffence != null && _plateCtrl.text.isNotEmpty && !_loading) ? _issueFine : null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                shadowColor: TomsColors.primary.withValues(alpha: 0.25),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      _selectedOffence != null ? 'Issue Fine - \$${_selectedOffence!.amount.toStringAsFixed(0)}' : 'Issue Fine',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
          MobileNav(items: _navItems, currentRoute: '/police/issue-fine', onNavigate: (r) => context.push(r)),
        ],
      ),
    );
  }

  Widget _confirmationView(BuildContext context) {
    final shortId = _fineId != null && _fineId!.length > 5 ? 'FN-${_fineId!.substring(_fineId!.length - 5).toUpperCase()}' : _fineId ?? '';
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: TomsColors.success.withValues(alpha: 0.15)),
                      child: const Icon(Icons.check_circle, size: 48, color: TomsColors.success),
                    ),
                    const SizedBox(height: 24),
                    const Text('Fine Issued Successfully', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('The driver has been notified', style: const TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
                    const SizedBox(height: 32),
                    GlassCard(
                      elevated: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _summaryRow('Fine ID', shortId, mono: true),
                          const Divider(),
                          _summaryRow('Amount', '\$${_selectedOffence?.amount.toStringAsFixed(0) ?? '0'}', bold: true),
                          _summaryRow('Demerit', '-${_selectedOffence?.demeritPoints ?? 0}', color: TomsColors.destructive),
                          if (_driverName != null) _summaryRow('Driver', _driverName!),
                          _summaryRow('Plate', _plateCtrl.text),
                          _summaryRow(
                            'Location',
                            '${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                            mono: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => context.go('/police/dashboard'),
                        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Back to Dashboard'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          MobileNav(items: _navItems, currentRoute: '/police/issue-fine', onNavigate: (r) => context.push(r)),
        ],
      ),
    );
  }

  Widget _header(BuildContext ctx, String title, String sub) {
    return Container(
      decoration: const BoxDecoration(gradient: TomsColors.policeGradient),
      padding: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top + 12, left: 20, right: 20, bottom: 32),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ctx.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
              Text(sub, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(
        t.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TomsColors.mutedForeground, letterSpacing: 1.5),
      );

  Widget _amountTile(String label, String value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [bg, bg.withValues(alpha: 0.03)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: fg.withValues(alpha: 0.7), letterSpacing: 1, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool mono = false, bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: bold ? 18 : 13, fontWeight: FontWeight.w700, fontFamily: mono ? 'monospace' : null, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
