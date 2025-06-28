import 'package:flutter/material.dart';
import 'dart:math' as math;

class StressGaugeWidget extends StatefulWidget {
  final double currentStressLevel; // Value between 0-100
  final List<double> weeklyStressData; // Optional: for trend indicator

  const StressGaugeWidget({
    Key? key,
    this.currentStressLevel = 65.0,
    this.weeklyStressData = const [45, 60, 55, 70, 65, 50, 65],
  }) : super(key: key);

  @override
  _StressGaugeWidgetState createState() => _StressGaugeWidgetState();
}

class _StressGaugeWidgetState extends State<StressGaugeWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.currentStressLevel,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStressColor(double level) {
    if (level <= 25) return Colors.green;
    if (level <= 50) return Colors.yellow[700]!;
    if (level <= 75) return Colors.orange;
    return Colors.red;
  }

  String _getStressLabel(double level) {
    if (level <= 25) return 'Low';
    if (level <= 50) return 'Moderate';
    if (level <= 75) return 'High';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed, color: Colors.orange[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Stress Level Monitor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Main Gauge
          Container(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Arc
                CustomPaint(
                  size: const Size(200, 200),
                  painter: GaugeBackgroundPainter(),
                ),
                
                // Animated Stress Arc
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(200, 200),
                      painter: StressArcPainter(
                        stressLevel: _animation.value,
                        color: _getStressColor(_animation.value),
                      ),
                    );
                  },
                ),
                
                // Center Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Text(
                          '${_animation.value.toInt()}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _getStressColor(_animation.value),
                          ),
                        );
                      },
                    ),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Text(
                          _getStressLabel(_animation.value),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Needle
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: ((_animation.value / 100) * math.pi) - (math.pi / 2),
                      child: Container(
                        width: 4,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3748),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        margin: const EdgeInsets.only(bottom: 70),
                      ),
                    );
                  },
                ),
                
                // Center Dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3748),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Scale Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScaleLabel('0', Colors.green),
              _buildScaleLabel('25', Colors.yellow[700]!),
              _buildScaleLabel('50', Colors.orange),
              _buildScaleLabel('75', Colors.red),
              _buildScaleLabel('100', Colors.red[800]!),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Weekly Trend Mini Chart
          Container(
            height: 40,
            child: Row(
              children: [
                Icon(Icons.trending_up, 
                     color: Colors.grey[600], 
                     size: 16),
                const SizedBox(width: 8),
                Text(
                  '7-Day Trend',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 20,
                    child: Row(
                      children: widget.weeklyStressData.map((level) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: _getStressColor(level).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleLabel(String text, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Gauge Background
class GaugeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    
    // Draw background arc (semicircle)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start from left
      math.pi, // Draw semicircle
      false,
      paint,
    );
    
    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (int i = 0; i <= 10; i++) {
      final angle = math.pi + (i * math.pi / 10);
      final startRadius = radius - 10;
      final endRadius = radius + 5;
      
      final startX = center.dx + startRadius * math.cos(angle);
      final startY = center.dy + startRadius * math.sin(angle);
      final endX = center.dx + endRadius * math.cos(angle);
      final endY = center.dy + endRadius * math.sin(angle);
      
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        tickPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Custom Painter for Stress Arc
class StressArcPainter extends CustomPainter {
  final double stressLevel;
  final Color color;
  
  StressArcPainter({required this.stressLevel, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    
    // Calculate sweep angle based on stress level
    final sweepAngle = (stressLevel / 100) * math.pi;
    
    // Draw stress level arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // Start from left
      sweepAngle, // Sweep based on stress level
      false,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(StressArcPainter oldDelegate) {
    return oldDelegate.stressLevel != stressLevel || oldDelegate.color != color;
  }
}