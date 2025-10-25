import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate invoice number
  String _generateInvoiceNumber() {
    String year = DateFormat('yyyy').format(DateTime.now());
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'INV-$year-${timestamp.substring(timestamp.length - 6)}';
  }

  // Create invoice
  Future<String> createInvoice({
    required String clientId,
    required String clientName,
    required String clientEmail,
    required String trainerId,
    required List<InvoiceItem> items,
    double taxRate = 0.0,
    int daysUntilDue = 30,
  }) async {
    try {
      double subtotal = items.fold(0, (sum, item) => sum + item.total);
      double tax = subtotal * taxRate;
      double total = subtotal + tax;

      DateTime issueDate = DateTime.now();
      DateTime dueDate = issueDate.add(Duration(days: daysUntilDue));

      InvoiceModel invoice = InvoiceModel(
        id: '',
        invoiceNumber: _generateInvoiceNumber(),
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        trainerId: trainerId,
        issueDate: issueDate,
        dueDate: dueDate,
        items: items,
        subtotal: subtotal,
        tax: tax,
        total: total,
        status: InvoiceStatus.pending,
      );

      DocumentReference docRef =
          await _firestore.collection('invoices').add(invoice.toMap());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create invoice: ${e.toString()}');
    }
  }

  // Get invoices for a client
  Stream<List<InvoiceModel>> getClientInvoices(String clientId) {
    return _firestore
        .collection('invoices')
        .where('clientId', isEqualTo: clientId)
        .orderBy('issueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get invoices for a trainer
  Stream<List<InvoiceModel>> getTrainerInvoices(String trainerId) {
    return _firestore
        .collection('invoices')
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('issueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Mark invoice as paid
  Future<void> markInvoiceAsPaid(
    String invoiceId,
    String paymentMethod,
  ) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'status': InvoiceStatus.paid.name,
        'paidDate': DateTime.now().toIso8601String(),
        'paymentMethod': paymentMethod,
      });
    } catch (e) {
      throw Exception('Failed to mark invoice as paid: ${e.toString()}');
    }
  }

  // Cancel invoice
  Future<void> cancelInvoice(String invoiceId) async {
    try {
      await _firestore.collection('invoices').doc(invoiceId).update({
        'status': InvoiceStatus.cancelled.name,
      });
    } catch (e) {
      throw Exception('Failed to cancel invoice: ${e.toString()}');
    }
  }

  // Check and update overdue invoices
  Future<void> updateOverdueInvoices() async {
    try {
      DateTime now = DateTime.now();
      QuerySnapshot snapshot = await _firestore
          .collection('invoices')
          .where('status', isEqualTo: InvoiceStatus.pending.name)
          .get();

      for (var doc in snapshot.docs) {
        InvoiceModel invoice = InvoiceModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);

        if (now.isAfter(invoice.dueDate)) {
          await _firestore.collection('invoices').doc(doc.id).update({
            'status': InvoiceStatus.overdue.name,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update overdue invoices: ${e.toString()}');
    }
  }

  // Generate PDF invoice
  Future<void> generateInvoicePDF(
    InvoiceModel invoice,
    String trainerName,
    String trainerAddress,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                      pw.Text(
                        'Issue Date: ${DateFormat('MMM dd, yyyy').format(invoice.issueDate)}',
                      ),
                      pw.Text(
                        'Due Date: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}',
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        trainerName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(trainerAddress),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              // Bill to
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(invoice.clientName),
              pw.Text(invoice.clientEmail),
              pw.SizedBox(height: 30),
              // Items table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Quantity',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Unit Price',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // Item rows
                  ...invoice.items.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.description),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.quantity.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('\$${item.unitPrice.toStringAsFixed(2)}'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('\$${item.total.toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: \$${invoice.subtotal.toStringAsFixed(2)}'),
                      pw.Text('Tax: \$${invoice.tax.toStringAsFixed(2)}'),
                      pw.Divider(),
                      pw.Text(
                        'Total: \$${invoice.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Spacer(),
              // Footer
              pw.Divider(),
              pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    // Print or share the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
