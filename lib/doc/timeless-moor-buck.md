# SensorHub 适配自研环境检测器 - 开发指导

## 一、背景

项目原本为 QingPing 传感器设计，现已删除相关文件。当前需要适配**自研环境检测器**：
- 传输协议：**MQTT**（不变）
- 数据格式：**十六进制字符串**
- 当前支持数据：温度、湿度、CO2（后续会扩展更多类型）

当前项目 MQTT 基础设施完整，但解码器层缺失（代码中有多处 TODO 标记），数据从 MQTT 收到后未被解析和持久化。

---

## 二、当前架构回顾

```
MQTT消息到达
    ↓
DeviceVM._subscribeCallback()  ← 目前只打日志，TODO
    ↓ (缺失) 解码器
SensorData 对象
    ↓ (缺失) 持久化
SensorDataCo2Dao.insert()
    ↓ (缺失) UI更新
DeviceVM.sensorCard 更新 → DeviceScreen 刷新
```

### 关键文件

| 层 | 文件 | 状态 |
|---|---|---|
| MQTT 服务 | `lib/data/services/mqtt_service.dart` | 完整可用 |
| 设备配置模型 | `lib/data/models/device_config.dart` | 完整可用 |
| 传感器数据模型 | `lib/data/models/sensor_data.dart` | 完整可用 |
| 传感器数据子类 | `lib/data/models/sensor_data_subclasses/sensor_data_co2.dart` | 完整可用 |
| 设备配置 DAO | `lib/data/dao/device_config_dao.dart` | 完整可用 |
| 传感器数据 DAO | `lib/data/dao/sensor_data_co2_dao.dart` | 完整可用 |
| MQTT 仓库 | `lib/data/repositories/mqtt_repository.dart` | 完整可用 |
| 设备 VM | `lib/ui/device/view_model/device_vm.dart` | MQTT回调有 TODO |
| 设备注册表单 | `lib/ui/device/widgets/device_registration_form_page.dart` | 遗留 sensorType 参数 |
| 路由 | `lib/route/routes.dart` | 遗留 DeviceAddPage |
| 通知 VM | `lib/ui/notification/view_model/notification_vm.dart` | 仅存桩数据 |
| 解码器 | **不存在** | 需新建 |

---

## 三、开发步骤（按优先级排列）

### 步骤 1：创建解码器抽象层

**目标**：建立可扩展的解码器框架，让后续新传感器类型只需新增解码器实现即可。

**新建目录**：`lib/data/decoders/`

**新建文件 1**：`lib/data/decoders/payload_decoder.dart`

```dart
/// 解码器抽象接口
/// 每种传感器协议实现自己的解码器
abstract class PayloadDecoder {
  /// 解码原始数据为 SensorData 对象
  /// [payload] 原始数据（通常是字节数组）
  /// [configId] 关联的设备配置ID
  /// [timestamp] 数据时间戳（秒）
  SensorData decode(Uint8List payload, int configId, int timestamp);

  /// 返回此解码器支持的传感器类型标识
  String get sensorType;
}
```

**设计要点**：
- `payload` 参数使用 `Uint8List`（字节数组），因为十六进制字符串本质上就是字节数据。在解码前先将 hex 字符串转为 `Uint8List`。
- `sensorType` 用于解码器注册表查找，可以是一个协议标识字符串。
- 方法签名中包含 `configId` 和 `timestamp`，因为解码器不需要关心这些从哪来，只需填充到返回的 `SensorData` 中。

**新建文件 2**：`lib/data/decoders/decoder_registry.dart`

```dart
/// 解码器注册表（单例）
/// 负责管理和查找解码器
class DecoderRegistry {
  static final DecoderRegistry _instance = DecoderRegistry._();
  factory DecoderRegistry() => _instance;
  DecoderRegistry._();

  final Map<String, PayloadDecoder> _decoders = {};

  /// 注册解码器
  void register(PayloadDecoder decoder) {
    _decoders[decoder.sensorType] = decoder;
  }

  /// 根据传感器类型获取解码器
  PayloadDecoder? getDecoder(String sensorType) {
    return _decoders[sensorType];
  }
}
```

**设计要点**：
- 单例模式，应用启动时注册所有解码器。
- `sensorType` 字符串作为 key。建议与 `DeviceConfig` 关联 —— 可以在 `DeviceConfig` 中新增一个 `sensorType` 字段，存储该设备使用哪种解码器。

---

### 步骤 2：实现十六进制协议解码器

**目标**：实现自研环境检测器的具体解码逻辑。

**新建文件**：`lib/data/decoders/environmental_detector_decoder.dart`

```dart
/// 自研环境检测器解码器
/// 解析十六进制字符串 -> SensorData(Co2)
class EnvironmentalDetectorDecoder extends PayloadDecoder {
  @override
  String get sensorType => 'environmental_detector';

  @override
  SensorData decode(Uint8List payload, int configId, int timestamp) {
    // TODO: 根据你的协议文档实现具体的字节解析逻辑
    // 示例结构（你需要替换为实际协议）：
    // Byte 0:   帧头 (如 0xAA)
    // Byte 1-2: 温度 (int16, 单位 0.1°C)
    // Byte 3-4: 湿度 (int16, 单位 0.1%)
    // Byte 5-6: CO2  (int16, 单位 ppm)
    // Byte 7:   校验和

    // 伪代码示例：
    // int temperature = (payload[1] << 8) | payload[2];  // 大端序
    // int humidity    = (payload[3] << 8) | payload[4];
    // int co2         = (payload[5] << 8) | payload[6];

    // return SensorDataCo2(
    //   configId: configId,
    //   datetime: timestamp,
    //   temperature: temperature,
    //   humidity: humidity,
    //   co2: co2,
    // );
  }
}
```

**实现指南**：

1. **将 hex 字符串转为字节数组**（在调用解码器之前做）：
   ```dart
   // 假设收到的 MQTT 消息是 hex 字符串如 "AA0B4C1A2E04D2F7"
   String hexString = "AA0B4C1A2E04D2F7";
   List<int> bytes = [];
   for (int i = 0; i < hexString.length; i += 2) {
     bytes.add(int.parse(hexString.substring(i, i + 2), radix: 16));
   }
   Uint8List payload = Uint8List.fromList(bytes);
   ```

2. **字节序**：确认你的协议是大端序还是小端序。大端序高位在前：`(payload[1] << 8) | payload[2]`。

3. **校验**：如果协议包含校验和/CRC，在解码前先验证数据完整性。校验失败应返回 null 或抛出异常，调用方据此决定是否丢弃该帧。

4. **单位对齐**：现有模型 `SensorData` 中温度和湿度是 `int` 类型，`DeviceInfoCard` 中显示时会除以 10。确保解码后的值与这个约定一致（例如 25.6°C 存为 256）。

**在应用启动时注册**（在 `main.dart` 或 DeviceVM 初始化时）：
```dart
DecoderRegistry().register(EnvironmentalDetectorDecoder());
```

---

### 步骤 3：改造 DeviceConfig 模型（新增 sensorType 字段）

**目标**：让每个设备知道自己使用哪种解码器。

**修改文件**：`lib/data/models/device_config.dart`

- 新增字段：`String sensorType;`
- 更新 `fromMap()` / `toMap()` 包含此字段
- 更新 `DeviceConfigDao` 的建表 SQL（需要在 `SqliteService._onCreate` 或数据库迁移中添加列）

**修改文件**：`lib/data/services/sqlite_service.dart`

- 在 `device_configs` 表的建表 SQL 中添加 `sensorType TEXT NOT NULL DEFAULT 'environmental_detector'`

**修改文件**：`lib/data/repositories/mqtt_repository.dart`

- `insertDevice()` 中创建动态表时，根据 `sensorType` 决定表结构。目前只有 CO2 传感器表，后续可扩展。

---

### 步骤 4：改造 DeviceVM —— 串联解码器

**目标**：将 MQTT 消息回调中的 TODO 替换为实际的解码+持久化+UI更新逻辑。

**修改文件**：`lib/ui/device/view_model/device_vm.dart`

**改造 MQTT 订阅回调**（原文件约第 114 行和第 181 行）：

```dart
void _onMessageReceived(String deviceName, String topic, Uint8List payload) {
  // 1. 将 hex 字符串转字节（如果 payload 是 String，先转换）
  // 2. 查找该设备对应的解码器类型
  // 3. 调用 DecoderRegistry().getDecoder(sensorType)?.decode()
  // 4. 将解码后的 SensorData 存入 sensorCard
  // 5. 调用 SensorDataCo2Dao.insert() 持久化
  // 6. 调用 notifyListeners() 刷新 UI
}
```

**具体改造点**：

1. **`connectDeviceToMqtt` 方法**：订阅回调中收到消息后：
   ```dart
   // 在订阅回调中
   final decoder = DecoderRegistry().getDecoder(deviceConfig.sensorType);
   if (decoder == null) return;
   
   final sensorData = decoder.decode(payload, deviceConfig.configId!, timestamp);
   
   // 持久化
   final tableName = '${deviceConfig.clientId}_${deviceConfig.configId}';
   await SensorDataCo2Dao.instance.insert(tableName, sensorData as SensorDataCo2);
   
   // 更新 UI
   sensorCard[deviceName] = [sensorData, ...?sensorCard[deviceName]];
   notifyListeners();
   ```

2. **`addDevice` 方法**：添加设备时把 `sensorType` 存入 `DeviceConfig`。

3. **`connectAllSavedDevices` 方法**：初始化时已加载历史数据到 `sensorCard`，新数据到达时追加即可。

---

### 步骤 5：清理遗留代码

**修改文件**：`lib/ui/device/widgets/device_registration_form_page.dart`

- 删除 `sensorType` 参数（当前从 `ModalRoute.of(context)?.settings.arguments` 获取）
- 或者改为内部默认值 `'environmental_detector'`，以后可加下拉选择

**修改文件**：`lib/route/routes.dart`

- 删除 `RoutePath.deviceAdd` 常量（对应文件已删除）
- 删除 `DeviceAddPage` 的 case（如果 `generateRoute` 中有的话）

**检查并删除其他 qing_ping 引用**：
- 全局搜索 `qing_ping`、`qingping`（大小写不敏感），确保无残留引用
- 检查 `pubspec.yaml` 中是否有 qing_ping 相关依赖

---

### 步骤 6：改造通知系统

**目标**：从真实传感器数据生成通知，替代桩数据。

**修改文件**：`lib/ui/notification/view_model/notification_vm.dart`

**设计思路**：

1. 在 `DeviceVM` 解码数据后，检查是否超过阈值：
   ```dart
   void _checkThresholds(SensorDataCo2 data) {
     if (data.temperature > 400) { // 40.0°C
       _generateNotification(data, 'temperature', data.temperature);
     }
     if (data.co2 > 1500) { // 1500ppm
       _generateNotification(data, 'co2', data.co2);
     }
   }
   ```

2. 通知生成后存入 `NotificationMessageDao` 并通知 `NotificationVM` 更新。

3. **跨 ViewModel 通信方案**（二选一）：
   - **方案 A（简单）**：将 `NotificationVM` 提升到 `app.dart` 的 `MultiProvider` 中作为全局 Provider，`DeviceVM` 通过 `context.read<NotificationVM>()` 调用。
   - **方案 B（解耦）**：使用事件总线（如 `EventBus` 库或自定义 `StreamController`），`DeviceVM` 发布事件，`NotificationVM` 监听。

4. 在 `DeviceInfoCard` 中已有的 `labelMap`/`labelUnitMap` 和 `NotificationScreen` 中的 `sensorType`/`sensorTypeUnit` 映射表已经覆盖了温度、湿度、CO2 类型，可直接复用。

---

### 步骤 7：扩展数据模型（为未来更多传感器类型做准备）

**现状**：`SensorDataCo2` 继承 `SensorData`，表结构固定为 (config_id, datetime, temperature, humidity, co2)。

**扩展思路**（当需要添加新数据类型如 PM2.5、VOC 时）：

- **方案 A（子类继承）**：创建 `SensorDataPm25 extends SensorData`，新增 `pm25` 字段。对应创建 `SensorDataPm25Dao` 管理新表。多个子类的表结构不同。
  - 优点：类型安全，每种传感器有独立表
  - 缺点：每种新传感器需要新建 DAO

- **方案 B（JSON 灵活字段）**：在 `SensorData` 中新增 `Map<String, dynamic> extraData`，所有非通用字段存入此 Map，序列化为 JSON 存储。
  - 优点：一个模型通吃所有传感器，无需新建 DAO
  - 缺点：丢失类型安全，查询不便

**推荐**：当前阶段用方案 A（已有 `SensorDataCo2`），因为传感器类型有限。如果未来传感器类型超过 5 种且每个都有独特字段，再考虑迁移到方案 B。

---

## 四、数据流总览（改造后）

```
MQTT 消息到达 (hex 字符串)
    ↓
MqttService._onMessage (原始字节)
    ↓
DeviceVM._onMessageReceived()
    ├─ hex字符串 → Uint8List
    ├─ DecoderRegistry.get(sensorType).decode(bytes) → SensorDataCo2
    ├─ 阈值检查 → 超标则生成 NotificationMessage
    │   └─ NotificationMessageDao.insert()
    │   └─ NotificationVM 更新
    ├─ SensorDataCo2Dao.insert(tableName, data)  // 持久化
    └─ sensorCard[deviceName].add(data)
        └─ notifyListeners()
            └─ DeviceScreen 刷新
```

---

## 五、文件变更清单

| 操作 | 文件 |
|---|---|
| **新建** | `lib/data/decoders/payload_decoder.dart` |
| **新建** | `lib/data/decoders/decoder_registry.dart` |
| **新建** | `lib/data/decoders/environmental_detector_decoder.dart` |
| **修改** | `lib/data/models/device_config.dart` - 新增 sensorType 字段 |
| **修改** | `lib/data/services/sqlite_service.dart` - device_configs 表加 sensorType 列 |
| **修改** | `lib/data/repositories/mqtt_repository.dart` - insertDevice 传递 sensorType |
| **修改** | `lib/ui/device/view_model/device_vm.dart` - 串联解码器 |
| **修改** | `lib/ui/device/widgets/device_registration_form_page.dart` - 清理 sensorType 参数 |
| **修改** | `lib/route/routes.dart` - 删除 DeviceAddPage 路由 |
| **修改** | `lib/ui/notification/view_model/notification_vm.dart` - 接入真实数据 |
| **可能需要修改** | `lib/ui/main/widgets/app.dart` - 提升 NotificationVM 为全局 Provider |

---

## 六、验证方式

完成开发后，按以下步骤验证：

1. **注册设备**：在应用中通过注册表单添加你的环境检测器（填写 MQTT broker 地址、端口、topic 等）
2. **发送测试数据**：使用 MQTT 客户端工具（如 MQTTX）向对应 topic 发送模拟的十六进制数据帧
3. **检查 UI**：设备卡片是否实时显示解码后的温度、湿度、CO2 数值
4. **检查持久化**：关闭应用重新打开，历史数据是否仍然显示
5. **检查通知**：发送超过阈值的数据，通知页面是否生成告警
6. **单元测试**（可选但推荐）：为 `EnvironmentalDetectorDecoder` 编写解码正确性的单元测试
