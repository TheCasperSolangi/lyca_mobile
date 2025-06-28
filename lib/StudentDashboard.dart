import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {

 late TabController _tabController;
  late PageController _bannerController;
  int _currentBannerIndex = 0;
  late Timer _bannerTimer;
  int _currentIndex = 0;

  // Student data
  Map<String, dynamic> studentData = {};
  List<dynamic> announcements = [];
  List<dynamic> banners = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bannerController = PageController();
    _loadData();
  }
List<dynamic> subjects = []; // Replace the existing static subjects list

  // Menu items for the bottom sheet
  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Assignments',
      'icon': Icons.assignment,
      'color': const Color(0xFF3E64FF),
      'route':'/assignment'
    },
    {
      'title': 'Exams',
      'icon': Icons.quiz,
      'color': const Color(0xFFFF6A6A),
      'route': '/exams'
    },
    {
      'title':"Attendance",
      'icon':Icons.calendar_today,
      'color': const Color.fromARGB(255, 253, 144, 1),
      'route':'/attendance'
    },
    {
      'title': 'Library',
      'icon': Icons.local_library,
      'color': const Color(0xFF2BBBAD),
      'route':'/library'
    },
    {
      'title': 'Self Exams',
      'icon': Icons.event,
      'color': const Color(0xFFFDC639),
      'route':'/self_exams'
    },
     {
      'title': 'Mental Health',
      'icon': Icons.fastfood,
      'color': const Color(0xFFFF8C69),
      'route':'/mental_health'
    },
    {
      'title': 'Fees',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFF9C27B0),
      'route':'/fees'
    },
    {
      'title': 'Transportation',
      'icon': Icons.directions_bus,
      'color': const Color(0xFF11998E),
      'route':'/transport'
    },
   
    {
      'title': 'Leaves',
      'icon': Icons.people,
      'color': const Color(0xFF43CBFF),
      'route':'/leave'
    },
  ];




 Future<void> _loadData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final schoolCode = prefs.getString('school_code');
    final campusCode = prefs.getString('campus_code');
    final token = prefs.getString('token');

    print('Username: $username');
    print('School Code: $schoolCode');
    print('Campus Code: $campusCode');
    print('Token: ${token != null ? 'Present' : 'Missing'}');

    if (username == null || schoolCode == null || campusCode == null || token == null) {
      throw Exception('Missing required credentials');
    }

    // Fetch student data
    final studentResponse = await http.get(
      Uri.parse('http://192.168.1.13:5000/api/v2/students/username/$username'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    print('Student API Response Status: ${studentResponse.statusCode}');
    print('Student API Response Body: ${studentResponse.body}');

    if (studentResponse.statusCode != 200) {
      throw Exception('Failed to load student data: ${studentResponse.statusCode}');
    }

    // Fetch announcements
    final announcementsResponse = await http.get(
      Uri.parse('http://192.168.1.13:5000/api/v2/announcements/school/$schoolCode/campus/$campusCode'),
      headers: {'Authorization': 'Bearer $token'},
    );

    // Fetch subjects
final subjectsResponse = await http.get(
  Uri.parse('http://192.168.1.13:5000/api/v2/subjects'),
  headers: {'Authorization': 'Bearer $token'},
);

print('Subjects API Response Status: ${subjectsResponse.statusCode}');
print('Subjects API Response Body: ${subjectsResponse.body}');

if (subjectsResponse.statusCode != 200) {
  throw Exception('Failed to load subjects: ${subjectsResponse.statusCode}');
}

    print('Announcements API Response Status: ${announcementsResponse.statusCode}');
    print('Announcements API Response Body: ${announcementsResponse.body}');

    if (announcementsResponse.statusCode != 200) {
      throw Exception('Failed to load announcements: ${announcementsResponse.statusCode}');
    }

    // Fetch classes
    final classesResponse = await http.get(
      Uri.parse('http://192.168.1.13:5000/api/v2/classes'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Classes API Response Status: ${classesResponse.statusCode}');
    print('Classes API Response Body: ${classesResponse.body}');

    if (classesResponse.statusCode != 200) {
      throw Exception('Failed to load classes: ${classesResponse.statusCode}');
    }

    // Parse responses
    final studentDataResponse = json.decode(studentResponse.body);
    final announcementsDataResponse = json.decode(announcementsResponse.body);
    final classesDataResponse = json.decode(classesResponse.body);

    setState(() {
      // Find class name and section from class_code
      String className = 'Unknown';
      String classSection = '';
      
      if (classesDataResponse is List && studentDataResponse['class_code'] != null) {
        final classData = classesDataResponse.firstWhere(
          (classItem) => classItem['_id'] == studentDataResponse['class_code'],
          orElse: () => null,
        );
        
        if (classData != null) {
          className = classData['name'] ?? 'Unknown';
          classSection = classData['section'] ?? '';
        }
      }
      
      // Combine class name and section
      final fullClassName = classSection.isNotEmpty ? '$className $classSection' : className;

      // Handle subjects safely
final subjectsDataResponse = json.decode(subjectsResponse.body);
if (subjectsDataResponse is List) {
  subjects = subjectsDataResponse.map((subject) {
    return {
      'id': subject['_id'] ?? '',
      'title': subject['name'] ?? 'Unknown Subject',
      'icon': _getSubjectIcon(subject['name'] ?? ''),
      'announcements': 0, // You can add announcement count logic here
      'progress': 0.75, // You can calculate actual progress
      'type': subject['type'] ?? 'Theory',
      'image': subject['subject_image'] ?? 'https://via.placeholder.com/150',
      'fallbackColor': _getFallbackColor(subject['name'] ?? ''),
    };
  }).toList();
} else {
  subjects = [];
}

      // Handle student data safely
      studentData = {
        'full_name': studentDataResponse['full_name'] ?? 'Student Name',
        'name': studentDataResponse['full_name'] ?? 'Student Name', // Added: for buildStudentOverview
        'class': fullClassName, // Updated: use the resolved class name with section
        'rollNumber': studentDataResponse['roll_number'] ?? 'N/A',
        'attendance': studentDataResponse['attendance_percentage'] ?? '0%',
        'gpa': studentDataResponse['gpa'] ?? '0.0',
        'profilePicture': studentDataResponse['student_profile_pic'] ?? 'https://i.pinimg.com/736x/65/b1/83/65b183088ef17846c895091dcc7ff801.jpg',
      };
   
      // Handle announcements safely - Fixed: properly assign the parsed data
      if (announcementsDataResponse is List) {
        announcements = announcementsDataResponse.map((announcement) {
          return {
            'title': announcement['title'] ?? 'No Title',
            'description': announcement['description'] ?? 'No Description',
            'priority': announcement['priority']?.toLowerCase() ?? 'low', // Convert to lowercase for priority color matching
            'date': announcement['start_date'] != null 
                ? DateTime.parse(announcement['start_date']).toLocal().toString().split(' ')[0] 
                : 'No Date',
            'id': announcement['_id'] ?? '',
          };
        }).toList();
      } else {
        announcements = [];
      }

      // Create mock banners
      banners = [
        {
          'id': 1,
          'imageUrl': 'https://www.eventrentalutah.com/wp-content/uploads/2014/08/shutterstock_611459207.jpg',
          'title': 'Upcoming Exams',
          'description': 'Prepare for mid-terms starting next week',
        },
        {
          'id': 2,
          'imageUrl': 'https://www.choosebooster.com/hs-fs/hubfs/boosterthon_site_images/blog/assets/unknown_bzPxRe8.jpeg',
          'title': 'School Events',
          'description': 'Annual day celebrations coming soon',
        },
      ];
      
      isLoading = false;
      errorMessage = null;
    });

    // Start banner timer if we have banners
    if (banners.isNotEmpty) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (mounted) {
          _currentBannerIndex = (_currentBannerIndex + 1) % banners.length;
          _bannerController.animateToPage(
            _currentBannerIndex,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  } catch (e) {
    print('Error in _loadData: $e');
    setState(() {
      errorMessage = 'Failed to load data: ${e.toString()}';
      isLoading = false;
      
      // Set default student data when error occurs
      studentData = {
        'full_name': 'Student Name',
        'name': 'Student Name',
        'class': 'Unknown',
        'rollNumber': 'N/A',
        'attendance': '0%',
        'gpa': '0.0',
        'profilePicture': 'https://i.pinimg.com/736x/65/b1/83/65b183088ef17846c895091dcc7ff801.jpg',
      };
      
      announcements = [];
      banners = [];
    });
  }
}

// 4. Add helper methods
IconData _getSubjectIcon(String subjectName) {
  switch (subjectName.toLowerCase()) {
    case 'mathematics':
    case 'mathmatics': // Handle the typo in API
      return Icons.calculate;
    case 'science':
      return Icons.science;
    case 'english':
      return Icons.menu_book;
    case 'history':
      return Icons.public;
    case 'geography':
      return Icons.terrain;
    case 'pe':
    case 'physical education':
      return Icons.fitness_center;
    case 'art':
      return Icons.palette;
    case 'computer science':
    case 'cs':
      return Icons.computer;
    default:
      return Icons.book;
  }
}

Color _getFallbackColor(String subjectName) {
  switch (subjectName.toLowerCase()) {
    case 'mathematics':
    case 'mathmatics':
      return const Color(0xFF5E72EB);
    case 'science':
      return const Color(0xFF2BBBAD);
    case 'english':
      return const Color(0xFFFF6A6A);
    case 'history':
      return const Color(0xFFFDC639);
    case 'geography':
      return const Color(0xFF56CCF2);
    case 'pe':
    case 'physical education':
      return const Color(0xFF11998E);
    case 'art':
      return const Color(0xFFFC5C7D);
    case 'computer science':
    case 'cs':
      return const Color(0xFF43CBFF);
    default:
      return const Color(0xFF9E9E9E);
  }
}

 @override
  void dispose() {
    _tabController.dispose();
    _bannerController.dispose();
    _bannerTimer.cancel();
    super.dispose();
  }
  Future<void> fetchBanners() async {
    // Simulate API call with delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock banner data
    setState(() {
      banners = [
        {
          'id': 1,
          'imageUrl': 'https://www.eventrentalutah.com/wp-content/uploads/2014/08/shutterstock_611459207.jpg',
          'title': 'Upcoming Exams',
          'description': 'Prepare for mid-terms starting May 20th',
        },
        {
          'id': 2,
          'imageUrl': 'https://www.choosebooster.com/hs-fs/hubfs/boosterthon_site_images/blog/assets/unknown_bzPxRe8.jpeg?width=730&height=425&name=unknown_bzPxRe8.jpeg',
          'title': 'School Events',
          'description': 'Annual day celebrations on May 25th',
        },
        {
          'id': 3,
          'imageUrl': 'https://m.media-amazon.com/images/M/MV5BNWVkYzhjOTUtMDA4My00YjJlLWJhZjktZWZlYTgxNTIyYTJiXkEyXkFqcGc@._V1_FMjpg_UX1000_.jpg',
          'title': 'Academic Calendar',
          'description': 'Summer break starts June 15th',
        },
      ];
      isLoading = false;
    });
  }

  void _showMenuBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMenuBottomSheet(),
    );
  }

    Widget _buildMenuBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Menu items grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (item['route'] != null) {
                      Navigator.pushNamed(context, item['route']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item['title']} screen not implemented yet'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 36,
                          color: item['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Quick access section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAccessButton(
                  Icons.calendar_today,
                  'Calendar',
                  Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/calendar'),
                ),
                 _buildQuickAccessButton(
                  Icons.person_3_outlined,
                  'Profile',
                  Colors.red,

                   onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                _buildQuickAccessButton(
                  Icons.notifications,
                  'Notifications',
                  Colors.orange,

                   onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
                 _buildQuickAccessButton(
                  Icons.settings_accessibility_outlined,
                  'Settings',
                  Colors.orange,

                   onTap: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Updated quick access button widget to include onTap
  Widget _buildQuickAccessButton(IconData icon, String label, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          _buildDashboardTab(),
          
          // Classes Tab
          _buildPlaceholderTab('Classes Content Will Appear Here'),
          
          // Profile Tab
          _buildPlaceholderTab('Profile Content Will Appear Here'),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          isLoading = true;
        });
        await fetchBanners();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 150,
            floating: true,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Student Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3E64FF), Color(0xFF5E72EB), Color(0xFF7580ED)],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -20,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.school_rounded,
                          size: 180,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 60,
                      child: Row(
                        children: [
                          Text(
                            'Welcome back,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            studentData['full_name'] ?? 'Student',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, size: 26),
                onPressed: () {},
                tooltip: 'Search',
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 26),
                      onPressed: () {},
                      tooltip: 'Notifications',
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 1,
                            spreadRadius: 0,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {},
                  child: Hero(
                    tag: 'profilePicture',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 0,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: NetworkImage(
                          studentData['profilePicture'] ?? 'https://placeholder.com/user',
                        ),
                        onBackgroundImageError: (_, __) {},
                      ),
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: Container(
                height: 4.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Overview Section
                buildStudentOverview(),
                
                // Banner Slider Section (Separate from announcements)
                buildBannerSlider(),
                
                // Tab Section for Announcements
                buildAnnouncementSection(),
                
                // Subjects Section (4 in one line)
                buildSubjectsSection(),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderTab(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
Widget _buildBottomNavigationBar() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFloatingNavItem(Icons.dashboard_outlined, 'Dashboard', 0),
            _buildFloatingNavItem(Icons.menu_outlined, 'Menu', 1, showMenu: true),
     
          ],
        ),
      ),
    ),
  );
}

Widget _buildFloatingNavItem(IconData icon, String label, int index, {bool showMenu = false}) {
  final isSelected = (showMenu ? _currentIndex == -1 : _currentIndex == index);
  final primaryColor = Theme.of(context).primaryColor;
  final unselectedColor = Colors.grey[400];
  
  return InkWell(
    onTap: () {
      if (showMenu) {
        _showMenuBottomSheet();
      } else {
        setState(() {
          _currentIndex = index;
          _tabController.animateTo(index);
        });
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: isSelected ? BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? primaryColor : unselectedColor,
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
 Widget buildStudentOverview() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3E64FF), Color(0xFF5E72EB)],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.2),
          blurRadius: 15,
          offset: const Offset(0, 5),
        )
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(
                  studentData['profilePicture'] ?? 'https://via.placeholder.com/150'
                ),
                onBackgroundImageError: (_, __) {},
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentData['name'] ?? 'Student Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Class: ${studentData['class'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Roll Number: ${studentData['rollNumber'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Attendance',
                studentData['attendance']?.toString() ?? '0%',
                Icons.calendar_today,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'GPA',
                studentData['gpa']?.toString() ?? '0.0',
                Icons.grade,
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3E64FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'View Profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget buildBannerSlider() {
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : Stack(
              children: [
                PageView.builder(
                  controller: _bannerController,
                  itemCount: banners.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentBannerIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(
                          image: NetworkImage(banner['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner['description'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 12,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      banners.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentBannerIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget buildAnnouncementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final announcement = announcements[index];
              Color priorityColor;
              
              switch (announcement['priority']) {
                case 'high':
                  priorityColor = Colors.red.shade400;
                  break;
                case 'medium':
                  priorityColor = Colors.orange.shade400;
                  break;
                default:
                  priorityColor = Colors.green.shade400;
              }
              
              return Container(
                width: 280,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            announcement['date'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.more_vert,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        announcement['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        announcement['description'],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Read More'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildSubjectsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Subjects',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              return buildSubjectCard(subjects[index]);
            },
          ),
        ],
      ),
    );
  }

// 5. Replace the buildSubjectCard method completely:
Widget buildSubjectCard(Map<String, dynamic> subject) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(subject['image']),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {
                  // Handle image loading error
                },
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Fallback color background (shown when image fails to load)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: subject['fallbackColor'],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  subject['fallbackColor'],
                  subject['fallbackColor'].withOpacity(0.8),
                ],
              ),
            ),
          ),
          
          // Content
          if (subject['announcements'] > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${subject['announcements']}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: subject['fallbackColor'],
                    ),
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with better visibility
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    subject['icon'],
                    size: 28,
                    color: subject['fallbackColor'],
                  ),
                ),
                const SizedBox(height: 10),
                
                // Subject title with better readability
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subject['title'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Progress bar with better contrast
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 4,
                          width: MediaQuery.of(context).size.width / 4 * 0.6 * subject['progress'],
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
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
        ],
      ),
    ),
  );
}
}