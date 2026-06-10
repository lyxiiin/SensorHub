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

    //图标
    //略

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
}