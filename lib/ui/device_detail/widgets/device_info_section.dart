import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import '../../../l10n/app_localizations.dart';

/// A sensor data card displayed in a 2-column GridView.
///
/// Shows the sensor icon + name, formatted value + unit,
/// and the elapsed time since the last measurement.
/// Tapping the card reports the sensor type via [onTap]
/// (e.g. to link it to the history chart).
class DeviceInfoSection extends StatelessWidget {
  final Measurement item;
  final ValueChanged<SensorType>? onTap;

  const DeviceInfoSection({super.key, required this.item, this.onTap});

  // ── Spacing constants ─────────────────────────────────────────────
  static const double _cardPaddingH = 12.0;
  static const double _cardPaddingV = 8.0;
  static const double _iconNameGap = 6.0;
  static const double _headerToValueGap = 4.0;
  static const double _valueToTimeGap = 4.0;
  static const double _valueUnitGap = 2.0;

  // ── Icon constants ────────────────────────────────────────────────
  static const double _sensorIconSize = 22.0;
  static const double _timeIconSize = 12.0;

  // ── Card styling ──────────────────────────────────────────────────
  static const double _cardBorderRadius = 16.0;
  static const double _iconContainerRadius = 8.0;
  static const double _iconContainerPadding = 6.0;
  static const double _cardMinHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final sensor = item.sensorType;

    final minutesAgo =
        ((DateTime.now().millisecondsSinceEpoch ~/ 1000 - item.timestamp) / 60)
            .toInt()
            .clamp(0, 9999);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius.r),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      color: colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardBorderRadius.r),
        onTap: onTap == null ? null : () => onTap!(item.sensorType),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _cardMinHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _cardPaddingH.w,
              vertical: _cardPaddingV.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Header: icon + sensor name ────────────────────────
                _SensorHeader(sensor: sensor),

                SizedBox(height: _headerToValueGap.h),

                // ── Value + unit ──────────────────────────────────────
                _ValueRow(value: item.formattedValue, unit: sensor.unit),

                SizedBox(height: _valueToTimeGap.h),

                // ── Time since last update ────────────────────────────
                _TimeRow(
                  minutesAgo: minutesAgo,
                  label: l10n.device_screen_minutes_ago,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header row showing the sensor icon badge and display name.
class _SensorHeader extends StatelessWidget {
  final SensorType sensor;

  const _SensorHeader({required this.sensor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = Color(sensor.iconColor);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DeviceInfoSection._iconContainerPadding.w),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(
              DeviceInfoSection._iconContainerRadius.r,
            ),
          ),
          child: SvgPicture.asset(
            sensor.icon,
            width: DeviceInfoSection._sensorIconSize.w,
            height: DeviceInfoSection._sensorIconSize.w,
            colorFilter: ColorFilter.mode(badgeColor, BlendMode.srcIn),
          ),
        ),
        SizedBox(width: DeviceInfoSection._iconNameGap.w),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              sensor.displayName,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Row displaying the formatted measurement value and its unit.
class _ValueRow extends StatelessWidget {
  final String value;
  final String unit;

  const _ValueRow({required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        SizedBox(width: DeviceInfoSection._valueUnitGap.w),
        Text(
          unit,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Bottom row showing a clock icon and "N minutes ago" text.
class _TimeRow extends StatelessWidget {
  final int minutesAgo;
  final String label;

  const _TimeRow({required this.minutesAgo, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Row(
      children: [
        Icon(
          Icons.access_time_rounded,
          size: DeviceInfoSection._timeIconSize.w,
          color: mutedColor,
        ),
        SizedBox(width: 4.w),
        Text(
          '$minutesAgo $label',
          style: TextStyle(fontSize: 11.sp, color: mutedColor),
        ),
      ],
    );
  }
}
