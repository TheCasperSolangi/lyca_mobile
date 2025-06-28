import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Model class for Leave
class Leave {
  final String id;
  final String requesterUsername;
  final String requesterType;
  final String leaveReason;
  final String leaveSupportingDocs;
  final int leaveDays;
  final DateTime leaveStart;
  final DateTime leaveEnding;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  Leave({
    required this.id,
    required this.requesterUsername,
    required this.requesterType,
    required this.leaveReason,
    required this.leaveSupportingDocs,
    required this.leaveDays,
    required this.leaveStart,
    required this.leaveEnding,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create Leave from JSON data
  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['_id'],
      requesterUsername: json['requester_username'],
      requesterType: json['requester_type'],
      leaveReason: json['leave_reason'],
      leaveSupportingDocs: json['leave_supporting_docs'],
      leaveDays: json['leave_days'],
      leaveStart: DateTime.parse(json['leave_start']),
      leaveEnding: DateTime.parse(json['leave_ending']),
      status: json['status'],
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// API Service for Leave Management
class LeaveService {
  // Base URLs for API
  final String baseUrl = 'http://192.168.1.13:5000/api/v2/leaves';
  final String storageUrl = 'http://192.168.1.13:5005/api/uploads';
  
  // Method to fetch leaves from API
  Future<List<Leave>> getStudentLeaves(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$username'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization headers if needed
          // 'Authorization': 'Bearer YOUR_AUTH_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          return data.map((json) => Leave.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${responseData['message']}');
        }
      } else {
        throw Exception('Failed to load leaves: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Method to apply for leave via API
  Future<bool> applyLeave(Map<String, dynamic> leaveData) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization headers if needed
          // 'Authorization': 'Bearer YOUR_AUTH_TOKEN',
        },
        body: json.encode(leaveData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        print('Leave application failed with status ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error applying for leave: $e');
      return false;
    }
  }
  
  // Method to upload supporting document to storage server
  Future<String?> uploadDocument(File file) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(storageUrl),
      );
      
      // Add authorization header if needed
      // request.headers.addAll({
      //   'Authorization': 'Bearer YOUR_AUTH_TOKEN',
      // });
      
      // Add file to request
      request.files.add(await http.MultipartFile.fromPath(
        'file', // The field name expected by your storage server
        file.path,
        filename: file.path.split('/').last,
      ));
      
      // Send request
      var response = await request.send();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Get response data
        final respStr = await response.stream.bytesToString();
        final respData = json.decode(respStr);
        
        // Return the file URL from server response
        // Assuming your storage server returns the URL in a specific field
        // Adjust this based on your actual storage server response format
        return respData['url'] ?? respData['fileUrl'] ?? respData['data']?['url'];
      } else {
        print('Document upload failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading document: $e');
      return null;
    }
  }
}

class StudentLeaveScreen extends StatefulWidget {
  @override
  _StudentLeaveScreenState createState() => _StudentLeaveScreenState();
}

class _StudentLeaveScreenState extends State<StudentLeaveScreen> {
  final LeaveService _leaveService = LeaveService();
  late Future<List<Leave>> _leavesFuture;
  
  // Current user info (would come from authentication in a real app)
  final String _username = "john_doe";
  
  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }
  
  void _loadLeaves() {
    setState(() {
      _leavesFuture = _leaveService.getStudentLeaves(_username);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'My Leaves',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadLeaves();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Refreshing leave data...'))
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderStats(),
          Expanded(
            child: FutureBuilder<List<Leave>>(
              future: _leavesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading leave data',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadLeaves,
                          icon: Icon(Icons.refresh),
                          label: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No leave records found',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                } else {
                  return _buildLeaveList(snapshot.data!);
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyLeaveDialog(),
        label: Text('Apply for Leave'),
        icon: Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: FutureBuilder<List<Leave>>(
        future: _leavesFuture,
        builder: (context, snapshot) {
          int approved = 0;
          int pending = 0;
          int rejected = 0;
          
          if (snapshot.hasData) {
            for (var leave in snapshot.data!) {
              if (leave.status == 'approved') approved++;
              if (leave.status == 'pending_review') pending++;
              if (leave.status == 'rejected') rejected++;
            }
          }
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Approved', approved.toString(), Colors.green),
              _buildStatCard('Pending', pending.toString(), Colors.amber),
              _buildStatCard('Rejected', rejected.toString(), Colors.red),
            ],
          );
        },
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

  Widget _buildLeaveList(List<Leave> leaves) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leave = leaves[index];
        return _buildLeaveCard(leave);
      },
    );
  }

  Widget _buildLeaveCard(Leave leave) {
    // Define colors based on status
    Color statusColor;
    IconData statusIcon;
    
    switch (leave.status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending_review':
      default:
        statusColor = Colors.amber;
        statusIcon = Icons.hourglass_bottom;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showLeaveDetails(leave),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: Colors.indigo),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      leave.leaveReason,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                          _formatStatus(leave.status),
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
                  Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    '${DateFormat('MMM dd').format(leave.leaveStart)} - ${DateFormat('MMM dd, yyyy').format(leave.leaveEnding)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Spacer(),
                  Text(
                    '${leave.leaveDays} day${leave.leaveDays > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              if (leave.status == 'rejected' && leave.rejectionReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Reason: ${leave.rejectionReason}',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending_review':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  void _showLeaveDetails(Leave leave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Reason', leave.leaveReason),
            _detailRow('Status', _formatStatus(leave.status)),
            _detailRow('Days', '${leave.leaveDays}'),
            _detailRow('Start Date', DateFormat('MMM dd, yyyy').format(leave.leaveStart)),
            _detailRow('End Date', DateFormat('MMM dd, yyyy').format(leave.leaveEnding)),
            _detailRow('Supporting Document', leave.leaveSupportingDocs.isNotEmpty ? 'Attached' : 'None'),
            if (leave.rejectionReason != null)
              _detailRow('Rejection Reason', leave.rejectionReason!),
            _detailRow('Applied On', DateFormat('MMM dd, yyyy').format(leave.createdAt)),
          ],
        ),
        actions: [
          if (leave.leaveSupportingDocs.isNotEmpty)
            TextButton(
              onPressed: () {
                // TODO: Implement document viewing/downloading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Document URL: ${leave.leaveSupportingDocs}')),
                );
              },
              child: Text('View Document'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
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

  void _showApplyLeaveDialog() {
    // Form controllers
    final reasonController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String? selectedFilePath;
    String? selectedFileName;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Apply for Leave'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason for Leave',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Text('Start Date:'),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          startDate = pickedDate;
                          // Auto-set end date if not already set
                          if (endDate == null || endDate!.isBefore(startDate!)) {
                            endDate = startDate;
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          SizedBox(width: 8),
                          Text(
                            startDate == null
                                ? 'Select Date'
                                : DateFormat('MMM dd, yyyy').format(startDate!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('End Date:'),
                  InkWell(
                    onTap: () async {
                      if (startDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select start date first')),
                        );
                        return;
                      }
                      
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: startDate!,
                        firstDate: startDate!,
                        lastDate: startDate!.add(Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          endDate = pickedDate;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16),
                          SizedBox(width: 8),
                          Text(
                            endDate == null
                                ? 'Select Date'
                                : DateFormat('MMM dd, yyyy').format(endDate!),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Supporting Document:'),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
                      );
                      if (result != null) {
                        setState(() {
                          selectedFilePath = result.files.single.path;
                          selectedFileName = result.files.single.name;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedFileName ?? 'Choose File',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                ),
                onPressed: () async {
                  if (reasonController.text.isEmpty || 
                      startDate == null || 
                      endDate == null || 
                      selectedFilePath == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill all required fields')),
                    );
                    return;
                  }
                  
                  // Submit leave application
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Submitting leave application..."),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  
                  // First upload the supporting document
                  String? docUrl;
                  if (selectedFilePath != null) {
                    docUrl = await _leaveService.uploadDocument(File(selectedFilePath!));
                    if (docUrl == null) {
                      Navigator.pop(context); // Close progress dialog
                      Navigator.pop(context); // Close form dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to upload supporting document'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }
                  
                  // Calculate days difference
                  final difference = endDate!.difference(startDate!).inDays + 1;
                  
                  // Format dates as strings (YYYY-MM-DD format)
                  final leaveData = {
                    'requester_username': _username,
                    'requester_type': 'Student',
                    'leave_reason': reasonController.text,
                    'leave_supporting_docs': docUrl ?? '',
                    'leave_days': difference,
                    'leave_start': DateFormat('yyyy-MM-dd').format(startDate!),
                    'leave_ending': DateFormat('yyyy-MM-dd').format(endDate!),
                    'status': 'pending_review',
                  };
                  
                  // Submit leave application
                  final result = await _leaveService.applyLeave(leaveData);
                  Navigator.pop(context); // Close progress dialog
                  Navigator.pop(context); // Close form dialog
                  
                  if (result) {
                    // Refresh the leaves list
                    _loadLeaves();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Leave application submitted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit leave application'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }
}