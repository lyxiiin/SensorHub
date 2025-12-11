import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/ui/core/ui/custom_app_bar.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';

import '../../../l10n/app_localizations.dart';
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
  // 表单控制器
  final _nameController = TextEditingController();
  final _brokerController = TextEditingController();
  final _portController = TextEditingController();
  final _macController = TextEditingController();
  final _topicController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  void dispose() {
    _nameController.dispose();
    _brokerController.dispose();
    _portController.dispose();
    _macController.dispose();
    _topicController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appText = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args = ModalRoute.of(context)?.settings.arguments ?? "未命名设备";

    return Scaffold(
      extendBody: true,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colorScheme.surfaceContainerHigh,
        iconTheme: IconThemeData(
          color: colorScheme.primary,
          size: 20.r
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_sharp),
          onPressed: (){
            RouteUtils.pop(context);
          },
        ),
        title: Text("注册设备",style: TextStyle(fontSize: 20.sp,fontWeight: FontWeight.bold,color: colorScheme.onSurface),),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: (){
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 表单标题
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
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

                  const SizedBox(height: 16),

                  // 服务器地址输入框
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

                  const SizedBox(height: 16),

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

                  const SizedBox(height: 16),
                  // 设备MAC输入框
                  _buildTextField(
                    controller: _macController,
                    label: "设备MAC",
                    hint: "请输入设备MAC地址",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "MAC地址不能为空";
                      }
                      // 简单的MAC地址格式验证 (AA:BB:CC:DD:EE:FF)
                      final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:]){5}([0-9A-Fa-f]{2})$');
                      if (!macRegex.hasMatch(value)) {
                        return "请输入有效的MAC地址格式";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  const SizedBox(height: 16),
                  // 主题输入框
                  _buildTextField(
                    controller: _topicController,
                    label: "主题(Topic)",
                    hint: "请输入MQTT主题",
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "主题不能为空";
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  const SizedBox(height: 16),

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

                  const SizedBox(height: 16),

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

                  const SizedBox(height: 32),

                  // 提交按钮
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _submitForm(args as String);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      "注册设备",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建输入框的通用方法
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

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      style: theme.textTheme.bodyLarge,
    );
  }

  // 提交表单的方法
  Future<void> _submitForm(String sensorType) async {
    final deviceVM = context.read<DeviceVM>();
    final res = await deviceVM.addDevice(
      sensorType: sensorType,
      name: _nameController.text.trim(),
      broker: _brokerController.text.trim(),
      port: int.parse(_portController.text.trim()),
      mac: _macController.text.trim(),
      topic: _topicController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if(res){
      RouteUtils.pushNamedAndRemoveUntil(context,RoutePath.main);
    }else{
      showToast("注册设备失败");
    }
  }
}