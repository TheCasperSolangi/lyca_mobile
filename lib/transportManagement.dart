import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

// Models
class Transport {
  final String id;
  final String registrationNumber;
  final String schoolCode;
  final String campusCode;
  final String vehicleName;
  final String driver;
  final String driverId;
  final String driverPicture;
  final int pointNumbers;
  final List<RoutePoint> route;
  final int currentPoint;
  final String currentRoute;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transport({
    required this.id,
    required this.registrationNumber,
    required this.schoolCode,
    required this.campusCode,
    required this.vehicleName,
    required this.driver,
    required this.driverId,
    required this.driverPicture,
    required this.pointNumbers,
    required this.route,
    required this.currentPoint,
    required this.currentRoute,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transport.fromJson(Map<String, dynamic> json) {
    return Transport(
      id: json['_id'] ?? '',
      registrationNumber: json['registration_number'] ?? '',
      schoolCode: json['school_code'] ?? '',
      campusCode: json['campus_code'] ?? '',
      vehicleName: json['vehical_name'] ?? '', // Note: API has typo "vehical"
      driver: json['driver'] ?? '',
      driverId: json['driver_id'] ?? '',
      driverPicture: json['driver_picture'] ?? '',
      pointNumbers: json['point_numbers'] ?? 0,
      route: (json['route'] as List<dynamic>?)
          ?.map((item) => RoutePoint.fromJson(item))
          .toList() ?? [],
      currentPoint: json['current_point'] ?? 0,
      currentRoute: json['current_route'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class RoutePoint {
  final String routeName;
  final int routeNumber;

  RoutePoint({
    required this.routeName,
    required this.routeNumber,
  });

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      routeName: json['route_name'] ?? '',
      routeNumber: json['route_number'] ?? 0,
    );
  }
}

// API Service
class TransportApiService {
  static const String baseUrl = 'http://192.168.1.13:5000/api/v2/transport';
  static String? _authToken;
  static String? _schoolCode;
  static String? _campusCode;

  // Initialize and load token from SharedPreferences
  static Future<void> initialize() async {
    await _loadAuthToken();
    await _loadUserData();
  }

  static Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('token'); // Changed from 'auth_token' to 'token'
      print('Auth token loaded: ${_authToken != null ? 'Present' : 'Not found'}');
      if (_authToken != null) {
        print('Token preview: ${_authToken!.substring(0, _authToken!.length > 20 ? 20 : _authToken!.length)}...');
      }
    } catch (e) {
      print('Error loading auth token: $e');
    }
  }

  static Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _schoolCode = prefs.getString('school_code');
      _campusCode = prefs.getString('campus_code');
      print('School code loaded: $_schoolCode');
      print('Campus code loaded: $_campusCode');
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  static Future<void> setAuthToken(String token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token); // Changed from 'auth_token' to 'token'
      print('Auth token saved successfully');
    } catch (e) {
      print('Error saving auth token: $e');
    }
  }

  static Future<void> setUserData({String? schoolCode, String? campusCode}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (schoolCode != null) {
        _schoolCode = schoolCode;
        await prefs.setString('school_code', schoolCode);
        print('School code saved: $schoolCode');
      }
      if (campusCode != null) {
        _campusCode = campusCode;
        await prefs.setString('campus_code', campusCode);
        print('Campus code saved: $campusCode');
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  static Future<void> clearAuthToken() async {
    _authToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token'); // Changed from 'auth_token' to 'token'
      print('Auth token cleared');
    } catch (e) {
      print('Error clearing auth token: $e');
    }
  }

  static Future<void> clearUserData() async {
    _schoolCode = null;
    _campusCode = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('school_code');
      await prefs.remove('campus_code');
      print('User data cleared');
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  static Future<void> clearAllData() async {
    await clearAuthToken();
    await clearUserData();
  }

  static bool get hasValidToken => _authToken != null && _authToken!.isNotEmpty;
  static bool get hasUserData => _schoolCode != null && _campusCode != null;
  
  // Getters for user data
  static String? get schoolCode => _schoolCode;
  static String? get campusCode => _campusCode;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  static Future<Transport?> getTransportById(String id) async {
    await _ensureTokenLoaded();
    
    if (!hasValidToken) {
      throw Exception('No valid authentication token found. Please login again.');
    }

    try {
      print('Making API call to: $baseUrl/$id');
      print('Headers: $_headers');
      
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: _headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Transport.fromJson(data);
      } else if (response.statusCode == 401) {
        await clearAuthToken();
        throw Exception('Authentication expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('Transport not found');
        return null;
      } else {
        throw Exception('Failed to load transport: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching transport: $e');
      rethrow;
    }
  }

  static Future<Transport?> getTransportByRegistration(String registrationNumber) async {
    await _ensureTokenLoaded();
    
    if (!hasValidToken) {
      throw Exception('No valid authentication token found. Please login again.');
    }

    try {
      print('Making API call to: $baseUrl/registration/$registrationNumber');
      print('Headers: $_headers');
      
      final response = await http.get(
        Uri.parse('$baseUrl/registration/$registrationNumber'),
        headers: _headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Transport.fromJson(data);
      } else if (response.statusCode == 401) {
        await clearAuthToken();
        throw Exception('Authentication expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('Transport not found');
        return null;
      } else {
        throw Exception('Failed to load transport: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching transport: $e');
      rethrow;
    }
  }

  static Future<List<Transport>> getTransportsBySchoolAndCampus(
      String schoolCode, String campusCode) async {
    await _ensureTokenLoaded();
    
    if (!hasValidToken) {
      throw Exception('No valid authentication token found. Please login again.');
    }

    try {
      print('Making API call to: $baseUrl/school/$schoolCode/campus/$campusCode');
      print('Headers: $_headers');
      
      final response = await http.get(
        Uri.parse('$baseUrl/school/$schoolCode/campus/$campusCode'),
        headers: _headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Transport.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        await clearAuthToken();
        throw Exception('Authentication expired. Please login again.');
      } else if (response.statusCode == 404) {
        print('No transports found');
        return [];
      } else {
        throw Exception('Failed to load transports: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching transports: $e');
      rethrow;
    }
  }

  static Future<bool> updateCurrentLocation(String id, int currentPoint, String currentRoute) async {
    await _ensureTokenLoaded();
    
    if (!hasValidToken) {
      throw Exception('No valid authentication token found. Please login again.');
    }

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$id/location'),
        headers: _headers,
        body: json.encode({
          'current_point': currentPoint,
          'current_route': currentRoute,
        }),
      );

      if (response.statusCode == 401) {
        await clearAuthToken();
        throw Exception('Authentication expired. Please login again.');
      }

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  // Method to get user's transports automatically using stored school/campus codes
  static Future<List<Transport>> getUserTransports() async {
    await _ensureTokenLoaded();
    
    if (!hasValidToken) {
      throw Exception('No valid authentication token found. Please login again.');
    }

    if (!hasUserData) {
      throw Exception('No school/campus data found. Please complete your profile.');
    }

    return await getTransportsBySchoolAndCampus(_schoolCode!, _campusCode!);
  }

  // Helper method to ensure token is loaded
  static Future<void> _ensureTokenLoaded() async {
    if (_authToken == null) {
      await _loadAuthToken();
    }
    if (_schoolCode == null || _campusCode == null) {
      await _loadUserData();
    }
  }

  // Method to check if user is authenticated and has complete data
  static Future<bool> isAuthenticated() async {
    await _ensureTokenLoaded();
    return hasValidToken;
  }

  static Future<bool> hasCompleteUserData() async {
    await _ensureTokenLoaded();
    return hasValidToken && hasUserData;
  }

  // Method for debugging - get current status
  static Future<String> getTokenStatus() async {
    await _ensureTokenLoaded();
    return hasValidToken ? 'Token present' : 'No token found';
  }

  static Future<Map<String, dynamic>> getDebugInfo() async {
    await _ensureTokenLoaded();
    return {
      'hasToken': hasValidToken,
      'hasUserData': hasUserData,
      'schoolCode': _schoolCode,
      'campusCode': _campusCode,
    };
  }
}

// Color Scheme
class AppColors {
  // Reddish Color Palette
  static const Color primary = Color(0xFFE53E3E);          // Deep Red
  static const Color primaryDark = Color(0xFFC53030);      // Darker Red
  static const Color secondary = Color(0xFFFEB2B2);        // Light Red
  static const Color accent = Color(0xFFFF6B6B);           // Coral Red
  static const Color background = Color(0xFFFFF5F5);       // Very Light Red
  static const Color surface = Color(0xFFFFFFFF);          // White
  static const Color error = Color(0xFFE53E3E);            // Error Red
  static const Color success = Color(0xFF38A169);          // Green
  static const Color warning = Color(0xFFD69E2E);          // Orange
  static const Color textPrimary = Color(0xFF2D3748);      // Dark Gray
  static const Color textSecondary = Color(0xFF718096);    // Medium Gray
  static const Color textLight = Color(0xFFA0AEC0);        // Light Gray
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color darkPrimary = Color(0xFFFF6B6B);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFE2E8F0);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF5F5), Color(0xFFFFFFFF)],
  );
}

class TransportTrackerApp extends StatelessWidget {
  const TransportTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transport Tracker',
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        primaryColor: AppColors.darkPrimary,
        scaffoldBackgroundColor: AppColors.darkBackground,
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.darkPrimary,
          brightness: Brightness.dark,
        ),
        cardTheme: CardTheme(
          color: AppColors.darkSurface,
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      themeMode: ThemeMode.system,
      home: FutureBuilder(
        future: TransportApiService.initialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            );
          }
          return const TransportTrackerScreen(
            enableDebugMode: true,
            useStoredUserData: true,
          );
        },
      ),
    );
  }
}

class TransportTrackerScreen extends StatefulWidget {
  final String? transportId;
  final String? registrationNumber;
  final String? schoolCode;
  final String? campusCode;
  final bool enableDebugMode;
  final bool useStoredUserData;

  const TransportTrackerScreen({
    Key? key,
    this.transportId,
    this.registrationNumber,
    this.schoolCode,
    this.campusCode,
    this.enableDebugMode = false,
    this.useStoredUserData = true,
  }) : super(key: key);

  @override
  _TransportTrackerScreenState createState() => _TransportTrackerScreenState();
}

class _TransportTrackerScreenState extends State<TransportTrackerScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timer;
  Timer? _refreshTimer;
  
  Transport? _transport;
  bool _isLoading = true;
  String? _error;
  int _estimatedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    await TransportApiService.initialize();
    
    if (!TransportApiService.hasValidToken) {
      setState(() {
        _error = 'No authentication token found. Please login to continue.';
        _isLoading = false;
      });
      return;
    }
    
    _loadTransportData();
    _startRefreshTimer();
  }

  void _loadTransportData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.enableDebugMode) {
        print('=== DEBUG MODE ===');
        final debugInfo = await TransportApiService.getDebugInfo();
        print('Transport ID: ${widget.transportId}');
        print('Registration Number: ${widget.registrationNumber}');
        print('Widget School Code: ${widget.schoolCode}');
        print('Widget Campus Code: ${widget.campusCode}');
        print('Use Stored User Data: ${widget.useStoredUserData}');
        print('Stored School Code: ${debugInfo['schoolCode']}');
        print('Stored Campus Code: ${debugInfo['campusCode']}');
        print('Has Token: ${debugInfo['hasToken']}');
        print('Has User Data: ${debugInfo['hasUserData']}');
        print('=================');
      }

      if (!TransportApiService.hasValidToken) {
        setState(() {
          _error = 'Authentication required. Please login to continue.';
          _isLoading = false;
        });
        return;
      }

      Transport? transport;
      
      if (widget.transportId != null && widget.transportId!.isNotEmpty) {
        print('Fetching transport by ID: ${widget.transportId}');
        transport = await TransportApiService.getTransportById(widget.transportId!);
      } else if (widget.registrationNumber != null && widget.registrationNumber!.isNotEmpty) {
        print('Fetching transport by registration: ${widget.registrationNumber}');
        transport = await TransportApiService.getTransportByRegistration(widget.registrationNumber!);
      } else {
        String? schoolCode = widget.schoolCode;
        String? campusCode = widget.campusCode;
        
        if (widget.useStoredUserData) {
          schoolCode = TransportApiService.schoolCode ?? widget.schoolCode;
          campusCode = TransportApiService.campusCode ?? widget.campusCode;
        }
        
        if (schoolCode != null && campusCode != null && 
            schoolCode.isNotEmpty && campusCode.isNotEmpty) {
          print('Fetching transports by school: $schoolCode, campus: $campusCode');
          final transports = await TransportApiService.getTransportsBySchoolAndCampus(
            schoolCode, 
            campusCode
          );
          if (transports.isNotEmpty) {
            final activeTransports = transports.where((t) => t.isActive).toList();
            transport = activeTransports.isNotEmpty ? activeTransports.first : transports.first;
            print('Found ${transports.length} transports (${activeTransports.length} active), using: ${transport.vehicleName}');
          } else {
            print('No transports found for school/campus');
          }
        } else if (widget.useStoredUserData && TransportApiService.hasUserData) {
          print('Fetching user transports using stored school/campus data');
          final transports = await TransportApiService.getUserTransports();
          if (transports.isNotEmpty) {
            final activeTransports = transports.where((t) => t.isActive).toList();
            transport = activeTransports.isNotEmpty ? activeTransports.first : transports.first;
            print('Found ${transports.length} user transports, using: ${transport.vehicleName}');
          }
        } else {
          setState(() {
            _error = 'No transport identifier provided. Please provide transport ID, registration number, or ensure school/campus codes are available.';
            _isLoading = false;
          });
          return;
        }
      }

      if (transport != null && mounted) {
        print('Transport loaded successfully: ${transport.vehicleName}');
        setState(() {
          _transport = transport;
          _estimatedSeconds = _calculateEstimatedTime(transport!);
          _isLoading = false;
        });
        _startTimer();
        _progressController.forward();
      } else if (mounted) {
        setState(() {
          _error = 'Transport not found. Please check the provided information and try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception in _loadTransportData: $e');
      if (mounted) {
        setState(() {
          if (e.toString().contains('Authentication') || e.toString().contains('login')) {
            _error = 'Authentication expired. Please login again.';
          } else if (e.toString().contains('school/campus data')) {
            _error = 'School/campus information not found. Please complete your profile.';
          } else {
            _error = 'Failed to load transport data: ${e.toString().replaceAll('Exception: ', '')}';
          }
          _isLoading = false;
        });
      }
    }
  }

  int _calculateEstimatedTime(Transport transport) {
    if (transport.pointNumbers <= transport.currentPoint) return 0;
    
    int remainingPoints = transport.pointNumbers - transport.currentPoint;
    return remainingPoints * 240;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_estimatedSeconds > 0 && mounted) {
        setState(() {
          _estimatedSeconds--;
        });
      }
    });
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadTransportData();
      }
    });
  }

  String get _formattedTimeRemaining {
    int minutes = _estimatedSeconds ~/ 60;
    int seconds = _estimatedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _formattedETA {
    DateTime now = DateTime.now();
    DateTime eta = now.add(Duration(seconds: _estimatedSeconds));
    return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
  }

  String get _currentLocationName {
    if (_transport == null || _transport!.route.isEmpty) return 'Unknown';
    
    try {
      final currentRoutePoint = _transport!.route.firstWhere(
        (route) => route.routeNumber == _transport!.currentPoint,
      );
      return currentRoutePoint.routeName;
    } catch (e) {
      return _transport!.currentRoute.isNotEmpty ? _transport!.currentRoute : 'Unknown';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refreshTimer?.cancel();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode 
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.darkBackground, AppColors.darkSurface],
              )
            : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _transport == null
                      ? _buildNotFoundState()
                      : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading your transport...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_error != null && _error!.contains('Authentication')) {
                    await _handleReAuthentication();
                  } else {
                    _loadTransportData();
                  }
                },
                icon: Icon(_error != null && _error!.contains('Authentication') 
                    ? Icons.login : Icons.refresh),
                label: Text(_error != null && _error!.contains('Authentication') 
                    ? 'Login Again' : 'Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.textLight.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_bus_filled_outlined,
                  size: 48,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Transport Not Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The requested transport vehicle could not be found. Please check your details and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: () async => _loadTransportData(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildHeroCard(),
            const SizedBox(height: 20),
            _buildETACards(),
            const SizedBox(height: 20),
            _buildJourneyProgress(),
            const SizedBox(height: 20),
            _buildDriverInfo(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Column(
            children: [
              Text(
                'Live Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Real-time updates',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _loadTransportData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _transport!.vehicleName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reg: ${_transport!.registrationNumber}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _transport!.isActive ? _pulseAnimation.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _transport!.isActive 
                            ? Colors.green.withOpacity(0.9)
                            : Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _transport!.isActive ? 'LIVE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Location',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentLocationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildETACards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formattedTimeRemaining,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Time Left',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formattedETA,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ETA',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyProgress() {
    final sortedRoute = List<RoutePoint>.from(_transport!.route)
      ..sort((a, b) => a.routeNumber.compareTo(b.routeNumber));

    double progress = _transport!.currentPoint / _transport!.pointNumbers;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Journey Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_transport!.currentPoint / _transport!.pointNumbers * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Route Points
          SizedBox(
            height: sortedRoute.length * 45.0,
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedRoute.length,
              itemBuilder: (context, index) {
                final routePoint = sortedRoute[index];
                bool isPassed = routePoint.routeNumber < _transport!.currentPoint;
                bool isCurrent = routePoint.routeNumber == _transport!.currentPoint;

                return Container(
                  height: 45,
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPassed
                                  ? AppColors.primary
                                  : isCurrent
                                      ? AppColors.accent
                                      : AppColors.textLight.withOpacity(0.3),
                              border: Border.all(
                                color: isCurrent ? AppColors.accent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isPassed
                                ? const Icon(Icons.check, color: Colors.white, size: 10)
                                : isCurrent
                                    ? Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                          ),
                          if (index < sortedRoute.length - 1)
                            Container(
                              width: 2,
                              height: 29,
                              color: isPassed
                                  ? AppColors.primary
                                  : AppColors.textLight.withOpacity(0.3),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  routePoint.routeName,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: isPassed
                                        ? AppColors.textSecondary
                                        : isCurrent
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.accent.withOpacity(0.2), AppColors.primary.withOpacity(0.1)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseAnimation.value * 0.3 + 0.7,
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: AppColors.accent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'NOW',
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: _transport?.driverPicture.isNotEmpty == true
                  ? Image.network(
                      _transport!.driverPicture,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.secondary.withOpacity(0.3),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.secondary.withOpacity(0.3),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Driver',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _transport!.driver,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${_transport!.driverId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified,
              color: AppColors.success,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.call, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Calling ${_transport!.driver}...'),
                      ],
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              icon: const Icon(Icons.call, size: 20),
              label: const Text('Call Driver', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.share, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Sharing journey details...'),
                      ],
                    ),
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              icon: const Icon(Icons.share, size: 20),
              label: const Text('Share', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleReAuthentication() async {
    await TransportApiService.clearAuthToken();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Authentication Required'),
          content: const Text('Your session has expired. Please login again to continue tracking your transport.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Login', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }
}