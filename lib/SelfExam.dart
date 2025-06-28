import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'dart:convert';
import 'dart:io';

// Model class for SelfExam - updated to match API schema
class SelfExam {
  final String id;
  final String attemptCode;
  final String testType;
  final String candidateUsername;
  final String schoolCode;
  final String campusCode;
  final String examinationName;
  final String status;
  final String? verdict;
  final int totalScore;
  final int? obtainedScore;
  final String questionBucketCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  SelfExam({
    required this.id,
    required this.attemptCode,
    required this.testType,
    required this.candidateUsername,
    required this.schoolCode,
    required this.campusCode,
    required this.examinationName,
    required this.status,
    this.verdict,
    required this.totalScore,
    this.obtainedScore,
    required this.questionBucketCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SelfExam.fromJson(Map<String, dynamic> json) {
    return SelfExam(
      id: json['_id'] ?? '',
      attemptCode: json['attempt_code'] ?? '',
      testType: json['test_type'] ?? '',
      candidateUsername: json['candidate_username'] ?? '',
      schoolCode: json['school_code'] ?? '',
      campusCode: json['campus_code'] ?? '',
      examinationName: json['examination_name'] ?? '',
      status: json['status'] ?? 'Pending',
      verdict: json['verdict'],
      totalScore: json['total_score'] ?? 0,
      obtainedScore: json['obtained_score'],
      questionBucketCode: json['question_bucket_code'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// API Service class
class ExamApiService {
  static const String baseUrl = 'http://192.168.1.13:5000/api/v2'; // Replace with your actual API URL
  
  static Future<Map<String, String>> _getAuthHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? '',
      'school_code': prefs.getString('school_code') ?? '',
      'campus_code': prefs.getString('campus_code') ?? '',
    };
  }

  // Get exams by user
  static Future<List<SelfExam>> getExamsByUser(String username) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/self_exams/user/$username'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> examsJson = data['exams'] ?? [];
        return examsJson.map((json) => SelfExam.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load exams: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Create new exam
  static Future<bool> createExam({
    required String testType,
    required String examinationName,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final userData = await _getUserData();
      
      // Generate unique attempt code
      final attemptCode = 'ATT_${DateTime.now().millisecondsSinceEpoch}';
      
      // Set question bucket code based on test type
      final questionBucketCode = 'QB_${testType}_001';
      
      // Set total score based on test type
      int totalScore;
      switch (testType) {
        case 'SAT':
          totalScore = 1600;
          break;
        case 'IQ':
          totalScore = 160;
          break;
        case 'EQ':
          totalScore = 100;
          break;
        case 'LAT':
          totalScore = 100;
          break;
        default:
          totalScore = 100;
      }

      final body = {
        'attempt_code': attemptCode,
        'test_type': testType,
        'test_code': 'TC_${testType}_001',
        'examination_name': examinationName,
        'status': 'Pending',
        'total_score': totalScore,
        'question_bucket_code': questionBucketCode,
        'candidate_username': userData['username'],
        'school_code': userData['school_code'],
        'campus_code': userData['campus_code'],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/self_exams'),
        headers: headers,
        body: json.encode(body),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating exam: $e');
      return false;
    }
  }

  // Download PDF result
  static Future<String?> downloadExamResultPDF(String attemptCode) async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Get auth headers with attempt token
      final headers = await _getAuthHeaders();
      headers['x-attempt-token'] = attemptCode;

      final response = await http.get(
        Uri.parse('$baseUrl/self-exams/pdf-result'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Get downloads directory
        Directory? downloadsDir;
        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            downloadsDir = await getExternalStorageDirectory();
          }
        } else {
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        if (downloadsDir == null) {
          throw Exception('Could not access storage directory');
        }

        // Create filename
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final filename = 'exam_result_$timestamp.pdf';
        final filePath = '${downloadsDir.path}/$filename';

        // Write PDF bytes to file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return filePath;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Exam must be completed to generate PDF');
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading PDF: $e');
      throw Exception('Failed to download PDF: $e');
    }
  }
}

class SelfExamScreen extends StatefulWidget {
  @override
  _SelfExamScreenState createState() => _SelfExamScreenState();
}

class _SelfExamScreenState extends State<SelfExamScreen> {
  String _username = "";
  List<SelfExam> _examApplications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
    await _loadExams();
  }

  Future<void> _loadExams() async {
    if (_username.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exams = await ExamApiService.getExamsByUser(_username);
      setState(() {
        _examApplications = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Self Exam Applications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadExams,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderStats(),
          Expanded(
            child: _buildExamList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyExamDialog(),
        label: Text('Apply for Exam'),
        icon: Icon(Icons.quiz),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Widget _buildHeaderStats() {
    int approved = 0;
    int pending = 0;
    int completed = 0;
    int attempted = 0;
    
    for (var exam in _examApplications) {
      switch (exam.status.toLowerCase()) {
        case 'pending':
          pending++;
          break;
        case 'attempted':
          attempted++;
          break;
        case 'completed':
          completed++;
          break;
      }
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Pending', pending.toString(), Colors.amber),
              _buildStatCard('Attempted', attempted.toString(), Colors.blue),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Completed', completed.toString(), Colors.green),
              _buildStatCard('Total', _examApplications.length.toString(), Colors.indigo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(height: 16),
            Text('Loading exams...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error loading exams',
              style: TextStyle(fontSize: 18, color: Colors.red[600]),
            ),
            SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExams,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_examApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No exam applications found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Apply for your first exam using the button below',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _examApplications.length,
        itemBuilder: (context, index) {
          final exam = _examApplications[index];
          return _buildExamCard(exam);
        },
      ),
    );
  }

  Widget _buildExamCard(SelfExam exam) {
    Color statusColor;
    IconData statusIcon;
    
    switch (exam.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'attempted':
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_bottom;
        break;
      case 'pending':
      default:
        statusColor = Colors.amber;
        statusIcon = Icons.schedule;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showExamDetails(exam),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getExamIcon(exam.testType), color: Colors.purple),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.examinationName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          exam.testType,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        SizedBox(width: 4),
                        Text(
                          exam.status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Created: ${DateFormat('MMM dd, yyyy').format(exam.createdAt)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              if (exam.obtainedScore != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.score, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Score: ${exam.obtainedScore}/${exam.totalScore}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      if (exam.verdict != null) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: exam.verdict == 'Pass' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            exam.verdict!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: exam.verdict == 'Pass' ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                      Spacer(),
                      if (exam.status.toLowerCase() == 'completed')
                        InkWell(
                          onTap: () => _downloadPDF(exam.attemptCode),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download, size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'PDF',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getExamIcon(String testType) {
    switch (testType.toUpperCase()) {
      case 'IQ':
        return Icons.psychology;
      case 'EQ':
        return Icons.favorite;
      case 'SAT':
        return Icons.school;
      case 'LAT':
        return Icons.quiz;
      default:
        return Icons.quiz;
    }
  }

  void _showExamDetails(SelfExam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exam Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Exam Name', exam.examinationName),
              _detailRow('Test Type', exam.testType),
              _detailRow('Status', exam.status),
              _detailRow('Total Score', exam.totalScore.toString()),
              if (exam.obtainedScore != null)
                _detailRow('Obtained Score', exam.obtainedScore.toString()),
              if (exam.verdict != null)
                _detailRow('Verdict', exam.verdict!),
              _detailRow('School Code', exam.schoolCode),
              _detailRow('Campus Code', exam.campusCode),
              _detailRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(exam.createdAt)),
              _detailRow('Updated', DateFormat('MMM dd, yyyy HH:mm').format(exam.updatedAt)),
            ],
          ),
        ),
        actions: [
          if (exam.status.toLowerCase() == 'completed')
            TextButton.icon(
              onPressed: () => _downloadPDF(exam.attemptCode),
              icon: Icon(Icons.download, color: Colors.green),
              label: Text('Download PDF', style: TextStyle(color: Colors.green)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPDF(String attemptCode) async {
    // Close the dialog first
    Navigator.pop(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Generating PDF...'),
            SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    try {
      final filePath = await ExamApiService.downloadExamResultPDF(attemptCode);
      
      Navigator.pop(context); // Close loading dialog

      if (filePath != null) {
        // Show success dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('PDF Downloaded'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your exam result has been downloaded successfully.'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    filePath,
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openPDF(filePath);
                },
                icon: Icon(Icons.open_in_new),
                label: Text('Open PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Download Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Failed to download the PDF result.'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  e.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Please try again or contact support if the problem persists.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _downloadPDF(attemptCode); // Retry
              },
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openPDF(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done) {
        // If the default app couldn't open it, show alternatives
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${filePath}'),
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () {
                // You can implement share functionality here if needed
                // For now, just show the path
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open PDF. File saved to: ${filePath}'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showApplyExamDialog() {
    String? selectedTestType;
    String customExamName = '';
    
    // Available exam types as per your requirement
    final List<Map<String, String>> examTypes = [
      {'type': 'SAT', 'description': 'Scholastic Assessment Test'},
      {'type': 'LAT', 'description': 'Law Admission Test'},
      {'type': 'IQ', 'description': 'Intelligence Quotient Test'},
      {'type': 'EQ', 'description': 'Emotional Quotient Assessment'},
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Apply for Self Exam'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Test Type:'),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTestType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: examTypes.map((exam) {
                      return DropdownMenuItem<String>(
                        value: exam['type'],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              exam['type']!,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              exam['description']!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTestType = value;
                        // Set default exam name based on test type
                        if (value != null) {
                          customExamName = '${value} Practice Test ${DateTime.now().year}';
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => customExamName = value,
                    decoration: InputDecoration(
                      labelText: 'Examination Name',
                      border: OutlineInputBorder(),
                      hintText: 'Enter custom exam name or use default',
                    ),
                    controller: TextEditingController(text: customExamName),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Notes:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• Exam will be created in "Pending" status\n'
                          '• You can attempt the exam once approved\n'
                          '• Each test type has different scoring criteria',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),

// Replace your ElevatedButton onPressed handler with this fixed version:
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.purple,
  ),
  onPressed: selectedTestType == null || customExamName.isEmpty
      ? null
      : () async {
          // Store the navigator and scaffold messenger references
          final navigator = Navigator.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          
          // Close the apply dialog first
          navigator.pop();
          
          // Show loading dialog and store its context
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.purple),
                    SizedBox(height: 16),
                    Text('Creating exam...'),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while we process your application',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
          
          try {
            print('Starting exam creation...');
            
            final success = await ExamApiService.createExam(
              testType: selectedTestType!,
              examinationName: customExamName,
            );
            
            print('Exam creation result: $success');
            
            // Close loading dialog safely
            if (mounted) {
              navigator.pop();
            }
            
            if (success) {
              print('Showing success message...');
              
              // Use the stored scaffold messenger reference
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Exam application submitted successfully!'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
                
                // Refresh the exam list
                print('Refreshing exam list...');
                _loadExams();
              }
              
            } else {
              print('Showing error message...');
              
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Failed to submit exam application'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: () {
                        if (mounted) {
                          _showApplyExamDialog();
                        }
                      },
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            print('Exception caught: $e');
            
            // Close loading dialog safely
            if (mounted) {
              navigator.pop();
            }
            
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Error: ${e.toString()}'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: () {
                      if (mounted) {
                        _showApplyExamDialog();
                      }
                    },
                  ),
                ),
              );
            }
          }
        },
  child: Text('Submit'),
)
            ],
          );
        },
      ),
    );
  }
}