class SensorReading {
  final int? id;
  final String configId;
  final String name;
  final int datetime; // Unix timestamp in seconds or milliseconds
  final int temp;     // e.g., 2500 for 25.00°C → stored as integer * 100
  final int humidity; // e.g., 6050 for 60.50% RH
  final int co2;      // ppm

  SensorReading({
    this.id,
    required this.configId,
    required this.name,
    required this.datetime,
    required this.temp,
    required this.humidity,
    required this.co2,
  });

  Map<String, dynamic> toMap() {
    return {
      'config_id': configId,
      'datetime': datetime,
      'temp': temp,
      'humidity': humidity,
      'co2': co2,
      'name': name
    };
  }

  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'],
      configId: map['config_id'],
      datetime: map['datetime'],
      temp: map['temp'],
      humidity: map['humidity'],
      co2: map['co2'],
      name: map['name'],
    );
  }
}