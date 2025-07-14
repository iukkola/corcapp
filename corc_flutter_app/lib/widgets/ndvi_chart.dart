import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/ndvi_data.dart';

class NDVIChart extends StatelessWidget {
  final List<NDVIData> ndviData;
  final double height;

  const NDVIChart({
    Key? key,
    required this.ndviData,
    this.height = 300.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (ndviData.isEmpty) {
      return Container(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Ei NDVI-dataa saatavilla',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Satelliittidata päivittyy viikoittain',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NDVI Kehitys',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              _buildLegend(),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: true,
                  horizontalInterval: 0.1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < ndviData.length) {
                          final date = ndviData[value.toInt()].date;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 0.2,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                minX: 0,
                maxX: (ndviData.length - 1).toDouble(),
                minY: -0.2,
                maxY: 1.0,
                lineBarsData: [
                  LineChartBarData(
                    spots: _buildSpots(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.green[600]!,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: _getPointColor(spot.y),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green[100]!.withOpacity(0.3),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    tooltipBorder: BorderSide(color: Colors.grey[300]!),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.spotIndex;
                        final ndvi = ndviData[index];
                        return LineTooltipItem(
                          '${ndvi.date.day}/${ndvi.date.month}/${ndvi.date.year}\n'
                          'NDVI: ${ndvi.ndviValue.toStringAsFixed(3)}\n'
                          'Tila: ${ndvi.healthStatusFinnish}\n'
                          'Biomassa: ${ndvi.biomassEstimate?.toStringAsFixed(1) ?? 'N/A'} kg/ha',
                          TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          _buildStats(),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    return ndviData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.ndviValue);
    }).toList();
  }

  Color _getPointColor(double ndviValue) {
    if (ndviValue >= 0.6) return Colors.green[700]!;
    if (ndviValue >= 0.4) return Colors.green[500]!;
    if (ndviValue >= 0.2) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('Erinomainen', Colors.green[700]!),
        SizedBox(width: 8),
        _buildLegendItem('Hyvä', Colors.green[500]!),
        SizedBox(width: 8),
        _buildLegendItem('Kohtalainen', Colors.orange[600]!),
        SizedBox(width: 8),
        _buildLegendItem('Huono', Colors.red[600]!),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    if (ndviData.isEmpty) return SizedBox();

    final latest = ndviData.last;
    final average = ndviData.map((e) => e.ndviValue).reduce((a, b) => a + b) / ndviData.length;
    final trend = ndviData.length >= 2 ? 
      ndviData.last.ndviValue - ndviData[ndviData.length - 2].ndviValue : 0.0;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Viimeisin', latest.ndviValue.toStringAsFixed(3), 
            latest.healthStatusFinnish, _getPointColor(latest.ndviValue)),
          _buildStatItem('Keskiarvo', average.toStringAsFixed(3), 
            '', Colors.grey[600]!),
          _buildStatItem('Trendi', 
            '${trend >= 0 ? '+' : ''}${trend.toStringAsFixed(3)}',
            trend >= 0 ? 'Paranee' : 'Heikkenee',
            trend >= 0 ? Colors.green[600]! : Colors.red[600]!),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String sublabel, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (sublabel.isNotEmpty) ...[
          SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }
}