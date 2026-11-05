import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../services/notification_service.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState
    extends State<AdminNotificationScreen> {
  final _service = NotificationService();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;
  String? _message;

  static const _templates = {
    'Milk arriving': 'Your milk is arriving. Please open the door! 🥛',
    'Order accepted': 'Your order has been accepted.',
    'Delivered': 'Your milk has been delivered ✅',
    'Bill generated': 'Your monthly bill has been generated.',
    'Payment overdue': 'Your payment is overdue. Please pay soon.',
    'Subscription expiring':
    'Your subscription is about to expire. Renew now.',
  };

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    await _service.sendToAllCustomers(
      title: _title.text.trim(),
      body: _body.text.trim(),
    );
    setState(() {
      _sending = false;
      _message = 'Notification sent to all customers ✅';
      _title.clear();
      _body.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Send Notification',
            style:
            TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: _templates.entries
              .map((e) => ActionChip(
            label: Text(e.key),
            onPressed: () {
              _title.text = e.key;
              _body.text = e.value;
              setState(() {});
            },
          ))
              .toList(),
        ),
        const SizedBox(height: 16),
        CustomTextField(controller: _title, label: 'Title'),
        const SizedBox(height: 12),
        CustomTextField(
            controller: _body, label: 'Message', maxLines: 3),
        const SizedBox(height: 16),
        CustomButton(
          label: 'Send to All Customers',
          icon: Icons.send,
          loading: _sending,
          onPressed: _send,
        ),
        if (_message != null) ...[
          const SizedBox(height: 12),
          Text(_message!,
              style: const TextStyle(color: AppColors.success)),
        ],
      ],
    );
  }
}