// 所有支持的传感器类型
enum SensorType {
    temperature, // 温度传感器
    humidity, // 湿度传感器
    atmosPressure, // 压力传感器
    co2, // 二氧化碳传感器
    pm25, // pm2.5传感器
    pm10, // pm10传感器
    voc, // voc传感器
    noise, // 噪声传感器
    lux, // 光传感器
}

extension SensorTypeMeta on SensorType{

    /// 传感器图标容器背景色（ARGB 整型，与 Material 色板对齐）
    int get iconColor {
        switch (this) {
            case SensorType.temperature:    return 0xFFF44336; // Red
            case SensorType.humidity:       return 0xFF2196F3; // Blue
            case SensorType.atmosPressure:  return 0xFF4CAF50; // Green
            case SensorType.co2:            return 0xFFFF9800; // Orange
            case SensorType.pm25:           return 0xFF9C27B0; // Purple
            case SensorType.pm10:           return 0xFF673AB7; // DeepPurple
            case SensorType.voc:            return 0xFF00BCD4; // Cyan
            case SensorType.noise:          return 0xFF607D8B; // BlueGrey
            case SensorType.lux:            return 0xFFFFEB3B; // Yellow
        }
    }

    String get displayName{
        switch(this){
            case SensorType.temperature: return '温度';
            case SensorType.humidity: return '湿度';
            case SensorType.atmosPressure: return '压力';
            case SensorType.co2: return '二氧化碳';
            case SensorType.pm25: return 'pm2.5';
            case SensorType.pm10: return 'pm10';
            case SensorType.voc: return 'voc';
            case SensorType.noise: return '噪声';
            case SensorType.lux: return '光';
        }
    }

    //单位
    String get unit{
        switch(this){
            case SensorType.temperature:    return '℃';
            case SensorType.humidity:       return '%';
            case SensorType.atmosPressure:  return 'hPa';
            case SensorType.co2:            return 'ppm';
            case SensorType.pm25:           return 'μg/m³';
            case SensorType.pm10:           return 'μg/m³';
            case SensorType.voc:            return 'ppb';
            case SensorType.noise:          return 'dB';
            case SensorType.lux:            return 'lux';
        }
    }

    //图标（SVG资源路径，配合SvgPicture.asset使用）
    String get icon{
        switch(this){
            case SensorType.temperature:    return 'assets/icons/icon_temperature.svg';
            case SensorType.humidity:       return 'assets/icons/icon_humidity.svg';
            case SensorType.atmosPressure:  return 'assets/icons/icon_sensor.svg';
            case SensorType.co2:            return 'assets/icons/icon_co2.svg';
            case SensorType.pm25:           return 'assets/icons/icon_pm.svg';
            case SensorType.pm10:           return 'assets/icons/icon_pm.svg';
            case SensorType.voc:            return 'assets/icons/icon_sensor.svg';
            case SensorType.noise:          return 'assets/icons/icon_sensor.svg';
            case SensorType.lux:            return 'assets/icons/icon_lux.svg';
        }
    }

    int get storageScale {
        switch (this) {
            case SensorType.temperature:
            case SensorType.humidity:
            case SensorType.atmosPressure:
            case SensorType.noise:
            return 100;
            default:
              return 1;
        }
    }
    
    //小数位数 and 除10判断
    int get decimalPlaces{
        switch(this){
            case SensorType.temperature:
            case SensorType.humidity:
            case SensorType.atmosPressure:
            case SensorType.noise:
                return 2;
            default:
                return 0;
        }
    }


    //根据原始整数值，格式化为显示字符串
    String formatValue(int value){
        if(decimalPlaces == 2){
            return (value / storageScale).toStringAsFixed(decimalPlaces);
        }
        return value.toString();
    }

    static SensorType fromString(String name){
        return SensorType.values.firstWhere(
            (e) => e.name == name,
            orElse: () => throw ArgumentError('Unknown SensorType: $name'),
        );
    }

    double restoreValue(int value) => value / storageScale;
}