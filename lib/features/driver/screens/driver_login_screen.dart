import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});
  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _licenseCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _licenseCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _signIn() async {
    final licenseNumber = _licenseCtrl.text.trim().toUpperCase();
    final pass = _passCtrl.text;
    if (licenseNumber.isEmpty || pass.isEmpty) { setState(() => _error = 'Please fill in all fields'); return; }

    setState(() { _loading = true; _error = null; });
    try {
      final auth = AuthService();
      final user = await auth.signInDriver(licenseNumber, pass);
      if (!mounted) return;
      if (user == null) { setState(() { _loading = false; _error = 'Account not found'; }); return; }
      if (!user.isDriver) { setState(() { _loading = false; _error = 'Access denied. Driver accounts only.'; }); await auth.signOut(); return; }
      context.go('/driver/dashboard');
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      if (msg.contains('Exception: ')) msg = msg.replaceAll('Exception: ', '');
      if (msg.contains('too-many-requests')) msg = 'Too many attempts. Try again later.';
      setState(() { _loading = false; _error = msg; });
    }
  }

  Future<void> _resetPassword() async {
    final licenseNumber = _licenseCtrl.text.trim().toUpperCase();
    if (licenseNumber.isEmpty) {
      setState(() => _error = 'Enter your license number to reset password.');
      return;
    }
    
    setState(() { _loading = true; _error = null; });
    try {
      final auth = AuthService();
      await auth.resetDriverPassword(licenseNumber);
      if (!mounted) return;
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent (if account exists)')));
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _register() async {
    // Navigate to registration dialog
    final result = await showDialog<bool>(context: context, builder: (ctx) => _RegisterDialog());
    if (result == true && mounted) {
      context.go('/driver/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: TomsColors.driverGradient)),
        Positioned.fill(child: Opacity(opacity: 0.03, child: CustomPaint(painter: _LinePatternPainter()))),
        SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2))), child: const Icon(Icons.directions_car, size: 40, color: Colors.white)),
            const SizedBox(height: 24),
            const Text('Driver Portal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Sign in with your license number to manage fines and vehicles', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: TomsColors.card.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(24), border: Border.all(color: TomsColors.border.withValues(alpha: 0.3)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 32, offset: const Offset(0, 8))]),
              child: Column(children: [
                if (_error != null) ...[
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: TomsColors.destructive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: TomsColors.destructive.withValues(alpha: 0.2))),
                    child: Row(children: [const Icon(Icons.error_outline, size: 16, color: TomsColors.destructive), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: TomsColors.destructive)))]),
                  ),
                  const SizedBox(height: 16),
                ],
                _field('License Number', 'e.g. L-001', controller: _licenseCtrl),
                const SizedBox(height: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    GestureDetector(onTap: _resetPassword, child: const Text('Forgot?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: TomsColors.primary))),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    onSubmitted: (_) => _signIn(),
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      fillColor: TomsColors.secondary.withValues(alpha: 0.6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
                      suffixIcon: IconButton(icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, size: 18, color: TomsColors.mutedForeground), onPressed: () => setState(() => _showPass = !_showPass)),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(backgroundColor: TomsColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4, shadowColor: TomsColors.success.withValues(alpha: 0.3)),
                  child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                )),
                const SizedBox(height: 16),
                Row(children: [Expanded(child: Divider(color: TomsColors.border.withValues(alpha: 0.5))), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground))), Expanded(child: Divider(color: TomsColors.border.withValues(alpha: 0.5)))]),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, height: 48, child: OutlinedButton(
                  onPressed: _register,
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Create New Account', style: TextStyle(fontSize: 15)),
                )),
              ]),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock, size: 12, color: Colors.white.withValues(alpha: 0.4)), const SizedBox(width: 6), Text('Your data is encrypted and secure', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)))]),
          ])),
        ))),
      ]),
    );
  }

  Widget _field(String label, String hint, {TextEditingController? controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        onSubmitted: (_) => _signIn(),
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          fillColor: TomsColors.secondary.withValues(alpha: 0.6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
        )
      ),
    ]);
  }
}

class _RegisterDialog extends StatefulWidget {
  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _nameCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailUsernameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _nameCtrl.dispose(); _nidCtrl.dispose(); _phoneCtrl.dispose(); _emailUsernameCtrl.dispose(); _licenseCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final nid = _nidCtrl.text.trim();
    if (_nameCtrl.text.isEmpty || nid.isEmpty || _phoneCtrl.text.trim().isEmpty || _emailUsernameCtrl.text.trim().isEmpty || _licenseCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'All fields are required'); return;
    }
    if (_passCtrl.text.length < 6) { setState(() => _error = 'Password must be at least 6 characters'); return; }

    setState(() { _loading = true; _error = null; });
    try {
      final auth = AuthService();
      await auth.registerDriver(
        nationalId: nid,
        password: _passCtrl.text,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        emailUsername: _emailUsernameCtrl.text.trim(),
        licenseNumber: _licenseCtrl.text.trim().toUpperCase(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('email-already-in-use')) msg = 'This driver account is already registered';
      setState(() { _loading = false; _error = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Create Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: TomsColors.destructive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: const TextStyle(fontSize: 12, color: TomsColors.destructive)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(hintText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: 'National ID (13 digits)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(hintText: 'Phone Number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailUsernameCtrl,
                        decoration: InputDecoration(
                          hintText: 'Email username',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        '@driver.toms.com',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _licenseCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'License Number (used for login, e.g. L-001)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(hintText: 'Password (min 6 chars)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: TomsColors.success, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _LinePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) { canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
