import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';

/// 历史趋势卡片
///
/// 由外部（DeviceDetailVm）完全控制：
/// - [selectedType] / [selectedRange] 为受控状态，交互通过回调上报；
/// - [isLoading] 控制加载占位，[chartData] 为空时展示空态；
/// - 图表主体为带渐变填充的折线图，附当前 / 最高 / 最低 / 平均统计摘要。
class SensorChartCard extends StatelessWidget {
  final List<SensorType> availableSensors;
  final List<Measurement> chartData;
  final SensorType? selectedType;
  final String selectedRange;
  final bool isLoading;
  final ValueChanged<SensorType>? onSensorTypeChanged;
  final ValueChanged<String>? onTimeRangeChanged;

  const SensorChartCard({
    super.key,
    required this.availableSensors,
    required this.chartData,
    this.selectedType,
    this.selectedRange = '24h',
    this.isLoading = false,
    this.onSensorTypeChanged,
    this.onTimeRangeChanged,
  });

  static const _timeRanges = ['1h', '6h', '24h', '7d'];
  static const double _chartHeight = 220;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final sensor =
        selectedType ??
        (availableSensors.isNotEmpty ? availableSensors.first : null);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(colorScheme, sensor),
          SizedBox(height: 12.h),
          Divider(
            height: 1.h,
            thickness: 1.h,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          SizedBox(height: 12.h),
          if (isLoading)
            _buildLoading(colorScheme, l10n)
          else if (chartData.isEmpty || sensor == null)
            _buildEmpty(colorScheme, l10n)
          else ...[
            _buildChart(colorScheme, sensor),
            SizedBox(height: 12.h),
            _buildSummary(colorScheme, sensor, l10n),
          ],
        ],
      ),
    );
  }

  // ── 工具栏：传感器选择 + 时间范围 ───────────────────────────────
  Widget _buildToolbar(ColorScheme colorScheme, SensorType? sensor) {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<SensorType>(
            value: sensor,
            isExpanded: true,
            underline: const SizedBox(),
            style: TextStyle(
              fontSize: 13.sp,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            icon: Icon(Icons.expand_more, color: colorScheme.onSurfaceVariant),
            items: availableSensors.map((type) {
              return DropdownMenuItem<SensorType>(
                value: type,
                child: Text(
                  '${type.displayName} (${type.unit})',
                  style: TextStyle(fontSize: 13.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onSensorTypeChanged?.call(value);
            },
          ),
        ),
        SizedBox(width: 8.w),
        ..._buildTimeRangeButtons(colorScheme),
      ],
    );
  }

  List<Widget> _buildTimeRangeButtons(ColorScheme colorScheme) {
    return _timeRanges.map((label) {
      final isSelected = label == selectedRange;
      return Padding(
        padding: EdgeInsets.only(left: 4.w),
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: isSelected
                ? colorScheme.primary
                : Colors.transparent,
            foregroundColor: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => onTimeRangeChanged?.call(label),
          child: Text(label, style: TextStyle(fontSize: 12.sp)),
        ),
      );
    }).toList();
  }

  // ── 状态占位 ────────────────────────────────────────────────────
  Widget _buildLoading(ColorScheme colorScheme, AppLocalizations l10n) {
    return SizedBox(
      height: _chartHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28.r,
            height: 28.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            l10n.common_ui_loading,
            style: TextStyle(
              fontSize: 12.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme, AppLocalizations l10n) {
    return SizedBox(
      height: _chartHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 40.r,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.device_detail_no_data,
            style: TextStyle(
              fontSize: 13.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── 图表主体 ────────────────────────────────────────────────────
  Widget _buildChart(ColorScheme colorScheme, SensorType sensor) {
    final color = Color(sensor.iconColor);
    final spots = chartData.asMap().entries.map((entry) {
      final m = entry.value;
      return FlSpot(m.timestamp.toDouble(), m.sensorType.restoreValue(m.value));
    }).toList();

    // X 轴范围（秒级时间戳），单点时外扩 60s，多点时外扩 2%
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final xSpan = (maxX - minX).abs();
    final xPad = xSpan == 0 ? 60.0 : xSpan * 0.02;
    final xMin = minX - xPad;
    final xMax = maxX + xPad;

    // Y 轴范围，平直数据时外扩 ±1
    var minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    var maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (maxY == minY) {
      minY -= 1;
      maxY += 1;
    } else {
      final pad = (maxY - minY) * 0.1;
      minY -= pad;
      maxY += pad;
    }

    final isLongRange = selectedRange == '7d';
    final xInterval = (xSpan == 0 ? 300.0 : xSpan / 4);
    final yInterval = (maxY - minY) / 4;

    return SizedBox(
      height: _chartHeight,
      child: LineChart(
        LineChartData(
          minX: xMin,
          maxX: xMax,
          minY: minY,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outline.withValues(alpha: 0.12),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: yInterval,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    _formatValue(value, sensor),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: xInterval,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    _formatTime(value.toInt(), isLongRange: isLongRange),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(8.r),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => colorScheme.inverseSurface,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final m = chartData[spot.spotIndex];
                return LineTooltipItem(
                  '${m.sensorType.formatValue(m.value)} ${m.sensorType.unit}\n'
                  '${DateFormat('MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(m.timestamp * 1000))}',
                  TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onInverseSurface,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      ),
    );
  }

  // ── 统计摘要：当前 / 最高 / 最低 / 平均 ─────────────────────────
  Widget _buildSummary(
    ColorScheme colorScheme,
    SensorType sensor,
    AppLocalizations l10n,
  ) {
    final values = chartData
        .map((m) => m.sensorType.restoreValue(m.value))
        .toList();
    final current = values.last;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final avgV = values.reduce((a, b) => a + b) / values.length;
    final unit = sensor.unit;

    Widget item(String label, String value) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: 2.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        item(l10n.device_detail_chart_current, _formatValue(current, sensor)),
        item(l10n.device_detail_chart_max, _formatValue(maxV, sensor)),
        item(l10n.device_detail_chart_min, _formatValue(minV, sensor)),
        item(l10n.device_detail_chart_avg, _formatValue(avgV, sensor)),
      ],
    );
  }

  // ── 格式化工具 ──────────────────────────────────────────────────
  static String _formatValue(double value, SensorType sensor) {
    return value.toStringAsFixed(sensor.decimalPlaces);
  }

  static String _formatTime(int timestampSec, {required bool isLongRange}) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000);
    return DateFormat(isLongRange ? 'MM-dd' : 'HH:mm').format(dt);
  }
}
