class QingPingSensor {
  final int? configId;
  final String deviceId;
  final String serialNumber;
  final int collectionInterval;
  final int uploadInterval;
  final String firmwareVersion;
  final String hardwareVersion;
  final String commModuleVersion;
  final String mcuVersion;
  final String productId;
  final String pmSensorSn;
  final int screenType;
  final int powerType;
  final int wifiSupport;
  final int hasRs485;
  final String probeType;

  QingPingSensor({
    this.configId,
    required this.deviceId,
    required this.serialNumber,
    required this.collectionInterval,
    required this.uploadInterval,
    required this.firmwareVersion,
    required this.hardwareVersion,
    required this.commModuleVersion,
    required this.mcuVersion,
    required this.productId,
    required this.pmSensorSn,
    required this.screenType,
    required this.powerType,
    required this.wifiSupport,
    required this.hasRs485,
    required this.probeType,
  });

  Map<String, dynamic> toMap() {
    return {
      'config_id': configId,
      'device_id': deviceId,
      'serial_number': serialNumber,
      'collection_interval': collectionInterval,
      'upload_interval': uploadInterval,
      'firmware_version': firmwareVersion,
      'hardware_version': hardwareVersion,
      'comm_module_version': commModuleVersion,
      'mcu_version': mcuVersion,
      'product_id': productId,
      'pm_sensor_sn': pmSensorSn,
      'screen_type': screenType,
      'power_type': powerType,
      'wifi_support': wifiSupport,
      'has_rs485': hasRs485,
      'probe_type': probeType,
    };
  }

  factory QingPingSensor.fromMap(Map<String, dynamic> map) {
    return QingPingSensor(
      configId: map['config_id'],
      deviceId: map['device_id'],
      serialNumber: map['serial_number'],
      collectionInterval: map['collection_interval'],
      uploadInterval: map['upload_interval'],
      firmwareVersion: map['firmware_version'],
      hardwareVersion: map['hardware_version'],
      commModuleVersion: map['comm_module_version'],
      mcuVersion: map['mcu_version'],
      productId: map['product_id'],
      pmSensorSn: map['pm_sensor_sn'],
      screenType: map['screen_type'],
      powerType: map['power_type'],
      wifiSupport: map['wifi_support'],
      hasRs485: map['has_rs485'],
      probeType: map['probe_type'],
    );
  }
}