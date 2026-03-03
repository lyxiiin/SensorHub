class NotificationMessage {
  final int? id;
  final int configId;
  final int severity;
  final String sensorName;
  final int sensorType;
  final int value;
  final int datetime;
  NotificationMessage({
    this.id,
    required this.configId,
    required this.severity,
    required this.sensorName,
    required this.sensorType,
    required this.value,
    required this.datetime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'configId': configId,
      'severity': severity,
      'sensorName': sensorName,
      'sensorType': sensorType,
      'value': value,
      'datetime': datetime,
    };
  }

  factory NotificationMessage.fromMap(Map<String, dynamic> map) {
    return NotificationMessage(
      id: map['id'],
      configId: map['configId'],
      severity: map['severity'],
      sensorName: map['sensorName'],
      sensorType: map['sensorType'],
      value: map['value'],
      datetime: map['dateTime'],
    );
  }
}