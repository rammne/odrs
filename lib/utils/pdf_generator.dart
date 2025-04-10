import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RequestReceiptGenerator {
  static Future<void> generateReceipt({
    required String requestId,
    required String name,
    required String studentNumber,
    required String contact,
    required Map<String, int> documents,
    required DateTime requestDate,
    required String purpose,
    required String copyType,
    required String referenceNumber,
    required String paymentProvider,
    required double price,
    required String claimingMethod,
    String? requestingSchool,
    bool? principalSignatory,
    bool? guidanceCounselorSignatory
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Document Request Receipt',
                    style: pw.TextStyle(fontSize: 20)),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Request ID: $requestId'),
              pw.Text('Date: ${requestDate.toString().split('.')[0]}'),
              pw.SizedBox(height: 20),
              pw.Text('Student Information:'),
              pw.Text('Name: $name'),
              pw.Text('Student Number: $studentNumber'),
              pw.Text('Contact: $contact'),
              pw.SizedBox(height: 20),
              pw.Text('Requested Documents:'),
              ...documents.entries
                  .map((doc) => pw.Text('- ${doc.key} (${doc.value} copies)')),
              if (principalSignatory != null || guidanceCounselorSignatory != null) ...[                
                pw.SizedBox(height: 20),
                pw.Text('Signatories:'),
                if (principalSignatory == true)
                  pw.Text('- Principal'),
                if (guidanceCounselorSignatory == true)
                  pw.Text('- Guidance Counselor'),
              ],
              pw.SizedBox(height: 20),
              if (requestingSchool != null) ...[
                pw.Text('Requesting School: $requestingSchool'),
                pw.SizedBox(height: 20),
              ],
              pw.Text('Purpose:'),
              pw.Text(purpose),
              pw.SizedBox(height: 20),
              pw.Text('Copy Type: $copyType'),
              pw.SizedBox(height: 20),
              pw.Text('Reference Number: $referenceNumber'),
              pw.SizedBox(height: 20),
              pw.Text('Payment Details:'),
              pw.Text('Provider: $paymentProvider'),
              pw.Text('Total Amount: PHP ${price.toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Text('Claiming Method: $claimingMethod'),
              if (claimingMethod == 'Delivery')
                pw.Text('Note: Requesting party will do the booking and shoulder the shipping fee'),
              if (requestingSchool != null) ...[
                pw.SizedBox(height: 20),
                pw.Text('Note: Present/Submit an official letter from the requesting school upon claiming the document.',
                    style: pw.TextStyle(color: PdfColors.black)),
              ],
              pw.SizedBox(height: 40),
              pw.Text(
                  'Please present a copy (soft copy or hard copy) of this receipt when claiming your documents.'),
              if (documents.containsKey('Report Card'))
                pw.Text('Note: Processing may take 3 working days.')
              else
                pw.Text('Note: Processing may take 14 working days.')
            ],
          );
        },
      ),
    );

    // Display PDF preview and allow printing/saving
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'document_request_$requestId.pdf',
    );
  }

  static Future<void> showReceipt({
    required String requestId,
    required String name,
    required String studentNumber,
    required String contact,
    required Map<String, dynamic> documents,
    required DateTime requestDate,
    required String purpose,
    required String copyType,
    required String referenceNumber,
    required String paymentProvider,
    required double price,
    required String claimingMethod,
    String? requestingSchool,
    bool? principalSignatory,
    bool? guidanceCounselorSignatory,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Document Request Receipt',
                    style: pw.TextStyle(fontSize: 20)),
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Request ID: $requestId'),
              pw.Text('Date: ${requestDate.toString().split('.')[0]}'),
              pw.SizedBox(height: 20),
              pw.Text('Student Information:'),
              pw.Text('Name: $name'),
              pw.Text('Student Number: $studentNumber'),
              pw.Text('Contact: $contact'),
              pw.SizedBox(height: 20),
              pw.Text('Requested Documents:'),
              ...documents.entries
                  .map((doc) => pw.Text('- ${doc.key} (${doc.value} copies)')),
              if (principalSignatory != null || guidanceCounselorSignatory != null) ...[                
                pw.SizedBox(height: 20),
                pw.Text('Signatories:'),
                if (principalSignatory == true)
                  pw.Text('- Principal'),
                if (guidanceCounselorSignatory == true)
                  pw.Text('- Guidance Counselor'),
              ],
              pw.SizedBox(height: 20),
              if (requestingSchool != null) ...[
                pw.Text('Requesting School: $requestingSchool'),
                pw.SizedBox(height: 10),
                pw.Text('Note: Present/Submit an official letter from the requesting school upon claiming the document.',
                    style: pw.TextStyle(color: PdfColors.red)),
                pw.SizedBox(height: 20),
              ],
              pw.Text('Purpose:'),
              pw.Text(purpose),
              pw.SizedBox(height: 20),
              pw.Text('Copy Type: $copyType'),
              pw.SizedBox(height: 20),
              pw.Text('Reference Number: $referenceNumber'),
              pw.SizedBox(height: 20),
              pw.Text('Payment Details:'),
              pw.Text('Provider: $paymentProvider'),
              pw.Text('Total Amount: PHP ${price.toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Text('Claiming Method: $claimingMethod'),
              if (claimingMethod == 'Delivery')
                pw.Text('Note: Requesting party will do the booking and shoulder the shipping fee'),
              if (requestingSchool != null) ...[
                pw.SizedBox(height: 20),
                pw.Text('Note: Present/Submit an official letter from the requesting school upon claiming the document.',
                    style: pw.TextStyle(color: PdfColors.black)),
              ],
              pw.SizedBox(height: 40),
              pw.Text(
                  'Please present a copy (soft copy or hard copy) of this receipt when claiming your documents.'),
              pw.Text('Note: Processing may take 3-5 working days.'),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'document_request_$requestId.pdf',
    );
  }
}
