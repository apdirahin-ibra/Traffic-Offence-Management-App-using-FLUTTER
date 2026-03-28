import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../models/user_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../widgets/glass_card.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _auth = AuthService();
  final _db = FirestoreService();
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Create, update, deactivate, and restore Police, Driver, and Administrator accounts.', style: TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openCreateDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New User'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip('All', 'all'),
                  _filterChip('Drivers', 'driver'),
                  _filterChip('Police', 'police'),
                  _filterChip('Admins', 'admin'),
                  _filterChip('Suspended', 'suspended'),
                  _filterChip('Active', 'active'),
                  _filterChip('Inactive', 'inactive'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlassCard(
            elevated: true,
            padding: const EdgeInsets.all(20),
            child: StreamBuilder<List<VehicleModel>>(
              stream: _db.allVehiclesStream(),
              builder: (context, snap) {
                final vehicles = snap.data ?? const <VehicleModel>[];

                return StreamBuilder<List<UserModel>>(
                  stream: _db.allUsersStream(),
                  builder: (context, userSnap) {
                    if (userSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                    }
                    if (userSnap.hasError) {
                      return _emptyState('Unable to load users', '${userSnap.error}');
                    }

                    final allUsers = (userSnap.data ?? []).where((user) => user.isAdmin || user.isPolice || user.isDriver).toList()
                      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                    final users = _applyFilter(allUsers);

                    if (users.isEmpty) {
                      return _emptyState('No users found', 'No Driver, Police, or Administrator accounts match the current filter.');
                    }

                    return Column(
                      children: [
                        _tableHeader(),
                        const SizedBox(height: 8),
                        ...users.map((user) => _userRow(context, user, vehicles.where((v) => v.ownerId == user.uid).toList())),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<UserModel> _applyFilter(List<UserModel> users) {
    switch (_roleFilter) {
      case 'driver':
        return users.where((u) => u.isDriver).toList();
      case 'police':
        return users.where((u) => u.isPolice).toList();
      case 'admin':
        return users.where((u) => u.isAdmin).toList();
      case 'suspended':
        return users.where((u) => u.isDriver && u.isSuspended).toList();
      case 'active':
        return users.where((u) => u.isActive).toList();
      case 'inactive':
        return users.where((u) => !u.isActive).toList();
      default:
        return users;
    }
  }

  Widget _filterChip(String label, String value) {
    final active = _roleFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => setState(() => _roleFilter = value),
      selectedColor: TomsColors.primary.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: active ? TomsColors.primary : TomsColors.mutedForeground,
      ),
      side: BorderSide(color: active ? TomsColors.primary.withValues(alpha: 0.25) : TomsColors.border),
      backgroundColor: Colors.white,
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TomsColors.secondary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          Expanded(flex: 2, child: Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          Expanded(flex: 2, child: Text('Identifier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _userRow(BuildContext context, UserModel user, List<VehicleModel> vehicles) {
    final identifier = user.isPolice
        ? (user.badgeId ?? '-')
        : user.isDriver
            ? (user.licenseNumber.isEmpty ? '-' : user.licenseNumber)
            : user.email;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TomsColors.border.withValues(alpha: 0.9)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        user.isDriver ? '${user.email} • ${user.nationalId}' : user.email,
                        style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    user.isPolice ? 'Police Officer' : user.isDriver ? 'Driver' : 'Administrator',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: user.isActive ? TomsColors.success : TomsColors.destructive,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        !user.isActive
                            ? 'Inactive'
                            : user.isDriver && user.isSuspended
                                ? 'Suspended'
                                : 'Active',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(identifier, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                ),
                SizedBox(
                  width: 120,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _openEditDialog(context, user),
                        child: const Text('Edit'),
                      ),
                      TextButton(
                        onPressed: () => _clearLoginLock(context, user),
                        style: TextButton.styleFrom(foregroundColor: TomsColors.primary),
                        child: const Text('Clear Lock'),
                      ),
                      if (user.isDriver && !user.isSuspended)
                        TextButton(
                          onPressed: () => _suspendDriverLicense(context, user),
                          style: TextButton.styleFrom(foregroundColor: TomsColors.accent),
                          child: const Text('Suspend'),
                        ),
                      if (user.isDriver && user.isSuspended)
                        TextButton(
                          onPressed: () => _restoreDriverLicense(context, user),
                          style: TextButton.styleFrom(foregroundColor: TomsColors.success),
                          child: const Text('Restore'),
                        ),
                      TextButton(
                        onPressed: () => _confirmDelete(context, user),
                        style: TextButton.styleFrom(foregroundColor: TomsColors.destructive),
                        child: const Text('Deactivate'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (user.isDriver) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vehicles.isEmpty
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: TomsColors.secondary.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'No vehicles registered',
                              style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                            ),
                          ),
                        ]
                      : vehicles.map((vehicle) {
                          final subtitle = [
                            if (vehicle.make.isNotEmpty) vehicle.make,
                            if (vehicle.model.isNotEmpty) vehicle.model,
                            if (vehicle.color.isNotEmpty) vehicle.color,
                          ].join(' • ');
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: TomsColors.secondary.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: TomsColors.border.withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  vehicle.plateNumber,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String title, String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 42, color: TomsColors.mutedForeground),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(message, style: const TextStyle(fontSize: 12, color: TomsColors.mutedForeground), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AdminUserDialog(
        title: 'Create User',
        confirmLabel: 'Create',
        onSubmit: (payload) async {
          final created = await _auth.adminCreateUser(
            role: payload.role,
            name: payload.name,
            password: payload.password!,
            nationalId: payload.nationalId,
            badgeId: payload.badgeId,
            email: payload.email.isEmpty ? null : payload.email,
            phone: payload.phone,
            licenseNumber: payload.licenseNumber,
          );
          if (created == null) throw 'User could not be created.';
          await _db.logAction(
            _auth.currentUid ?? '',
            'admin_create_user',
            'Created ${payload.role} account for ${payload.name}',
          );
        },
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, UserModel user) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AdminUserDialog(
        title: 'Edit User',
        confirmLabel: 'Save Changes',
        initialUser: user,
        onSubmit: (payload) async {
          final updated = user.copyWith(
            name: payload.name,
            email: payload.role == 'driver' ? payload.email : user.email,
            phone: payload.phone,
            licenseNumber: payload.licenseNumber ?? user.licenseNumber,
            isActive: payload.isActive,
            licenseStatus: payload.isSuspended ? 'suspended' : 'active',
          );
          final patched = UserModel(
            uid: updated.uid,
            name: updated.name,
            email: updated.email,
            nationalId: payload.nationalId ?? updated.nationalId,
            badgeId: payload.role == 'police' ? payload.badgeId : null,
            role: payload.role,
            phone: updated.phone,
            licenseNumber: updated.licenseNumber,
            isActive: updated.isActive,
            demeritPoints: updated.demeritPoints,
            licenseStatus: updated.licenseStatus,
            createdAt: updated.createdAt,
          );
          await _db.adminUpdateManagedUser(patched);
          await _db.logAction(
            _auth.currentUid ?? '',
            'admin_update_user',
            'Updated ${patched.role} account for ${patched.name}',
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, UserModel user) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
          'Deactivate ${user.name}? This will block the account from signing in while preserving audit history.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: TomsColors.destructive),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await _auth.adminDeleteManagedUser(user.uid);
      await _db.logAction(
        _auth.currentUid ?? '',
        'admin_delete_user',
        'Deactivated ${user.role} account for ${user.name}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} was deactivated and can no longer sign in.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deactivate failed: $e')),
        );
      }
    }
  }

  Future<void> _restoreDriverLicense(BuildContext context, UserModel user) async {
    try {
      await _db.adminRestoreDriverLicense(user.uid);
      await _db.logAction(
        _auth.currentUid ?? '',
        'admin_restore_driver_license',
        'Restored driver license for ${user.name}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} license restored successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  Future<void> _suspendDriverLicense(BuildContext context, UserModel user) async {
    try {
      await _db.adminSuspendDriverLicense(user.uid);
      await _db.logAction(
        _auth.currentUid ?? '',
        'admin_suspend_driver_license',
        'Suspended driver license for ${user.name}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} license suspended successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suspend failed: $e')),
        );
      }
    }
  }

  Future<void> _clearLoginLock(BuildContext context, UserModel user) async {
    try {
      await _auth.adminClearUserLoginLock(user);
      await _db.logAction(
        _auth.currentUid ?? '',
        'admin_clear_login_lock',
        'Cleared login lock for ${user.role} account ${user.name}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login lock cleared for ${user.name}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clear lock failed: $e')),
        );
      }
    }
  }
}

class _AdminUserDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final UserModel? initialUser;
  final Future<void> Function(_AdminUserFormPayload payload) onSubmit;

  const _AdminUserDialog({
    required this.title,
    required this.confirmLabel,
    required this.onSubmit,
    this.initialUser,
  });

  @override
  State<_AdminUserDialog> createState() => _AdminUserDialogState();
}

class _AdminUserDialogState extends State<_AdminUserDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _badgeCtrl;
  late final TextEditingController _nationalIdCtrl;
  late final TextEditingController _licenseCtrl;
  final TextEditingController _passwordCtrl = TextEditingController();
  late String _role;
  late bool _isActive;
  late bool _isSuspended;
  bool _saving = false;
  String? _error;

  bool get _isCreate => widget.initialUser == null;

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _badgeCtrl = TextEditingController(text: user?.badgeId ?? '');
    _nationalIdCtrl = TextEditingController(text: user?.nationalId ?? '');
    _licenseCtrl = TextEditingController(text: user?.licenseNumber ?? '');
    _role = user?.role ?? 'police';
    _isActive = user?.isActive ?? true;
    _isSuspended = user?.isSuspended ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _badgeCtrl.dispose();
    _nationalIdCtrl.dispose();
    _licenseCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TomsColors.destructive.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TomsColors.destructive.withValues(alpha: 0.2)),
                  ),
                  child: Text(_error!, style: const TextStyle(fontSize: 12, color: TomsColors.destructive)),
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                onChanged: _isCreate
                    ? (value) {
                        if (value == null) return;
                        setState(() => _role = value);
                      }
                    : null,
                items: const [
                  DropdownMenuItem(value: 'driver', child: Text('Driver')),
                  DropdownMenuItem(value: 'police', child: Text('Police Officer')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              if (_role == 'driver') ...[
                TextField(controller: _nationalIdCtrl, decoration: const InputDecoration(labelText: 'National ID')),
                const SizedBox(height: 12),
              ],
              if (_role != 'police') ...[
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  readOnly: !_isCreate && _role != 'driver',
                  decoration: InputDecoration(
                    labelText: _role == 'driver' ? 'Email Username or Email' : 'Email',
                    helperText: _isCreate
                        ? (_role == 'admin'
                            ? 'Required for administrator login.'
                            : 'Driver email will be saved as username@driver.toms.com.')
                        : (_role == 'driver'
                            ? 'Edit the visible driver profile email username.'
                            : 'Email is locked after account creation.'),
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TomsColors.secondary.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TomsColors.border),
                  ),
                  child: const Text(
                    'Police sign in with badge ID. Internal auth email is created automatically.',
                    style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              if (_role == 'driver') ...[
                const SizedBox(height: 12),
                TextField(controller: _licenseCtrl, decoration: const InputDecoration(labelText: 'License Number')),
              ],
              if (_role == 'police') ...[
                const SizedBox(height: 12),
                TextField(controller: _badgeCtrl, decoration: const InputDecoration(labelText: 'Badge ID')),
              ],
              if (_isCreate) ...[
                const SizedBox(height: 12),
                TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Temporary Password')),
              ],
              if (!_isCreate) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Account'),
                  subtitle: const Text('Inactive users cannot sign in.'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                if (_role == 'driver')
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Suspended License'),
                    subtitle: const Text('Suspended drivers cannot hold an active license.'),
                    value: _isSuspended,
                    onChanged: (value) => setState(() => _isSuspended = value),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.confirmLabel),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final badgeId = _badgeCtrl.text.trim();
    final nationalId = _nationalIdCtrl.text.trim();
    final licenseNumber = _licenseCtrl.text.trim().toUpperCase();
    final password = _passwordCtrl.text;

    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (_role == 'driver' && nationalId.isEmpty) {
      setState(() => _error = 'National ID is required for drivers.');
      return;
    }
    if (_role == 'driver' && licenseNumber.isEmpty) {
      setState(() => _error = 'License number is required for drivers.');
      return;
    }
    if (_role == 'driver' && email.isEmpty) {
      setState(() => _error = 'Email username is required for drivers.');
      return;
    }
    if (_role == 'admin' && email.isEmpty) {
      setState(() => _error = 'Email is required for administrators.');
      return;
    }
    if (_role == 'police' && badgeId.isEmpty) {
      setState(() => _error = 'Badge ID is required for police officers.');
      return;
    }
    if (_isCreate && password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        _AdminUserFormPayload(
          role: _role,
          name: name,
          email: email,
          nationalId: nationalId.isEmpty ? null : nationalId,
          phone: _phoneCtrl.text.trim(),
          licenseNumber: licenseNumber.isEmpty ? null : licenseNumber,
          badgeId: badgeId.isEmpty ? null : badgeId,
          password: _isCreate ? password : null,
          isActive: _isActive,
          isSuspended: _isSuspended,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }
}

class _AdminUserFormPayload {
  final String role;
  final String name;
  final String email;
  final String? nationalId;
  final String phone;
  final String? licenseNumber;
  final String? badgeId;
  final String? password;
  final bool isActive;
  final bool isSuspended;

  const _AdminUserFormPayload({
    required this.role,
    required this.name,
    required this.email,
    required this.nationalId,
    required this.phone,
    required this.licenseNumber,
    required this.badgeId,
    required this.password,
    required this.isActive,
    required this.isSuspended,
  });
}
