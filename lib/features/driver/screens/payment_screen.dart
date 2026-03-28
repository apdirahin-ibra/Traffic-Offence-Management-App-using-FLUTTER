import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/waafipay_service.dart';
import '../../../models/fine_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/mobile_nav.dart';

class PaymentScreen extends StatefulWidget {
  final String? fineId;

  const PaymentScreen({super.key, this.fineId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _db = FirestoreService();
  final _auth = AuthService();
  final _waafiPay = WaafiPayService();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  bool _paid = false;
  bool _processing = false;
  List<FineModel> _unpaidFines = [];
  double _totalOwed = 0;
  String? _txnId;
  String _selectedWallet = 'evc_plus';
  String? _paidWith;
  String? _paidPhone;

  static const _navItems = [
    MobileNavItem(label: 'Home', icon: Icons.dashboard_outlined, route: '/driver/dashboard'),
    MobileNavItem(label: 'Vehicles', icon: Icons.directions_car, route: '/driver/vehicles'),
    MobileNavItem(label: 'Fines', icon: Icons.list_alt, route: '/driver/fines'),
    MobileNavItem(label: 'Appeals', icon: Icons.message_outlined, route: '/driver/appeals'),
    MobileNavItem(label: 'Profile', icon: Icons.person_outline, route: '/driver/profile'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnpaidFines();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUnpaidFines() async {
    final uid = _auth.currentUid ?? '';
    final fines = await _db.getRecentFines(limit: 100);
    final mine = fines.where((f) => f.driverId == uid && (f.isPending || f.isOverdue)).toList();
    final targetFineId = widget.fineId?.trim();
    final payable = (targetFineId != null && targetFineId.isNotEmpty)
        ? mine.where((fine) => fine.id == targetFineId).toList()
        : mine;

    if (mounted) {
      setState(() {
        _unpaidFines = payable;
        _totalOwed = payable.fold<double>(0, (s, f) => s + f.amount);
      });
    }
  }

  Future<void> _processPayment() async {
    if (_processing || _unpaidFines.isEmpty) return;

    setState(() => _processing = true);
    try {
      final result = await _waafiPay.processPayment(
        WaafiPayRequest(
          wallet: _selectedWallet,
          phoneNumber: _phoneCtrl.text.trim(),
          reference: 'traffic-fines',
          amount: _totalOwed,
          pin: _pinCtrl.text.trim(),
        ),
      );

      for (final fine in _unpaidFines) {
        await _db.updateFineStatus(fine.id, 'paid', paidAt: DateTime.now());
      }

      await _db.logAction(
        _auth.currentUid ?? '',
        'payment',
        'Paid \$${_totalOwed.toStringAsFixed(0)} for ${_unpaidFines.length} fines via ${result.providerLabel}',
      );

      if (mounted) {
        setState(() {
          _paid = true;
          _processing = false;
          _txnId = result.transactionId;
          _paidWith = result.providerLabel;
          _paidPhone = result.maskedPhone;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paid) return _successScreen(context);

    return Scaffold(
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              Container(
                decoration: const BoxDecoration(gradient: TomsColors.driverGradient),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, left: 20, right: 20, bottom: 32),
                child: Row(children: [
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('WaafiPay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Pay fines using your mobile wallet', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ]),
              ),
              Transform.translate(
                offset: const Offset(0, -16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(children: [
                    GlassCard(
                      elevated: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.fineId != null && widget.fineId!.isNotEmpty
                                      ? 'Selected fine payment'
                                      : '${_unpaidFines.length} unpaid fine${_unpaidFines.length != 1 ? 's' : ''}',
                                  style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.fineId != null && widget.fineId!.isNotEmpty ? 'Fine Amount' : 'Outstanding Balance',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text('\$${_totalOwed.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: TomsColors.accent)),
                          ],
                        ),
                        if (_unpaidFines.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          ..._unpaidFines.take(5).map((f) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(f.offenceType, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                    Text('\$${f.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      elevated: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Wallet Provider'),
                          const SizedBox(height: 16),
                          _walletOption(
                            value: 'evc_plus',
                            title: 'EVC Plus',
                            subtitle: 'Hormuud mobile wallet',
                            color: TomsColors.success,
                            icon: Icons.sim_card_outlined,
                          ),
                          const SizedBox(height: 12),
                          _walletOption(
                            value: 'sahal',
                            title: 'Sahal',
                            subtitle: 'Somtel mobile wallet',
                            color: TomsColors.primary,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(height: 12),
                          _walletOption(
                            value: 'zaad',
                            title: 'Zaad',
                            subtitle: 'Telesom mobile wallet',
                            color: TomsColors.accent,
                            icon: Icons.phone_android_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      elevated: true,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Wallet Details'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Mobile number e.g. 0612345678',
                              prefixIcon: Icon(Icons.phone_outlined, size: 18),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pinCtrl,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              hintText: '4-digit wallet PIN',
                              counterText: '',
                              prefixIcon: Icon(Icons.lock_outline, size: 18),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TomsColors.success.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: TomsColors.success.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.verified_user_outlined, size: 16, color: TomsColors.success),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'WaafiPay simulation will validate your wallet choice, Somali mobile number, and 4-digit PIN before confirming payment.',
                                    style: const TextStyle(fontSize: 11, color: TomsColors.success),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_unpaidFines.isNotEmpty && !_processing) ? _processPayment : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TomsColors.success,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: TomsColors.success.withValues(alpha: 0.3),
                        ),
                        child: _processing
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                  SizedBox(width: 12),
                                  Text('Processing WaafiPay...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              )
                            : Text(
                                'Pay with ${_waafiPay.providerLabel(_selectedWallet)} - \$${_totalOwed.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        MobileNav(items: _navItems, currentRoute: '/driver/fines', onNavigate: (r) => context.push(r)),
      ]),
    );
  }

  Widget _walletOption({
    required String value,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final selected = _selectedWallet == value;
    return InkWell(
      onTap: () => setState(() => _selectedWallet = value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.09) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : TomsColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedWallet,
              activeColor: color,
              onChanged: (selectedValue) {
                if (selectedValue == null) return;
                setState(() => _selectedWallet = selectedValue);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _successScreen(BuildContext context) {
    return Scaffold(
      body: Column(children: [
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
                  const Text('Payment Successful', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('\$${_totalOwed.toStringAsFixed(2)} paid via ${_paidWith ?? 'WaafiPay'}', style: const TextStyle(fontSize: 15, color: TomsColors.mutedForeground)),
                  const SizedBox(height: 24),
                  GlassCard(
                    elevated: true,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _row('Transaction ID', _txnId ?? ''),
                        const Divider(),
                        _row('Provider', _paidWith ?? 'WaafiPay'),
                        const Divider(),
                        _row('Wallet', _paidPhone ?? ''),
                        const Divider(),
                        _row('Fines Paid', '${_unpaidFines.length}'),
                        const Divider(),
                        _row('Total Paid', '\$${_totalOwed.toStringAsFixed(2)}'),
                        const Divider(),
                        _row('Status', 'Confirmed'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/driver/dashboard'),
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Back to Dashboard'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        MobileNav(items: _navItems, currentRoute: '/driver/fines', onNavigate: (r) => context.push(r)),
      ]),
    );
  }

  Widget _label(String t) => Text(
        t.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TomsColors.mutedForeground, letterSpacing: 1.5),
      );

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: const TextStyle(fontSize: 13, color: TomsColors.mutedForeground)),
            Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
