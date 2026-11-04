// 所有支持的传感器类型
enum SensorType {
    temperature, // 温度传感器
    humidity, // 湿度传感器
    pressure, // 压力传感器
    carbon_dioxide, // 二氧化碳传感器
    pm25, // pm2.5传感器
    pm10, // pm10传感器
    volatile_organic_compounds, // voc传感器
    noise, // 噪声传感器
    illuminance, // 光传感器
}

extension SensorTypeMeta on SensorType{

    /// 传感器图标容器背景色（ARGB 整型，与 Material 色板对齐）
    int get iconColor {
        switch (this) {
            case SensorType.temperature:    return 0xFFF44336; // Red
            case SensorType.humidity:       return 0xFF2196F3; // Blue
            case SensorType.pressure:       return 0xFF4CAF50; // Green
            case SensorType.carbon_dioxide: return 0xFFFF9800; // Orange
            case SensorType.pm25:           return 0xFF9C27B0; // Purple
            case SensorType.pm10:           return 0xFF673AB7; // DeepPurple
            case SensorType.volatile_organic_compounds:            return 0xFF00BCD4; // Cyan
            case SensorType.noise:          return 0xFF607D8B; // BlueGrey
            case SensorType.illuminance:            return 0xFFFFEB3B; // Yellow
        }
    }

    String get displayName{
        switch(this){
            case SensorType.temperature: return '温度';
            case SensorType.humidity: return '湿度';
            case SensorType.pressure: return '压力';
            case SensorType.carbon_dioxide: return '二氧化碳';
            case SensorType.pm25: return 'pm2.5';
            case SensorType.pm10: return 'pm10';
            case SensorType.volatile_organic_compounds: return 'voc';
            case SensorType.noise: return '噪声';
            case SensorType.illuminance: return '光';
        }
    }

    //单位
    String get unit{
        switch(this){
            case SensorType.temperature:    return '℃';
            case SensorType.humidity:       return '%';
            case SensorType.pressure:  return 'hPa';
            case SensorType.carbon_dioxide:            return 'ppm';
            case SensorType.pm25:           return 'μg/m³';
            case SensorType.pm10:           return 'μg/m³';
            case SensorType.volatile_organic_compounds:            return 'ppb';
            case SensorType.noise:          return 'dB';
            case SensorType.illuminance:            return 'lux';
        }
    }

    //图标（SVG资源路径，配合SvgPicture.asset使用）
    String get icon{
        switch(this){
            case SensorType.temperature:    return 'assets/icons/icon_temperature.svg';
            case SensorType.humidity:       return 'assets/icons/icon_humidity.svg';
            case SensorType.pressure:  return 'assets/icons/icon_pressure.svg';
            case SensorType.carbon_dioxide:            return 'assets/icons/icon_co2.svg';
            case SensorType.pm25:           return 'assets/icons/icon_pm.svg';
            case SensorType.pm10:           return 'assets/icons/icon_pm.svg';
            case SensorType.volatile_organic_compounds:            return 'assets/icons/icon_voc.svg';
            case SensorType.noise:          return 'assets/icons/icon_noise.svg';
            case SensorType.illuminance:            return 'assets/icons/icon_lux.svg';
        }
    }

    int get storageScale {
        switch (this) {
            case SensorType.temperature:
            case SensorType.humidity:
            case SensorType.pressure:
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
            case SensorType.pressure:
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