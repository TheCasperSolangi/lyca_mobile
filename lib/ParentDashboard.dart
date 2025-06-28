import 'dart:async';
import 'package:flutter/material.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({Key? key}) : super(key: key);

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> with SingleTickerProviderStateMixin {
  // Mock parent data
  final List<Map<String, dynamic>> children = [
    {
      'name': 'Alex Johnson',
      'class': 'Grade 10-A',
      'rollNumber': '2023-1045',
      'attendance': '92%',
      'profilePicture': 'https://i.pinimg.com/736x/65/b1/83/65b183088ef17846c895091dcc7ff801.jpg',
    },
    {
      'name': 'Sarah Johnson',
      'class': 'Grade 8-B',
      'rollNumber': '2023-1046',
      'attendance': '88%',
      'profilePicture': 'https://randomuser.me/api/portraits/girl/68.jpg',
    },
  ];

  // Mock banner data
  List<Map<String, dynamic>> banners = [];
  
  // Mock announcement data
  final List<Map<String, dynamic>> announcements = [
    {
      'id': 1,
      'title': 'Mid-Term Exams Schedule Released',
      'description': 'Check the exam schedule for next week',
      'date': 'May 15, 2025',
      'priority': 'high',
    },
    {
      'id': 2,
      'title': 'Parent-Teacher Meeting',
      'description': 'Scheduled for May 25th at 2 PM',
      'date': 'May 10, 2025',
      'priority': 'medium',
    },
    {
      'id': 3,
      'title': 'School Holiday',
      'description': 'School will remain closed on May 30th',
      'date': 'May 8, 2025',
      'priority': 'low',
    },
  ];

  // Simplified menu items for parent
  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Attendance',
      'icon': Icons.calendar_today,
      'color': const Color(0xFF3E64FF),
      'route': '/attendance'
    },
    {
      'title': 'Exams',
      'icon': Icons.quiz,
      'color': const Color(0xFFFF6A6A),
      'route': '/exams'
    },
    {
      'title': 'Fees',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFF9C27B0),
      'route': '/fees'
    },
    {
      'title': 'Leaves',
      'icon': Icons.people,
      'color': const Color(0xFF43CBFF),
      'route': '/leave'
    },
  ];

  bool isLoading = true;
  late TabController _tabController;
  late PageController _bannerController;
  int _currentBannerIndex = 0;
  late Timer _bannerTimer;
  int _currentIndex = 0;
  int _currentChildIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Only 2 tabs now
    _bannerController = PageController();
    
    // Fetch banners from API (simulated)
    fetchBanners();
    
    // Auto-scroll banner
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (banners.isNotEmpty) {
        _currentBannerIndex = (_currentBannerIndex + 1) % banners.length;
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
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
          'title': 'Parent Events',
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
      height: MediaQuery.of(context).size.height * 0.5, // Smaller height for fewer items
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
                crossAxisCount: 2, // Only 2 columns for fewer items
                childAspectRatio: 1.5, // Wider items
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
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: (item['color'] as Color).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 36,
                          color: item['color'] as Color,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: item['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
          
          // Profile Tab (simplified)
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
            expandedHeight: 120,
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
                child: const Text(
                  'Parent Dashboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    letterSpacing: 0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        // ignore: deprecated_member_use
                        color: Colors.white,
                        offset: Offset(0, 1),
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
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Children Cards (Horizontal Scroll)
                buildChildrenCards(),
                
                // Banner Slider Section
                buildBannerSlider(),
                
                // Announcements Section
                buildAnnouncementSection(),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChildrenCards() {
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentChildIndex = index;
              });
            },
            child: Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                        backgroundImage: NetworkImage(child['profilePicture']),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            child['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Class: ${child['class']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Roll Number: ${child['rollNumber']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildStatItem(
                                'Attendance',
                                child['attendance'],
                                Icons.calendar_today,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
          const SizedBox(width: 5),
          Text(
            '$title: $value',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
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
              _buildFloatingNavItem(Icons.menu_outlined, 'Menu', -1, showMenu: true),
              _buildFloatingNavItem(Icons.person_outlined, 'Profile', 1),
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
}