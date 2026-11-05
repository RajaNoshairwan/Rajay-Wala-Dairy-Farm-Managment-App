import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/user_model.dart';
import '../../../viewmodels/admin_billing_viewmodel.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});
  @override
  State<AdminPaymentScreen> createState() => _State();
}

class _State extends State<AdminPaymentScreen> {
  final _search = TextEditingController();
  final _amount = TextEditingController();
  List<UserModel> _customers = [];
  UserModel? _selected;
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').get();
      setState(() {
        _customers = snap.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList();
        if (_selected != null) {
          _selected = _customers.firstWhere((c) => c.uid == _selected!.uid, orElse: () => _selected!);
        }
      });
    } catch (e) { debugPrint('Load: $e'); }
  }

  List<UserModel> get _filtered => _customers.where((c) {
    if (_search.text.isEmpty) return true;
    final q = _search.text.toLowerCase();
    return c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q);
  }).toList();

  Future<void> _record() async {
    if (_selected == null) return;
    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    final adminUid = context.read<AuthViewModel>().user?.uid ?? '';
    final ok = await context.read<AdminBillingViewModel>().recordPayment(
      customerId: _selected!.uid, amount: amount, adminUid: adminUid,
    );
    setState(() => _saving = false);
    if (!mounted) return;
    if (ok) {
      await _load();
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
          title: const Text('Payment Recorded'),
          content: Text('Rs. ${amount.toStringAsFixed(0)} recorded for ${_selected!.name}.\nNew outstanding: ${CurrencyFormatter.format(_selected!.outstandingBalance)}'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      _amount.clear();
      setState(() => _selected = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<AdminBillingViewModel>().message ?? 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Record Cash Payment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      if (_selected != null) ...[
        Card(
          color: AppColors.primary.withValues(alpha: 0.1),
          child: ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: Text(_selected!.name),
            subtitle: Text('Outstanding: ${CurrencyFormatter.format(_selected!.outstandingBalance)}'),
            trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selected = null)),
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(controller: _amount, label: 'Amount (Rs)', keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        CustomButton(label: 'Record Payment', loading: _saving, onPressed: _record),
      ] else ...[
        CustomTextField(controller: _search, label: 'Search customer', prefixIcon: Icons.search),
        const SizedBox(height: 12),
        ..._filtered.map((c) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
            title: Text(c.name),
            subtitle: Text('${c.phone} · Owed: ${CurrencyFormatter.format(c.outstandingBalance)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _selected = c),
          ),
        )),
      ],
    ]);
  }
}