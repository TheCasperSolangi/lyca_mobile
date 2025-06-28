import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
                        Icons.privacy_tip_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Privacy Matters',
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
            
            // Privacy Policy Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSection(
                    'Introduction',
                    Icons.info_outline,
                    'Welcome to our Student Management System. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Information We Collect',
                    Icons.data_usage_outlined,
                    'We may collect information about you in a variety of ways:\n\n'
                    '• Personal Data: Name, email address, phone number, date of birth, and other contact information\n'
                    '• Academic Information: Student ID, grades, attendance records, academic performance\n'
                    '• Device Information: Device type, operating system, unique device identifiers\n'
                    '• Usage Data: Information about how you use our app, including pages visited and features used',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'How We Use Your Information',
                    Icons.settings_outlined,
                    'We use the information we collect to:\n\n'
                    '• Provide and maintain our educational services\n'
                    '• Process academic records and generate reports\n'
                    '• Communicate with students, parents, and educational staff\n'
                    '• Improve our application and user experience\n'
                    '• Ensure security and prevent fraud\n'
                    '• Comply with legal obligations and educational requirements',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Information Sharing',
                    Icons.share_outlined,
                    'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except in the following circumstances:\n\n'
                    '• With educational institutions for academic purposes\n'
                    '• With parents/guardians for student progress monitoring\n'
                    '• With service providers who assist in our operations\n'
                    '• When required by law or to protect rights and safety',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Data Security',
                    Icons.security_outlined,
                    'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet or electronic storage is 100% secure.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Data Retention',
                    Icons.schedule_outlined,
                    'We retain your personal information for as long as necessary to fulfill the purposes outlined in this privacy policy, unless a longer retention period is required by law or educational regulations.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Your Rights',
                    Icons.account_circle_outlined,
                    'You have the right to:\n\n'
                    '• Access your personal information\n'
                    '• Request correction of inaccurate data\n'
                    '• Request deletion of your data (subject to legal requirements)\n'
                    '• Object to processing of your data\n'
                    '• Request data portability\n'
                    '• Withdraw consent where applicable',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Children\'s Privacy',
                    Icons.child_care_outlined,
                    'Our service is designed for educational institutions and may be used by minors. We are committed to protecting children\'s privacy and comply with applicable laws regarding the collection and use of information from children under 13.',
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildSection(
                    'Changes to Privacy Policy',
                    Icons.update_outlined,
                    'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
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
              'If you have any questions about this Privacy Policy, please contact us:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            _buildContactInfo(Icons.email_outlined, 'privacy@studentapp.com'),
            const SizedBox(height: 8),
            _buildContactInfo(Icons.phone_outlined, '+92 300 1234567'),
            const SizedBox(height: 8),
            _buildContactInfo(Icons.location_on_outlined, 'Karachi, Sindh, Pakistan'),
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