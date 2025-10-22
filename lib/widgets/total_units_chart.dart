import 'package:flutter/material.dart';
import '../models/energy_data.dart';

class TotalUnitsChart extends StatelessWidget {
  final List<PowerLineData> powerLines;
  const TotalUnitsChart({Key? key, required this.powerLines}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxVoltage = 240.0;
    final totalVoltage =
        powerLines.fold<double>(0, (s, p) => s + p.voltageUsage);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Units',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 20),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ...powerLines.map((line) {
                  final pct = (line.voltageUsage / maxVoltage).clamp(0.0, 1.0);
                  return Column(
                    children: [
                      Text('${(pct * 100).toInt()}%',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Container(
                          width: 50,
                          height: 150 * pct,
                          decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(8))),
                      const SizedBox(height: 8),
                      Text(line.name.replaceAll(' Line', ''),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black87)),
                    ],
                  );
                }).toList(),
                // Total
                Column(
                  children: [
                    Text(
                        '${((totalVoltage / (maxVoltage * powerLines.length)) * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                        width: 50,
                        height: 150 *
                            (totalVoltage / (maxVoltage * powerLines.length))
                                .clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.circular(8))),
                    const SizedBox(height: 8),
                    const Text('Total',
                        style: TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                ),
              ]),
        ],
      ),
    );
  }
}
