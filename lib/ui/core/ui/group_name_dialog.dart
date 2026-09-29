import 'package:flutter/material.dart';

/// 通用「名称输入」对话框（新建 / 重命名共用），从分组管理页提取而来。
///
/// 查重在对话框内完成（错误就地显示在输入框下方），
/// 不合法时「确定」不关对话框。文案与查重所需数据全部由调用方注入，
/// 组件自身不依赖 VM，保持可独立测试。
///
/// 与 showConfirmDialog 保持同一设计约定：
/// 返回 null 表示用户取消（或点空白关闭），非 null 即为去除首尾空白
/// 后通过校验的名称。
///
/// 内部三个 ValueKey（group-name-field / group-dialog-cancel /
/// group-dialog-confirm）是既有测试（group_management_page_test）的
/// 定位锚点，保持不变。
class GroupNameDialog extends StatefulWidget {
  const GroupNameDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.emptyError,
    required this.duplicateError,
    this.initialName,
    this.existingNames = const <String>{},
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String cancelLabel;
  final String emptyError;
  final String duplicateError;
  final String? initialName;
  final Set<String> existingNames;

  @override
  State<GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<GroupNameDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    // controller 只能在这里释放：dialog 路由完全移除（含退场动画）后
    // State.dispose 才执行，此时 TextField 已不再引用它
    _controller.dispose();
    super.dispose();
  }

  String? _validate() {
    final value = _controller.text.trim();
    if (value.isEmpty) return widget.emptyError;
    if (widget.existingNames.contains(value)) return widget.duplicateError;
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const ValueKey('group-name-field'),
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: _error,
        ),
        // 输入即清错：不要让上一次的错误一直挂在框上
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          key: const ValueKey('group-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          key: const ValueKey('group-dialog-confirm'),
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// 弹出名称输入对话框的便捷入口，返回用户输入的名称；
/// 取消或点空白关闭返回 null。
///
/// 文案与查重集合由调用方注入（与 showConfirmDialog 同一套约定）。
Future<String?> showGroupNameDialog(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  required String cancelLabel,
  required String emptyError,
  required String duplicateError,
  String? initialName,
  Set<String> existingNames = const <String>{},
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => GroupNameDialog(
      title: title,
      hint: hint,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      emptyError: emptyError,
      duplicateError: duplicateError,
      initialName: initialName,
      existingNames: existingNames,
    ),
  );
}
