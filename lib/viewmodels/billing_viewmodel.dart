import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/user_model.dart';
import '../services/pdf_service.dart';

class BillingViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PdfService _pdfService = PdfService();
  List<InvoiceModel> _invoices = [];
  List<PaymentModel> _payments = [];
  List<LedgerEntryModel> _ledger = [];
  bool _loading = false;

  List<InvoiceModel> get invoices => _invoices;
  List<PaymentModel> get payments => _payments;
  List<LedgerEntryModel> get ledger => _ledger;
  bool get loading => _loading;
  double get totalOutstanding => _invoices.isNotEmpty ? _invoices.first.closingBalance : 0;

  Future<void> loadCustomerBilling(String customerId) async {
    _loading = true;
    notifyListeners();
    try {
      final invSnap = await _db.collection('invoices').where('customerId', isEqualTo: customerId).get();
      _invoices = invSnap.docs.map((d) => InvoiceModel.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

      final paySnap = await _db.collection('payments').where('customerId', isEqualTo: customerId).get();
      _payments = paySnap.docs.map((d) => PaymentModel.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

      final ledSnap = await _db.collection('ledger_entries').where('customerId', isEqualTo: customerId).get();
      _ledger = ledSnap.docs.map((d) => LedgerEntryModel.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Billing load error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> downloadInvoice(InvoiceModel invoice) async {
    try {
      final userDoc = await _db.collection('users').doc(invoice.customerId).get();
      if (!userDoc.exists) return;
      final customer = UserModel.fromMap(invoice.customerId, userDoc.data()!);
      final file = await _pdfService.generateInvoicePdf(invoice: invoice, customer: customer);
      await _pdfService.previewPdf(file);
    } catch (e) {
      debugPrint('PDF error: $e');
    }
  }
}