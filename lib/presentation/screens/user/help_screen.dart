import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Color(0xFF001184),
        title: const Text(
          'Help',
          style: TextStyle(color: Color.fromARGB(255, 255, 247, 247)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'How to Request Documents',
              [
                'Tap on "Request Documents" in the navigation menu or home screen',
                'Select the document type you need',
                'Fill in all required information',
                'Submit your request and note down your Request ID',
                'For documents to be claimed through delivery, kindly inform the respective registrar through email, call, or message about the information of rider when the document is ready to be retrieved',
                'Document copies are limited to 3'
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Document Types',
              [
                'SF10 (F137) Official - Official transcript for transferees',
                'Good Moral Certificate - Character reference document',
                'Other Documents - Various school-related certifications',
                'Documents from other schools that are requested to be filled out by OLOPSC such as Grades Form are outside the scope of this service. Kindly request this type of document through OLOPSC email',
                'Users are able to request soft copy or hard copy per request',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Payment Process',
              [
                'Pay through BPI, GCASH, or BDO',
                'Send a proof of payment to the email address provided',
                'Include your reference number in the email with your full name and student number',
                'Submit your request and note down your reference number',
                'Send proof of payment to pscashier@olopsc.edu.ph for Pre-School',
                'Send proof of payment to gs@olopsc.edu.ph for Grade School',
                'Send proof of payment to jhs@olopsc.edu.ph for Junior High School',
                'Send proof of payment to shs@olopsc.edu.ph for Senior High School',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Tracking Your Request',
              [
                'Go to "Request History" to view your requests',
                'Check the status of your document requests',
                'Download receipts for your records',
                'Contact the registrar for any concerns',
                'Users can track their request without logging in by inputting their Request ID in the Quick Search Tracking feature'
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Contact and Schedule Information',
              [
                'For more inquiries, please call 0969-563-0970(For Nursery to JHS)',
                'For more inquiries, please call 0998-595-7592(For SHS)',
                'Registrar Office Hours: 7:30 AM - 4:30 PM',
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'System Information',
              [
                'Accounts are created by the administrators, kindly inform the registrar if a student is not registered',
                'Alumni accounts are automatically deleted once logged out. Please save your receipt and take note of your Request ID',
                'Keep copies of all submitted documents for your records',
                'Users can only request one document per request, although multiple copies are still allowed',
                
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF001184),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, color: Color(0xFF001184)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )),
        const Divider(height: 32),
      ],
    );
  }
}
