import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/dao/device_config_dao.dart';
import 'package:sensor_hub/data/models/device_config.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/utils/app_logger.dart';

import '../../../route/routes.dart';

class DeviceRegistrationFormPage extends StatefulWidget {
  const DeviceRegistrationFormPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DeviceRegistrationFormPageState();
  }
}

class _DeviceRegistrationFormPageState extends State<DeviceRegistrationFormPage> {
  final _formKey = GlobalKey<FormState>();
  // 表单控制器（在 didChangeDependencies 中创建：编辑态需要带初值）
  late final TextEditingController _nameController;
  late final TextEditingController _brokerController;
  late final TextEditingController _portController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _upTopicController;
  late final TextEditingController _downTopicController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _showAdvanced = false;
  //防止重复调用
  bool _isSubmitting = false;

  /// 路由参数：进入页面时解析一次并缓存，不在 build 里重复读取
  ///
  /// 不能放在 initState：ModalRoute.of 是 InheritedWidget 查找，
  /// 在 initState 完成前调用会触发断言。
  ///
  /// 调用方（设备详情页「编辑」）传入的是 DeviceConfig；
  /// 从设备列表直接进入注册时没有参数，此时为 null，按新增处理。
  DeviceConfig? _deviceConfig;
  bool _routeArgsResolved = false;

  /// 是否为编辑已有设备
  bool get _isEditMode => _deviceConfig != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeArgsResolved) return;
    _routeArgsResolved = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    // 容错：只接受 DeviceConfig，其他类型（误传 int / String 等）按新增处理
    final config = args is DeviceConfig && args.configId != null ? args : null;
    _deviceConfig = config;

    _nameController = TextEditingController(text: config?.deviceName ?? '');
    _brokerController = TextEditingController(text: config?.broker ?? '');
    _portController = TextEditingController(text: config?.port.toString() ?? '');
    _clientIdController = TextEditingController(text: config?.clientId ?? '');
    _upTopicController = TextEditingController(text: config?.upTopic ?? '');
    _downTopicController = TextEditingController(text: config?.downTopic ?? '');
    _usernameController = TextEditingController(text: config?.username ?? '');
    _passwordController = TextEditingController(text: config?.password ?? '');
    // 已有 clientId 时展开高级设置，便于确认
    _showAdvanced = config?.clientId.isNotEmpty ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brokerController.dispose();
    _portController.dispose();
    _clientIdController.dispose();
    _upTopicController.dispose();
    _downTopicController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      // AppBar 的配色/标题样式由 AppThemes.appBarTheme 统一提供
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_sharp),
          onPressed: () {
            RouteUtils.pop(context);
          },
        ),
        title: Text(_isEditMode ? "编辑设备" : "注册设备"),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: (){
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 表单标题
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: Text(
                      "设备信息",
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  ),

                  // 名称输入框
                  _buildTextField(
                    controller: _nameController,
                    label: "名称",
                    hint: "请输入设备名称",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "设备名称不能为空";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _brokerController,
                    label: "服务器地址(Broker)",
                    hint: "请输入MQTT服务器地址",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "服务器地址不能为空";
                      }
                      // 简单的URL格式验证
                      if (!value.contains('.') && !value.contains(':')) {
                        return "请输入有效的服务器地址";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.url,
                  ),

                  SizedBox(height: 16.h),

                  // 端口输入框
                  _buildTextField(
                    controller: _portController,
                    label: "端口(Port)",
                    hint: "请输入端口号",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "端口号不能为空";
                      }
                      final port = int.tryParse(value);
                      if (port == null || port < 1 || port > 65535) {
                        return "请输入有效的端口号(1-65535)";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                  ),

                  SizedBox(height: 16.h),
                  // 上传主题输入框
                  _buildTextField(
                    controller: _upTopicController,
                    label: "上行主题(Topic)",
                    hint: "例如 env_monitor/AABBCCDDEEFF/data",
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "上行主题不能为空";
                      }
                      final segments = value.trim().split('/');
                      if (segments.length < 2) {
                        return "主题格式无效，需包含 MAC 地址段（如 env_monitor/AABBCCDDEEFF/data）";
                      }
                      final mac = segments[1];
                      if (!RegExp(r'^[0-9A-Fa-f]{12}$').hasMatch(mac)) {
                        return "主题第二段须为12位MAC地址（如 AABBCCDDEEFF）";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 16.h),
                  // 下行主题输入框
                  _buildTextField(
                    controller: _downTopicController,
                    label: "下行主题(Topic)",
                    hint: "请输入MQTT主题",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "主题不能为空";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 16.h),

                  // 用户名输入框
                  _buildTextField(
                    controller: _usernameController,
                    label: "用户名称",
                    hint: "请输入用户名",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "用户名不能为空";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 16.h),

                  // 密码输入框
                  _buildTextField(
                    controller: _passwordController,
                    label: "密码",
                    hint: "请输入密码",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "密码不能为空";
                      }
                      if (value.length < 6) {
                        return "密码长度至少6位";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                  ),

                  SizedBox(height: 16.h),

                  // 高级设置（可展开）
                  InkWell(
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    borderRadius: BorderRadius.circular(8.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Row(
                        children: [
                          Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more,
                              size: 20.r, color: colorScheme.primary),
                          SizedBox(width: 4.w),
                          Text("高级设置",
                              style: TextStyle(fontSize: 14.sp, color: colorScheme.primary)),
                        ],
                      ),
                    ),
                  ),
                  if (_showAdvanced) ...[
                    SizedBox(height: 16.h),
                    _buildTextField(
                      controller: _clientIdController,
                      label: "客户端ID (Client ID)",
                      hint: "留空则自动生成",
                      validator: (value) => null, // 非必填
                      keyboardType: TextInputType.text,
                    ),
                  ],

                  SizedBox(height: 32.h),

                  // 提交按钮（仅此处监听 DeviceVM.isLoading）
                  _buildSubmitButton(),
                ],
              ),
            ),
          )
        ),
      ),
    );
  }

  /// 提交按钮（仅此处监听 DeviceVM.isLoading，避免表单整体重建）
  ///
  /// 主题统一在方法内部读取，调用处不再传 colorScheme / theme。
  Widget _buildSubmitButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Consumer<DeviceVM>(builder: (context, vm, child) {
      return ElevatedButton(
        onPressed: vm.isLoading
            ? null
            : () {
                if (_formKey.currentState!.validate()) {
                  _submitForm();
                }
              },
        style: ElevatedButton.styleFrom(
          // M3 的 ElevatedButton 默认底色是 surfaceContainerLow，
          // 这里显式指定为主色，做成表单的主操作按钮
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: vm.isLoading
            ? SizedBox(
                width: 24.r,
                height: 24.r,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _submitLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    });
  }

  /// 构建输入框的通用方法
  ///
  /// 主题统一在方法内部读取（单一来源），调用处不再传 colorScheme。
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    required TextInputType keyboardType,
    bool obscureText = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(8.r);
    final outlineBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.outline),
    );
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      style: theme.textTheme.bodyLarge,
    );
  }

  /// 提交按钮文案（编辑态与注册态区分）
  String get _submitLabel => _isEditMode ? "保存修改" : "注册设备";

  /// 提交表单：编辑态更新已有配置，注册态新增设备
  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    _isSubmitting = true;
    try {
      final upTopic = _upTopicController.text.trim();
      final macAddress = upTopic.split('/').length > 1
          ? upTopic.split('/')[1].trim().toUpperCase()
          : '';

      if (_isEditMode) {
        await _saveEdit(macAddress: macAddress, upTopic: upTopic);
      } else {
        await _registerNew(macAddress: macAddress, upTopic: upTopic);
      }
    } finally {
      _isSubmitting = false;
    }
  }

  /// 编辑保存：复用当前配置的 configId / clientId，仅覆盖表单字段
  Future<void> _saveEdit({
    required String macAddress,
    required String upTopic,
  }) async {
    final original = _deviceConfig!;
    // clientId 留空时沿用原值，避免把已连接的设备标识清空
    final clientId = _clientIdController.text.trim().isEmpty
        ? original.clientId
        : _clientIdController.text.trim();

    final updated = DeviceConfig(
      configId: original.configId,
      deviceName: _nameController.text.trim(),
      broker: _brokerController.text.trim(),
      port: int.parse(_portController.text.trim()),
      clientId: clientId,
      upTopic: upTopic,
      downTopic: _downTopicController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      macAddress: macAddress.isEmpty ? original.macAddress : macAddress,
    );

    try {
      await DeviceConfigDao().update(updated);
      if (!mounted) return;
      showToast("设备配置已更新");
      // 回传 true，详情页据此刷新设备名与概览信息
      RouteUtils.popOfData<bool>(context, data: true);
    } catch (e) {
      logE('更新设备配置失败: $e', error: e, tag: 'DeviceRegistrationFormPage');
      if (mounted) showToast('$e');
    }
  }

  /// 新增设备：沿用原有注册流程
  Future<void> _registerNew({
    required String macAddress,
    required String upTopic,
  }) async {
    final deviceVM = context.read<DeviceVM>();
    final res = await deviceVM.addDevice(
      name: _nameController.text.trim(),
      macAddress: macAddress,
      broker: _brokerController.text.trim(),
      port: int.parse(_portController.text.trim()),
      clientId: _clientIdController.text.trim(),
      upTopic: upTopic,
      downTopic: _downTopicController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (res) {
      RouteUtils.pushNamedAndRemoveUntil(context, RoutePath.main);
    } else {
      showToast("注册设备失败");
    }
  }
}