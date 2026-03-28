import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';

class PoliceLoginScreen extends StatefulWidget {
  const PoliceLoginScreen({super.key});
  @override
  State<PoliceLoginScreen> createState() => _PoliceLoginScreenState();
}

class _PoliceLoginScreenState extends State<PoliceLoginScreen> {
  final _badgeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _badgeCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _signIn() async {
    final badgeId = _badgeCtrl.text.trim();
    final pass = _passCtrl.text;
    if (badgeId.isEmpty || pass.isEmpty) { setState(() => _error = 'Please fill in all fields'); return; }

    setState(() { _loading = true; _error = null; });
    try {
      final auth = AuthService();
      final user = await auth.signInPolice(badgeId, pass);
      if (!mounted) return;
      if (user == null) { setState(() { _loading = false; _error = 'Account not found'; }); return; }
      if (!user.isPolice) { setState(() { _loading = false; _error = 'Access denied. Police accounts only.'; }); await auth.signOut(); return; }
      context.go('/police/dashboard');
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      if (msg.contains('Exception: ')) msg = msg.replaceAll('Exception: ', '');
      if (msg.contains('too-many-requests')) msg = 'Too many attempts. Try again later.';
      setState(() { _loading = false; _error = msg; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: TomsColors.policeGradient)),
        Positioned.fill(child: Opacity(opacity: 0.03, child: CustomPaint(painter: _CrossPatternPainter()))),
        SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2))), child: const Icon(Icons.shield_outlined, size: 40, color: Colors.white)),
              Positioned(bottom: -4, right: -4, child: Container(width: 28, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, color: TomsColors.success, border: Border.all(color: TomsColors.primary, width: 2)), child: const Icon(Icons.verified, size: 16, color: Colors.white))),
            ]),
            const SizedBox(height: 24),
            const Text('Officer Portal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Traffic Offence Management System', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock, size: 12, color: Colors.white.withValues(alpha: 0.6)), const SizedBox(width: 6), Text('Secure Government Access', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6)))]),
            ),
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
                _inputField('Badge ID', 'e.g. P123456', controller: _badgeCtrl),
                const SizedBox(height: 16),
                _inputField('Password', 'Enter password', isPassword: true, controller: _passCtrl),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4, shadowColor: TomsColors.primary.withValues(alpha: 0.3)),
                  child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                )),
                const SizedBox(height: 16),
                Text('Forgot password? Contact your department administrator.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: TomsColors.mutedForeground)),
              ]),
            ),
            const SizedBox(height: 24),
            Text('Authorized personnel only. All activity is monitored and logged.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          ])),
        ))),
      ]),
    );
  }

  Widget _inputField(String label, String hint, {bool isPassword = false, TextEditingController? controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: TomsColors.foreground)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: isPassword && !_showPass,
        style: const TextStyle(fontSize: 15),
        onSubmitted: (_) => _signIn(),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          fillColor: TomsColors.secondary.withValues(alpha: 0.6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TomsColors.border.withValues(alpha: 0.5))),
          suffixIcon: isPassword ? IconButton(icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, size: 18, color: TomsColors.mutedForeground), onPressed: () => setState(() => _showPass = !_showPass)) : null,
        ),
      ),
    ]);
  }
}

class _CrossPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 60) { for (double y = 0; y < size.height; y += 60) { canvas.drawLine(Offset(x + 26, y + 30), Offset(x + 34, y + 30), paint); canvas.drawLine(Offset(x + 30, y + 26), Offset(x + 30, y + 34), paint); } }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
