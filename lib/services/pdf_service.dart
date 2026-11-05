import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../models/invoice_model.dart';
import '../models/user_model.dart';

class PdfService {
  Future<File> generateInvoicePdf({
    required InvoiceModel invoice,
    required UserModel customer,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Milk Delivery Invoice',
                    style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Customer: ${customer.name}'),
              pw.Text('Phone: ${customer.phone}'),
              pw.Text('Address: ${customer.address.fullAddress}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Billing Period: ${invoice.month}/${invoice.year}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Description', 'Amount (Rs.)'],
                data: [
                  [
                    'Milk delivered',
                    invoice.totalMilkAmount.toStringAsFixed(2)
                  ],
                  [
                    'Previous balance',
                    invoice.openingBalance.toStringAsFixed(2)
                  ],
                  [
                    'Payment received',
                    '-${invoice.paymentsReceived.toStringAsFixed(2)}'
                  ],
                  [
                    'Remaining balance',
                    invoice.closingBalance.toStringAsFixed(2)
                  ],
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Status: ${invoice.status.toUpperCase()}'),
              pw.Text(
                  'Due Date: ${invoice.dueDate.toString().split(' ')[0]}'),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file =
    File('${output.path}/invoice_${invoice.invoiceId}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> previewPdf(File file) async {
    await Printing.layoutPdf(
      onLayout: (format) => file.readAsBytes(),
    );
  }
}