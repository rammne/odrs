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
    required String purpose, // Add this parameter
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
              pw.SizedBox(height: 20),
              pw.Text('Purpose:'),
              pw.Text(purpose), // Add purpose to the receipt
              pw.SizedBox(height: 40),
              pw.Text(
                  'Please present a copy (soft copy or hard copy) of this receipt when claiming your documents.'),
              pw.Text('Note: Processing may take 3-5 working days.'),
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
}

// class PDFGenerator {
//   static Future<void> generateDocument(
//     String documentType,
//     Map<String, dynamic> userData,
//   ) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         pageFormat: PdfPageFormat.a4,
//         build: (pw.Context context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Header(
//                 level: 0,
//                 child: pw.Text('Official Document',
//                     style: pw.TextStyle(fontSize: 24)),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text('Document Type: $documentType'),
//               pw.SizedBox(height: 10),
//               pw.Text('Student Name: ${userData['name']}'),
//               pw.Text('Student Number: ${userData['studentNumber']}'),
//               pw.SizedBox(height: 20),
//               pw.Text('Date Generated: ${DateTime.now().toString()}'),
//             ],
//           );
//         },
//       ),
//     );

//     // Show PDF preview dialog with download option
//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//       name: '${documentType}_${userData['studentNumber']}.pdf',
//     );
//   }
// }
