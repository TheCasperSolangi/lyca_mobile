import 'package:flutter/material.dart';

class IQManagementScreen extends StatefulWidget {
  const IQManagementScreen({super.key});

  @override
  State<IQManagementScreen> createState() => _IQManagementScreenState();
}

class _IQManagementScreenState extends State<IQManagementScreen> {
  // Mock data for previously attempted tests
  final List<Map<String, dynamic>> _previousTests = [
    {
      'date': '2023-05-15',
      'score': 120,
      'status': 'Completed',
    },
    {
      'date': '2023-03-10',
      'score': 115,
      'status': 'Completed',
    },
    {
      'date': '2023-01-05',
      'score': '--',
      'status': 'Incomplete',
    },
  ];

  void _attemptNewTest() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New IQ Test'),
          content: const Text(
              'IQ Test Created. Please attempt the test using the link provided.'),
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
        title: const Text('IQ Test Management'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Previously Attempted IQ Tests',
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
                    title: Text('Test on ${test['date']}'),
                    subtitle: Text('Score: ${test['score']}'),
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
              ),
              child: const Text(
                'Attempt IQ Test',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}