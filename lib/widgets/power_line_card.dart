// ==========================================
// FILE: lib/widgets/power_line_card.dart
// ==========================================
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/energy_data.dart';

class PowerLineCard extends StatelessWidget {
  final PowerLineData data;

  const PowerLineCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD4F4DD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Current Usage
          _buildMetricRow(
            'Current Usage',
            '${data.currentUsage.toStringAsFixed(2)}A',
            (data.currentUsage / 10.0).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 12),

          // Voltage Usage
          _buildMetricRow(
            'Voltage Usage',
            '${data.voltageUsage.toStringAsFixed(1)}V',
            (data.voltageUsage / 240.0).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 12),

          // Power
          _buildMetricRow(
            'Power',
            '${data.power.toStringAsFixed(1)}W',
            (data.power / 1000.0).clamp(0.0, 1.0),
          ),
          const SizedBox(height: 20),

          // Pie Chart and Legend
          Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: PieChartPainter(usedPercentage: data.usedPercentage),
                ),
              ),
              const SizedBox(width: 30),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(Colors.green[700]!, 'Used'),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.grey[300]!, 'Unused'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: data.isActive ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data.isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, double progress) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}

// Pie Chart Painter
class PieChartPainter extends CustomPainter {
  final double usedPercentage;

  PieChartPainter({required this.usedPercentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw unused portion
    final unusedPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, unusedPaint);

    // Draw used portion
    final usedPaint = Paint()
      ..color = Colors.green[700]!
      ..style = PaintingStyle.fill;

    final sweepAngle = (usedPercentage / 100) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      true,
      usedPaint,
    );

    // Draw percentage text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${usedPercentage.toInt()}%',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}