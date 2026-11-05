import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_record_model.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../models/ledger_entry_model.dart';

class BillingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Recompute outstanding = total delivery amounts - total payments.
  /// Works even before any invoice is generated.
  Future<double> recomputeOutstanding(String customerId) async {
    final records = await _db.collection('delivery_records').where('customerId', isEqualTo: customerId).get();
    final payments = await _db.collection('payments').where('customerId', isEqualTo: customerId).get();

    double owed = 0, paid = 0;
    for (final d in records.docs) {
      owed += ((d.data()['amount'] ?? 0) as num).toDouble();
    }
    for (final d in payments.docs) {
      paid += ((d.data()['amount'] ?? 0) as num).toDouble();
    }
    final outstanding = owed - paid;
    await _db.collection('users').doc(customerId).update({'outstandingBalance': outstanding});
    return outstanding;
  }

  Future<InvoiceModel> generateMonthlyInvoice({
    required String customerId,
    required int month,
    required int year,
  }) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final recordsSnap = await _db.collection('delivery_records').where('customerId', isEqualTo: customerId).get();
    double totalMilkAmount = 0;
    for (final doc in recordsSnap.docs) {
      final r = DeliveryRecordModel.fromMap(doc.id, doc.data());
      if (!r.date.isBefore(startOfMonth) && r.date.isBefore(endOfMonth)) {
        totalMilkAmount += r.amount;
      }
    }

    double openingBalance = 0;
    final prevInvoiceSnap = await _db
        .collection('invoices')
        .where('customerId', isEqualTo: customerId)
        .where('year', isEqualTo: month == 1 ? year - 1 : year)
        .where('month', isEqualTo: month == 1 ? 12 : month - 1)
        .limit(1)
        .get();
    if (prevInvoiceSnap.docs.isNotEmpty) {
      openingBalance = ((prevInvoiceSnap.docs.first.data()['closingBalance'] ?? 0) as num).toDouble();
    }

    final paymentsSnap = await _db.collection('payments').where('customerId', isEqualTo: customerId).get();
    double paymentsReceived = 0;
    for (final doc in paymentsSnap.docs) {
      final p = PaymentModel.fromMap(doc.id, doc.data());
      if (!p.paymentDate.isBefore(startOfMonth) && p.paymentDate.isBefore(endOfMonth)) {
        paymentsReceived += p.amount;
      }
    }

    final closingBalance = openingBalance + totalMilkAmount - paymentsReceived;
    final invoiceId = 'INV-$year-$month-$customerId';
    final invoice = InvoiceModel(
      invoiceId: invoiceId,
      customerId: customerId,
      month: month,
      year: year,
      openingBalance: openingBalance,
      totalMilkAmount: totalMilkAmount,
      paymentsReceived: paymentsReceived,
      closingBalance: closingBalance,
      status: closingBalance <= 0 ? 'paid' : (paymentsReceived > 0 ? 'partiallyPaid' : 'unpaid'),
      dueDate: DateTime(year, month + 1, 10),
      generatedAt: DateTime.now(),
    );
    await _db.collection('invoices').doc(invoiceId).set(invoice.toMap());

    await _addLedgerEntry(customerId: customerId, description: 'Milk delivered (${totalMilkAmount.toStringAsFixed(0)} amount)', debit: totalMilkAmount);
    if (openingBalance > 0) {
      await _addLedgerEntry(customerId: customerId, description: 'Previous balance', debit: openingBalance);
    }
    if (paymentsReceived > 0) {
      await _addLedgerEntry(customerId: customerId, description: 'Payment received', credit: paymentsReceived);
    }

    await recomputeOutstanding(customerId);
    return invoice;
  }

  Future<void> _addLedgerEntry({
    required String customerId,
    required String description,
    double debit = 0,
    double credit = 0,
  }) async {
    final last = await _db.collection('ledger_entries').where('customerId', isEqualTo: customerId).get();
    double lastBalance = 0;
    for (final d in last.docs) {
      final bal = ((d.data()['balance'] ?? 0) as num).toDouble();
      if (bal > lastBalance || lastBalance == 0) {
        lastBalance = bal;
      }
    }
    final entry = LedgerEntryModel(
      entryId: '',
      customerId: customerId,
      date: DateTime.now(),
      description: description,
      debit: debit,
      credit: credit,
      balance: lastBalance + debit - credit,
    );
    await _db.collection('ledger_entries').add(entry.toMap());
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String? invoiceId,
    required String adminUid,
    String note = '',
  }) async {
    final payment = PaymentModel(
      paymentId: '',
      customerId: customerId,
      invoiceId: invoiceId,
      amount: amount,
      paymentDate: DateTime.now(),
      method: 'cash',
      recordedBy: adminUid,
      note: note,
    );
    await _db.collection('payments').add(payment.toMap());

    if (invoiceId != null) {
      final invRef = _db.collection('invoices').doc(invoiceId);
      final invDoc = await invRef.get();
      if (invDoc.exists) {
        final inv = InvoiceModel.fromMap(invoiceId, invDoc.data()!);
        final newPayments = inv.paymentsReceived + amount;
        final newClosing = inv.openingBalance + inv.totalMilkAmount - newPayments;
        await invRef.update({
          'paymentsReceived': newPayments,
          'closingBalance': newClosing,
          'status': newClosing <= 0 ? 'paid' : 'partiallyPaid',
        });
      }
    }

    await _addLedgerEntry(customerId: customerId, description: 'Cash payment', credit: amount);
    await recomputeOutstanding(customerId);
  }
}