class QingPingSensorState {
  final int configId;
  final int usbInsert;
  final int batteryLevel;
  final int signalStrength;
  final int voltage;
  final int networkType;
  final int datetime;
  final int uptime;


  QingPingSensorState({
    required this.configId,
    required this.usbInsert,
    required this.batteryLevel,
    required this.signalStrength,
    required this.voltage,
    required this.networkType,
    required this.datetime,
    required this.uptime,
  });

  Map<String,dynamic> toMap() {
    return {
      'configId': configId,
      'usbInsert': usbInsert,
      'batteryLevel': batteryLevel,
      'signalStrength': signalStrength,
      'voltage': voltage,
      'networkType': networkType,
      'datetime': datetime,
      'uptime': uptime,

    };
  }

  factory QingPingSensorState.fromMap(Map<String, dynamic> map) {
    return QingPingSensorState(
      configId: map['configId'] is int ? map['configId'] : 0,
      usbInsert: map['usbInsert'] is int ? map['usbInsert'] : 0,
      batteryLevel: map['batteryLevel'] is int ? map['batteryLevel'] : 0,
      signalStrength: map['signalStrength'] is int ? map['signalStrength'] : 0,
      voltage: map['voltage'] is int ? map['voltage'] : 0,
      networkType: map['networkType'] is int ? map['networkType'] : 0,
      datetime: map['datetime'] is int ? map['datetime'] : 0,
      uptime: map['uptime'] is int ? map['uptime'] : 0,
    );
  }
}

