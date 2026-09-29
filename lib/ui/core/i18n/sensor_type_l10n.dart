import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/l10n/app_localizations.dart';

/// 传感器类型的本地化名称。
///
/// [SensorTypeMeta.displayName] 是中文兜底文案（仅供日志使用），
/// UI 层展示一律通过本扩展传入当前 locale 的 [AppLocalizations]。
extension SensorTypeL10n on SensorType {
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case SensorType.temperature:
        return l10n.sensor_type_temperature;
      case SensorType.humidity:
        return l10n.sensor_type_humidity;
      case SensorType.atmosPressure:
        return l10n.sensor_type_pressure;
      case SensorType.co2:
        return l10n.sensor_type_co2;
      case SensorType.pm25:
        return l10n.sensor_type_pm25;
      case SensorType.pm10:
        return l10n.sensor_type_pm10;
      case SensorType.voc:
        return l10n.sensor_type_voc;
      case SensorType.noise:
        return l10n.sensor_type_noise;
      case SensorType.lux:
        return l10n.sensor_type_lux;
    }
  }
}
