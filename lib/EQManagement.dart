import 'package:flutter/material.dart';

class EQManagementScreen extends StatefulWidget {
  const EQManagementScreen({super.key});

  @override
  State<EQManagementScreen> createState() => _EQManagementScreenState();
}

class _EQManagementScreenState extends State<EQManagementScreen> {
  // Mock data for previously attempted EQ tests
  final List<Map<String, dynamic>> _previousTests = [
    {
      'date': '2023-06-20',
      'score': 'High',
      'status': 'Completed',
      'type': 'Self-Awareness',
    },
    {
      'date': '2023-04-12',
      'score': 'Medium',
      'status': 'Completed',
      'type': 'Relationship Skills',
    },
    {
      'date': '2023-02-08',
      'score': '--',
      'status': 'Incomplete',
      'type': 'Self-Management',
    },
  ];

  void _attemptNewTest() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New EQ Assessment'),
          content: const Text(
              'EQ Assessment Created. Please complete the assessment using the link provided.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EQ Assessment Management'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Previous EQ Assessments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _previousTests.length,
              itemBuilder: (context, index) {
                final test = _previousTests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('${test['type']} Assessment'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date: ${test['date']}'),
                        Text('Score: ${test['score']}'),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(test['status']),
                      backgroundColor: test['status'] == 'Completed'
                          ? Colors.green[100]
                          : Colors.orange[100],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _attemptNewTest,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.green, // Green button for EQ
              ),
              child: const Text(
                'Start New EQ Assessment',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}