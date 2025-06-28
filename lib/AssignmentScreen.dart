import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  List<Map<String, dynamic>> assignments = [];
  Map<String, dynamic>? studentData;
  List<Map<String, dynamic>> classes = [];
  Map<String, bool> submissionStatus = {}; // Track submission status for each assignment
  Map<String, Map<String, dynamic>> submissionDetails = {}; // Track detailed submission info
  bool isLoading = true;
  String? errorMessage;
  String selectedFilter = 'All';
  
  final String baseUrl = 'http://192.168.1.13:5000/api/v2';
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _loadStudentData();
      await _loadClasses();
      await _loadAssignments();
      await _checkSubmissionStatus(); // Check submission status for all assignments
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final token = prefs.getString('token');
    
    if (username == null) {
      throw Exception('Username not found in storage');
    }
    
    if (token == null) {
      throw Exception('Authorization token not found in storage');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/students/username/$username'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      studentData = json.decode(response.body);
    } else {
      throw Exception('Failed to load student data: ${response.statusCode}');
    }
  }

  Future<void> _loadClasses() async {
    final prefs = await SharedPreferences.getInstance();
    final schoolCode = prefs.getString('school_code');
    final campusCode = prefs.getString('campus_code');
    final token = prefs.getString('token');
    
    if (schoolCode == null || campusCode == null) {
      throw Exception('School or campus code not found in storage');
    }
    
    if (token == null) {
      throw Exception('Authorization token not found in storage');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/classes/$schoolCode/$campusCode'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      classes = List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load classes: ${response.statusCode}');
    }
  }

  Future<void> _loadAssignments() async {
    if (studentData == null) {
      throw Exception('Student data not loaded');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authorization token not found in storage');
    }

    final classCode = studentData!['class_code'];
    
    final response = await http.get(
      Uri.parse('$baseUrl/assignments/class/$classCode'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> assignmentData = json.decode(response.body);
      
      setState(() {
        assignments = assignmentData.map((assignment) {
          return {
            'assignment_code': assignment['assignment_code'] ?? '',
            'assignment_title': assignment['assignment_title'] ?? '',
            'teacher_username': assignment['teacher_username'] ?? '',
            'assignment_description': assignment['assignment_description'] ?? '',
            'assignment_doc': assignment['assignment_doc'] ?? '',
            'status': assignment['status'] ?? 'Open',
            'deadline': DateTime.parse(assignment['deadline']),
            'assignment_points': assignment['assignment_points'] ?? 0,
            'passing_points': assignment['passing_points'] ?? 0,
            'subject_icon': _getSubjectIcon(assignment['assignment_title']),
            'subject_color': _getSubjectColor(assignment['assignment_title']),
          };
        }).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load assignments: ${response.statusCode}');
    }
  }

  // Check submission status for assignments
  Future<void> _checkSubmissionStatus() async {
    if (studentData == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/submissions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> submissions = json.decode(response.body);
        final studentUsername = studentData!['student_username'];
        
        // Create maps for assignment submission status and details
        Map<String, bool> statusMap = {};
        Map<String, Map<String, dynamic>> detailsMap = {};
        
        for (var assignment in assignments) {
          final assignmentCode = assignment['assignment_code'];
          final submission = submissions.firstWhere(
            (sub) => sub['assignment_code'] == assignmentCode && 
                     sub['student_username'] == studentUsername,
            orElse: () => null,
          );
          
          if (submission != null) {
            statusMap[assignmentCode] = true;
            detailsMap[assignmentCode] = {
              'status': submission['status'] ?? 'Pending Submission',
              'submission_points': submission['submission_points'] ?? 0,
              'verdict': submission['verdict'] ?? 'Fail',
              'submission_time': submission['submission_time'] ?? '',
              'submission_doc': submission['submission_doc'] ?? '',
            };
          } else {
            statusMap[assignmentCode] = false;
          }
        }
        
        setState(() {
          submissionStatus = statusMap;
          submissionDetails = detailsMap;
        });
      }
    } catch (e) {
      // Silently handle submission status check errors
      print('Error checking submission status: $e');
    }
  }

  // Submit assignment
  Future<void> _submitAssignment(Map<String, dynamic> assignment) async {
    try {
      // Show file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Submitting assignment...'),
              ],
            ),
          ),
        );

        // Upload file and create submission
        await _uploadFileAndSubmit(file, assignment);
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Refresh submission status
        await _checkSubmissionStatus();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Assignment submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context, rootNavigator: true).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit assignment: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Upload file and create submission
  Future<void> _uploadFileAndSubmit(File file, Map<String, dynamic> assignment) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      throw Exception('Authorization token not found');
    }

    // Create multipart request for file upload
    var uploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.13/api/uploads'),
    );
    
    uploadRequest.headers['Authorization'] = 'Bearer $token';
    uploadRequest.files.add(await http.MultipartFile.fromPath('file', file.path));
    
    var uploadResponse = await uploadRequest.send();
    
    if (uploadResponse.statusCode != 200) {
      throw Exception('Failed to upload file');
    }
    
    // Get the uploaded file URL
    var uploadResponseData = await uploadResponse.stream.bytesToString();
    var uploadResult = json.decode(uploadResponseData);
    String fileUrl = uploadResult['url']; // Assuming the response contains a 'url' field
    
    // Create submission
    final submissionData = {
      'assignment_code': assignment['assignment_code'],
      'submission_time': DateTime.now().toIso8601String(),
      'student_username': studentData!['student_username'],
      'submission_doc': fileUrl,
      'status': 'Pending Submission',
      'submission_points': 0,
      'verdict': 'Fail' // Default, will be updated when graded
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/submissions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(submissionData),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Failed to create submission record');
    }
  }

  String _getSubjectIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('math') || titleLower.contains('algebra')) {
      return 'assets/math_icon.svg';
    } else if (titleLower.contains('computer') || titleLower.contains('programming') || titleLower.contains('cs')) {
      return 'assets/cs_icon.svg';
    } else if (titleLower.contains('physics') || titleLower.contains('quantum')) {
      return 'assets/physics_icon.svg';
    } else if (titleLower.contains('chemistry')) {
      return 'assets/chemistry_icon.svg';
    } else if (titleLower.contains('biology')) {
      return 'assets/biology_icon.svg';
    } else if (titleLower.contains('english') || titleLower.contains('literature')) {
      return 'assets/english_icon.svg';
    } else {
      return 'assets/default_icon.svg';
    }
  }

  int _getSubjectColor(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('math') || titleLower.contains('algebra')) {
      return 0xFF4CAF50; // Green
    } else if (titleLower.contains('computer') || titleLower.contains('programming') || titleLower.contains('cs')) {
      return 0xFF2196F3; // Blue
    } else if (titleLower.contains('physics') || titleLower.contains('quantum')) {
      return 0xFFF44336; // Red
    } else if (titleLower.contains('chemistry')) {
      return 0xFFFF9800; // Orange
    } else if (titleLower.contains('biology')) {
      return 0xFF8BC34A; // Light Green
    } else if (titleLower.contains('english') || titleLower.contains('literature')) {
      return 0xFF9C27B0; // Purple
    } else {
      return 0xFF607D8B; // Blue Grey
    }
  }

  List<Map<String, dynamic>> get filteredAssignments {
    if (selectedFilter == 'All') {
      return assignments;
    }
    return assignments.where((assignment) => assignment['status'] == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Assignments', 
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white,
            )),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6A11CB).withOpacity(0.9),
                const Color(0xFF2575FC).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 26),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        displacement: 40,
        backgroundColor: Colors.white,
        color: const Color(0xFF2575FC),
        onRefresh: _loadData,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2575FC)),
                ),
              )
            : errorMessage != null
                ? _buildErrorWidget()
                : _buildContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF6A11CB),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Assignments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2575FC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        if (studentData != null)
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: studentData!['student_profile_pic'] != null
                          ? NetworkImage(studentData!['student_profile_pic'])
                          : null,
                      child: studentData!['student_profile_pic'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentData!['full_name'] ?? 'Student',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Class: ${_getClassName(studentData!['class_code'])}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                _buildFilterChip('All', selectedFilter == 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('Open', selectedFilter == 'Open'),
                const SizedBox(width: 8),
                _buildFilterChip('Closed', selectedFilter == 'Closed'),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: filteredAssignments.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 64),
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No assignments found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final assignment = filteredAssignments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAssignmentCard(context, assignment, index),
                      );
                    },
                    childCount: filteredAssignments.length,
                  ),
                ),
        ),
      ],
    );
  }

  String _getClassName(String classCode) {
    final classObj = classes.firstWhere(
      (c) => c['_id'] == classCode,
      orElse: () => {'name': 'Unknown Class'},
    );
    return classObj['name'] ?? 'Unknown Class';
  }

  Widget _buildFilterChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool value) {
        setState(() {
          selectedFilter = label;
        });
      },
      selectedColor: const Color(0xFF6A11CB),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey[700],
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: selected ? 2 : 0,
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Map<String, dynamic> assignment, int index) {
    final daysRemaining = assignment['deadline'].difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0 && assignment['status'] == 'Open';
    final subjectColor = Color(assignment['subject_color']);
    final isSubmitted = submissionStatus[assignment['assignment_code']] ?? false;
    final submissionDetail = submissionDetails[assignment['assignment_code']];

    return GestureDetector(
      onTap: () {
        _showAssignmentDetails(context, assignment);
      },
      child: Hero(
        tag: 'assignment_${assignment['assignment_code']}',
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          shadowColor: subjectColor.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white,
                  subjectColor.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: isSubmitted 
                    ? (submissionDetail?['verdict'] == 'Pass' ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3))
                    : Colors.grey.withOpacity(0.1),
                width: isSubmitted ? 2 : 1,
              )),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: subjectColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.assignment,
                              color: subjectColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        assignment['assignment_title'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                    ),
                                    if (isSubmitted)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: submissionDetail?['verdict'] == 'Pass' 
                                              ? Colors.green.withOpacity(0.1)
                                              : submissionDetail?['status'] == 'Submitted'
                                                  ? Colors.orange.withOpacity(0.1)
                                                  : Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              submissionDetail?['verdict'] == 'Pass' 
                                                  ? Icons.check_circle
                                                  : submissionDetail?['status'] == 'Submitted'
                                                      ? Icons.schedule
                                                      : Icons.upload_file,
                                              size: 14,
                                              color: submissionDetail?['verdict'] == 'Pass' 
                                                  ? Colors.green[700]
                                                  : submissionDetail?['status'] == 'Submitted'
                                                      ? Colors.orange[700]
                                                      : Colors.blue[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              submissionDetail?['verdict'] == 'Pass' 
                                                  ? 'Passed'
                                                  : submissionDetail?['status'] == 'Submitted'
                                                      ? 'Graded'
                                                      : 'Submitted',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: submissionDetail?['verdict'] == 'Pass' 
                                                    ? Colors.green[700]
                                                    : submissionDetail?['status'] == 'Submitted'
                                                        ? Colors.orange[700]
                                                        : Colors.blue[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${assignment['assignment_code']} • ${assignment['teacher_username']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600]),
                                ),
                                if (isSubmitted && submissionDetail?['status'] == 'Submitted')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Score: ${submissionDetail?['submission_points']}/${assignment['assignment_points']} • ${submissionDetail?['verdict']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: submissionDetail?['verdict'] == 'Pass' 
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        assignment['assignment_description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildDetailChip(
                            Icons.timer_outlined,
                            isOverdue
                                ? 'Overdue!'
                                : '${daysRemaining.abs()} ${daysRemaining.abs() == 1 ? 'day' : 'days'} ${isOverdue ? 'ago' : 'left'}',
                            isOverdue ? Colors.red : subjectColor,
                          ),
                          const SizedBox(width: 8),
                          _buildDetailChip(
                            Icons.star_outline,
                            '${assignment['assignment_points']} pts',
                            subjectColor,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: assignment['status'] == 'Open'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              assignment['status'],
                              style: TextStyle(
                                color: assignment['status'] == 'Open'
                                    ? Colors.green[800]
                                    : Colors.red[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (assignment['status'] == 'Open' && !isOverdue && !isSubmitted)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: subjectColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_outward,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignmentDetails(BuildContext context, Map<String, dynamic> assignment) {
    final subjectColor = Color(assignment['subject_color']);
    final daysRemaining = assignment['deadline'].difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0 && assignment['status'] == 'Open';
    final isSubmitted = submissionStatus[assignment['assignment_code']] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'assignment_${assignment['assignment_code']}',
                        child: Material(
                          color: Colors.transparent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: subjectColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.assignment,
                                  color: subjectColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      assignment['assignment_title'],
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${assignment['assignment_code']} • ${assignment['teacher_username']}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600]),
                                    ),
                                    if (isSubmitted)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: Colors.green[700],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Assignment Submitted',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green[700],
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
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: subjectColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: subjectColor.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDetailCircle(
                              'Points',
                              '${assignment['assignment_points']}',
                              subjectColor,
                            ),
                            _buildDetailCircle(
                              'To Pass',
                              '${assignment['passing_points']}',
                              subjectColor,
                            ),
                            _buildDetailCircle(
                              'Status',
                              assignment['status'],
                              assignment['status'] == 'Open'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignment['assignment_description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Deadline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? Colors.red.withOpacity(0.05)
                              : subjectColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOverdue
                                ? Colors.red.withOpacity(0.2)
                                : subjectColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: isOverdue ? Colors.red : subjectColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _dateFormat.format(assignment['deadline']),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isOverdue
                                        ? Colors.red
                                        : const Color(0xFF333333),
                                  ),
                                ),
                                Text(
                                  _timeFormat.format(assignment['deadline']),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              isOverdue
                                  ? 'Overdue!'
                                  : '${daysRemaining.abs()} ${daysRemaining.abs() == 1 ? 'day' : 'days'} ${isOverdue ? 'ago' : 'left'}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isOverdue ? Colors.red : subjectColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (assignment['status'] == 'Open')
                        Column(
                          children: [
                            if (!isSubmitted) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isOverdue 
                                      ? null 
                                      : () {
                                          Navigator.pop(context);
                                          _submitAssignment(assignment);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isOverdue 
                                        ? Colors.grey 
                                        : subjectColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                    shadowColor: subjectColor.withOpacity(0.3),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isOverdue ? Icons.block : Icons.upload_file,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isOverdue 
                                            ? 'Submission Closed' 
                                            : 'Submit Assignment',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Assignment Submitted Successfully',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.green[800],
                                            ),
                                          ),
                                          Text(
                                            'Your submission is being reviewed',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.green[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: () {
                                  // View assignment document
                                  if (assignment['assignment_doc'] != null && 
                                      assignment['assignment_doc'].isNotEmpty) {
                                    // Open document URL
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Opening assignment document...'),
                                        backgroundColor: subjectColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No document available'),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: subjectColor,
                                  side: BorderSide(color: subjectColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'View Assignment Document',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCircle(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}