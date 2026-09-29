import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:sensor_hub/data/models/device_config.dart';
import 'package:sensor_hub/data/models/device_group.dart';
import 'package:sensor_hub/route/route_utils.dart';
import 'package:sensor_hub/ui/device/view_model/device_vm.dart';
import 'package:sensor_hub/utils/app_logger.dart';

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
  // 表单控制器（在 didChangeDependencies 中创建：编辑态需要带初值）
  late final TextEditingController _nameController;
  late final TextEditingController _brokerController;
  late final TextEditingController _portController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _upTopicController;
  late final TextEditingController _downTopicController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  /// 分组选择器的选中值；null = 未分组。
  ///
  /// 这里可以放心用 null 表示"未分组"，和设备列表页不同：
  /// DropdownButton 把选中值包在 _DropdownRouteResult 里 pop 出来，
  /// 只对"整个结果"判空，所以 value: null 的项被点中时 onChanged(null)
  /// 会正常触发；而 PopupMenuButton 直接对返回值判空，
  /// null 会被当成"用户关掉了菜单"，这就是列表页要用哨兵的原因。
  int? _selectedGroupId;

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

  late DeviceVM viewModel;

  /// 是否为编辑已有设备
  bool get _isEditMode => _deviceConfig != null;
  
  @override
  void initState() {
    super.initState();
    viewModel = context.read<DeviceVM>();
  }

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
    // 编辑态回填分组；新增时保持 null（未分组）
    _selectedGroupId = config?.groupId;
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
    final appText = AppLocalizations.of(context);
    return Scaffold(
      // AppBar 的配色/标题样式由 AppThemes.appBarTheme 统一提供
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            RouteUtils.pop(context);
          },
        ),
        title: Text(_isEditMode
            ? appText.device_form_title_edit
            : appText.device_form_title_register),
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
                      appText.device_form_section_info,
                      style: TextStyle(fontSize: 20.sp),
                    ),
                  ),

                  // 名称输入框
                  _buildTextField(
                    controller: _nameController,
                    label: appText.device_form_name_label,
                    hint: appText.device_form_name_hint,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appText.device_form_name_required;
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 16.h),

                  // 设备分组选择器。
                  // 选项来自 DeviceVM.groups（与设备列表页同一个数据源）；
                  // 包一层 Consumer，保证 initData 异步加载完分组后选项会自动出现。
                  Consumer<DeviceVM>(
                    builder: (context, vm, child) =>
                        _buildGroupDropdown(vm.groups),
                  ),

                  SizedBox(height: 16.h),
                  _buildTextField(
                    controller: _brokerController,
                    label: appText.device_form_broker_label,
                    hint: appText.device_form_broker_hint,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appText.device_form_broker_required;
                      }
                      // 简单的URL格式验证
                      if (!value.contains('.') && !value.contains(':')) {
                        return appText.device_form_broker_invalid;
                      }
                      return null;
                    },
                    keyboardType: TextInputType.url,
                  ),

                  SizedBox(height: 16.h),

                  // 端口输入框
                  _buildTextField(
                    controller: _portController,
                    label: appText.device_form_port_label,
                    hint: appText.device_form_port_hint,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appText.device_form_port_required;
                      }
                      final port = int.tryParse(value);
                      if (port == null || port < 1 || port > 65535) {
                        return appText.device_form_port_invalid;
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                  ),

                  SizedBox(height: 16.h),
                  // 上传主题输入框
                  _buildTextField(
                    controller: _upTopicController,
                    label: appText.device_form_up_topic_label,
                    hint: appText.device_form_up_topic_hint,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return appText.device_form_up_topic_required;
                      }
                      final segments = value.trim().split('/');
                      if (segments.length < 2) {
                        return appText.device_form_up_topic_invalid;
                      }
                      final mac = segments[1];
                      if (!RegExp(r'^[0-9A-Fa-f]{12}$').hasMatch(mac)) {
                        return appText.device_form_up_topic_mac_invalid;
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 16.h),
                  // 下行主题输入框
                  _buildTextField(
                    controller: _downTopicController,
                    label: appText.device_form_down_topic_label,
                    hint: appText.device_form_down_topic_hint,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appText.device_form_down_topic_required;
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 16.h),

                  // 用户名输入框
                  _buildTextField(
                    controller: _usernameController,
                    label: appText.device_form_username_label,
                    hint: appText.device_form_username_hint,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appText.device_form_username_required;
                      }
                      return null;
                    },
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 16.h),

                  // 密码输入框
                  _buildTextField(
                    controller: _passwordController,
                    label: appText.device_form_password_label,
                    hint: appText.device_form_password_hint,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appText.device_form_password_required;
                      }
                      if (value.length < 6) {
                        return appText.device_form_password_too_short;
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
                          Icon(_showAdvanced ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              size: 20.r, color: colorScheme.primary),
                          SizedBox(width: 4.w),
                          Text(appText.device_form_advanced,
                              style: TextStyle(fontSize: 14.sp, color: colorScheme.primary)),
                        ],
                      ),
                    ),
                  ),
                  if (_showAdvanced) ...[
                    SizedBox(height: 16.h),
                    _buildTextField(
                      controller: _clientIdController,
                      label: appText.device_form_client_id_label,
                      hint: appText.device_form_client_id_hint,
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
    final appText = AppLocalizations.of(context);
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
                _isEditMode
                    ? appText.device_form_submit_save
                    : appText.device_form_title_register,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    });
  }

  /// 设备分组选择器
  ///
  /// 用 DropdownButtonFormField 而不是 DropdownMenu：它在 Form 内部，
  /// 需要和 TextFormField 一模一样的外框与内边距，
  /// DropdownMenu 那种"输入框 + 菜单"的混合外观对不齐。
  ///
  /// 分组按 sortOrder 优先、groupId 兜底展示 —— 与设备列表筛选菜单
  /// 的排序规则保持一致（VM.groups 可能被测试塞进乱序数据，显式排一次）。
  Widget _buildGroupDropdown(List<DeviceGroup> groups) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appText = AppLocalizations.of(context);
    final borderRadius = BorderRadius.circular(8.r);
    final outlineBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: colorScheme.outline),
    );

    final sortedGroups = [...groups]..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        if (bySort != 0) return bySort;
        return (a.groupId ?? 0).compareTo(b.groupId ?? 0);
      });

    // 只把"确实存在于选项里"的 id 交给 DropdownButton。
    // 它的 _updateSelectedIndex() 里有
    //   assert(items.where((i) => i.value == value).length == 1)
    // 一旦传入的 id 找不到对应 item（例如分组已被删除），debug 下直接断言失败。
    final selection = sortedGroups.any((g) => g.groupId == _selectedGroupId)
        ? _selectedGroupId
        : null;

    return DropdownButtonFormField<int?>(
      // 用 initialValue：value 从 3.33 起已废弃
      initialValue: selection,
      isExpanded: true,
      icon: Icon(Icons.expand_more_rounded, color: colorScheme.onSurfaceVariant),
      // 由 DropdownButtonFormField 转发给内部 DropdownButton，
      // 保证选中项文案与 _buildTextField 的输入文案同字号
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: appText.device_form_group,
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      ),
      items: [
        // 「未分组」必须做成一个真实的、value 为 null 的 item，而不是只靠 hint：
        // DropdownButton 仅在"没有任何 item 的 value 等于当前值"时才退回 hint。
        // 有这个 item 时，value == null 会被当作选中项正常渲染成"未分组"，
        // 同时 isEmpty 变为 false，浮动 label 也会正确上浮到边框上。
        DropdownMenuItem<int?>(
          value: null,
          child: Text(appText.device_group_ungrouped),
        ),
        ...sortedGroups.map(
          (group) => DropdownMenuItem<int?>(
            value: group.groupId,
            child: Text(group.groupName, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) => setState(() => _selectedGroupId = value),
    );
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
      // groupId 不在表单里，必须沿用原值：
      // toMap() 里会带上 'groupId'，漏传就等于把已有分组清空
      groupId: _selectedGroupId,
    );

    // 跨 async gap 只允许使用已捕获的字符串，不再使用 context
    final l10n = AppLocalizations.of(context);
    try {
      final ok = await viewModel.updateDevice(updated);
      if (!mounted) return;
      if (ok) {
        showToast(l10n.device_form_update_success);
        // 回传 true，详情页据此刷新设备名与概览信息
        RouteUtils.popOfData<bool>(context, data: true);
      } else {
        showToast(l10n.device_form_update_failed);
      }
    } catch (e) {
      logE('更新设备配置失败: $e', error: e, tag: 'DeviceRegistrationFormPage');
      if (mounted) showToast(l10n.common_ui_operation_failed);
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
      groupId: _selectedGroupId,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (res) {
      RouteUtils.pushNamedAndRemoveUntil(context, RoutePath.main);
    } else {
      showToast(l10n.device_form_register_failed);
    }
  }


}