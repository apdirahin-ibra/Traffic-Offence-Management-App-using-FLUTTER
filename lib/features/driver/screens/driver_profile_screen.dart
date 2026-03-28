import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/mobile_nav.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  static const _navItems = [
    MobileNavItem(label: 'Home', icon: Icons.dashboard_outlined, route: '/driver/dashboard'),
    MobileNavItem(label: 'Vehicles', icon: Icons.directions_car, route: '/driver/vehicles'),
    MobileNavItem(label: 'Fines', icon: Icons.list_alt, route: '/driver/fines'),
    MobileNavItem(label: 'Appeals', icon: Icons.message_outlined, route: '/driver/appeals'),
    MobileNavItem(label: 'Profile', icon: Icons.person_outline, route: '/driver/profile'),
  ];

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();

  Future<void> _openEditDialog(UserModel user) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditDriverProfileDialog(user: user),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUid ?? '';

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: _db.userStream(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = snap.data;
                if (user == null) {
                  return const Center(
                    child: Text('Unable to load profile', style: TextStyle(color: TomsColors.mutedForeground)),
                  );
                }

                final initials = user.name
                    .split(' ')
                    .where((part) => part.isNotEmpty)
                    .take(2)
                    .map((part) => part[0])
                    .join()
                    .toUpperCase();

                final menuItems = [
                  {
                    'icon': Icons.person,
                    'label': 'Personal Information',
                    'desc': 'Name, email, phone, license',
                    'onTap': () => _openEditDialog(user),
                  },
                  {
                    'icon': Icons.badge_outlined,
                    'label': 'License Details',
                    'desc': '${user.licenseNumber.isEmpty ? 'Not set' : user.licenseNumber} • ${user.licenseStatus.toUpperCase()}',
                    'onTap': () => _openEditDialog(user),
                  },
                  {
                    'icon': Icons.mail_outline,
                    'label': 'Email Address',
                    'desc': user.email,
                    'onTap': () => _openEditDialog(user),
                  },
                  {
                    'icon': Icons.phone_outlined,
                    'label': 'Phone Number',
                    'desc': user.phone.isEmpty ? 'Add your contact number' : user.phone,
                    'onTap': () => _openEditDialog(user),
                  },
                ];

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(gradient: TomsColors.driverGradient),
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 48),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.arrow_back, size: 16, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                          ]),
                          const SizedBox(height: 24),
                          Row(children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(24)),
                              child: Center(child: Text(initials.isEmpty ? 'DR' : initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white))),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                                Text(user.nationalId, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.email_outlined, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                          child: Text(
                                      _driverEmailUsername(user.email),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.badge_outlined, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.licenseNumber.isEmpty ? 'License not set' : user.licenseNumber,
                                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                                  ),
                                ]),
                              ]),
                            ),
                          ]),
                        ]),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              GlassCard(
                                elevated: true,
                                child: Column(
                                  children: menuItems.map((mi) {
                                    final isLast = mi == menuItems.last;
                                    return Column(children: [
                                      GestureDetector(
                                        onTap: mi['onTap'] as void Function()?,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(color: TomsColors.secondary, borderRadius: BorderRadius.circular(12)),
                                              child: Icon(mi['icon'] as IconData, size: 20, color: TomsColors.mutedForeground),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                Text(mi['label'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                                Text(mi['desc'] as String, style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
                                              ]),
                                            ),
                                            const Icon(Icons.chevron_right, size: 16, color: TomsColors.mutedForeground),
                                          ]),
                                        ),
                                      ),
                                      if (!isLast) Divider(height: 1, color: TomsColors.border.withValues(alpha: 0.5)),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await _auth.signOut();
                                    if (context.mounted) context.push('/');
                                  },
                                  icon: const Icon(Icons.logout, size: 16, color: TomsColors.destructive),
                                  label: const Text('Sign Out', style: TextStyle(color: TomsColors.destructive)),
                                  style: OutlinedButton.styleFrom(side: BorderSide(color: TomsColors.destructive.withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('TOMS v1.0.0 • © 2026 National Traffic Authority', style: TextStyle(fontSize: 10, color: TomsColors.mutedForeground)),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          MobileNav(items: DriverProfileScreen._navItems, currentRoute: '/driver/profile', onNavigate: (r) => context.push(r)),
        ],
      ),
    );
  }

  String _driverEmailUsername(String email) {
    const suffix = '@driver.toms.com';
    final normalized = email.trim().toLowerCase();
    return normalized.endsWith(suffix) ? normalized.replaceFirst(suffix, '') : email;
  }
}

class _EditDriverProfileDialog extends StatefulWidget {
  final UserModel user;

  const _EditDriverProfileDialog({required this.user});

  @override
  State<_EditDriverProfileDialog> createState() => _EditDriverProfileDialogState();
}

class _EditDriverProfileDialogState extends State<_EditDriverProfileDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _nationalIdCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _licenseCtrl;
  late final TextEditingController _emailCtrl;
  final _auth = AuthService();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _nationalIdCtrl = TextEditingController(text: widget.user.nationalId);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _licenseCtrl = TextEditingController(text: widget.user.licenseNumber);
    _emailCtrl = TextEditingController(text: _driverEmailUsername(widget.user.email));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nationalIdCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _nationalIdCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Name, National ID, and email username are required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _auth.updateDriverProfile(
        uid: widget.user.uid,
        name: _nameCtrl.text,
        nationalId: _nationalIdCtrl.text,
        phone: _phoneCtrl.text,
        licenseNumber: _licenseCtrl.text,
        email: _emailCtrl.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _saving = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: TomsColors.destructive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!, style: const TextStyle(fontSize: 12, color: TomsColors.destructive)),
                ),
                const SizedBox(height: 12),
              ],
              TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(labelText: 'Email Username', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('@driver.toms.com', style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _nationalIdCtrl, decoration: InputDecoration(labelText: 'National ID', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _licenseCtrl, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: 'License Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: TomsColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _driverEmailUsername(String email) {
    const suffix = '@driver.toms.com';
    final normalized = email.trim().toLowerCase();
    return normalized.endsWith(suffix) ? normalized.replaceFirst(suffix, '') : email;
  }
}
