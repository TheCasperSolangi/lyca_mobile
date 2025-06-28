import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF2E7CF6),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2E7CF6), Color(0xFF4A90FF)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Terms of Service',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Last updated: June 26, 2025',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Terms of Service Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSection(
                    'Agreement to Terms',
                    Icons.handshake_outlined,
                    'By accessing and using our Student Management System mobile application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Use License',
                    Icons.verified_user_outlined,
                    'Permission is granted to temporarily use our application for educational purposes only. This license shall automatically terminate if you violate any of these restrictions:\n\n'
                    '• You may not modify or copy the materials\n'
                    '• You may not use the materials for commercial purposes\n'
                    '• You may not attempt to reverse engineer any software\n'
                    '• You may not remove any copyright or proprietary notations',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'User Accounts',
                    Icons.account_circle_outlined,
                    'When you create an account with us, you must provide accurate, complete, and current information. You are responsible for:\n\n'
                    '• Safeguarding your password and account credentials\n'
                    '• All activities that occur under your account\n'
                    '• Immediately notifying us of unauthorized access\n'
                    '• Ensuring your account information remains current and accurate',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Acceptable Use',
                    Icons.rule_outlined,
                    'You agree not to use the application to:\n\n'
                    '• Violate any applicable laws or regulations\n'
                    '• Transmit harmful, offensive, or inappropriate content\n'
                    '• Impersonate others or provide false information\n'
                    '• Interfere with the security or functionality of the app\n'
                    '• Access data not intended for you\n'
                    '• Use automated systems to access the service',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Educational Content',
                    Icons.school_outlined,
                    'All educational content, including but not limited to academic records, grades, and assignments, is provided for educational purposes only. The accuracy and completeness of such information is the responsibility of the educational institution.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Privacy and Data Protection',
                    Icons.privacy_tip_outlined,
                    'Your privacy is important to us. Our collection and use of personal information is governed by our Privacy Policy. By using our service, you consent to the collection and use of information as outlined in our Privacy Policy.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Service Availability',
                    Icons.cloud_outlined,
                    'We strive to maintain service availability but cannot guarantee uninterrupted access. The service may be temporarily unavailable due to:\n\n'
                    '• Scheduled maintenance\n'
                    '• Technical difficulties\n'
                    '• Circumstances beyond our control\n'
                    '• Educational institution requirements',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Intellectual Property',
                    Icons.copyright_outlined,
                    'The application and its original content, features, and functionality are owned by us and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Termination',
                    Icons.block_outlined,
                    'We may terminate or suspend your account and access immediately, without prior notice, for any reason whatsoever, including without limitation if you breach the Terms. Upon termination, your right to use the service will cease immediately.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Limitation of Liability',
                    Icons.warning_outlined,
                    'In no event shall our company, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages arising out of your use of the service.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Changes to Terms',
                    Icons.update_outlined,
                    'We reserve the right to modify or replace these Terms at any time. If a revision is material, we will try to provide at least 30 days notice prior to any new terms taking effect.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Governing Law',
                    Icons.gavel_outlined,
                    'These Terms shall be interpreted and governed by the laws of Pakistan. Any disputes relating to these terms will be subject to the exclusive jurisdiction of the courts of Karachi, Sindh, Pakistan.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildContactSection(),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF2E7CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2E7CF6).withOpacity(0.1),
            const Color(0xFF4A90FF).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7CF6).withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7CF6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.contact_support_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Contact Us',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'If you have any questions about these Terms of Service, please contact us:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildContactInfo(Icons.email_outlined, 'legal@studentapp.com'),
            const SizedBox(height: 8),
            _buildContactInfo(Icons.phone_outlined, '+92 300 1234567'),
            const SizedBox(height: 8),
            _buildContactInfo(Icons.location_on_outlined, 'Karachi, Sindh, Pakistan'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF2E7CF6).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: const Color(0xFF2E7CF6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'By using our app, you acknowledge that you have read and understood these terms.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF2E7CF6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String info) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF2E7CF6),
        ),
        const SizedBox(width: 8),
        Text(
          info,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2E7CF6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}