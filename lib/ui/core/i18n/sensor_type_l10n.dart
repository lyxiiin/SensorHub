import 'package:sensor_hub/data/models/sensor_channel.dart';
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
      case SensorType.pressure:
        return l10n.sensor_type_pressure;
      case SensorType.carbon_dioxide:
        return l10n.sensor_type_co2;
      case SensorType.pm25:
        return l10n.sensor_type_pm25;
      case SensorType.pm10:
        return l10n.sensor_type_pm10;
      case SensorType.volatile_organic_compounds:
        return l10n.sensor_type_voc;
      case SensorType.noise:
        return l10n.sensor_type_noise;
      case SensorType.illuminance:
        return l10n.sensor_type_lux;
    }
  }
}

/// (物理量, 通道) 的本地化名称。
///
/// 同一物理量的不同通道（内部 / 外部）有各自的文案；
/// [SensorChannel.primary] 以及不存在通道歧义的物理量回落到
/// [SensorTypeL10n.localizedName]。
extension SensorKeyL10n on SensorKey {
  String localizedName(AppLocalizations l10n) => switch ((type, channel)) {
        (SensorType.temperature, SensorChannel.internal) =>
          l10n.sensor_channel_temperature_internal,
        (SensorType.temperature, SensorChannel.external) =>
          l10n.sensor_channel_temperature_external,
        (SensorType.humidity, SensorChannel.internal) =>
          l10n.sensor_channel_humidity_internal,
        (SensorType.humidity, SensorChannel.external) =>
          l10n.sensor_channel_humidity_external,
        _ => type.localizedName(l10n),
      };
}
