import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// 通用确认对话框。
///
/// 只负责「询问 → 返回用户决定」这一层 UI：确认后的业务操作、
/// toast、导航全部留在调用方。文案由调用方注入，组件不依赖 VM，
/// 与 _GroupNameDialog 保持同一设计约定（可独立测试）。
///
/// [destructive] 为 true（默认）时确认按钮使用错误色，用于删除等
/// 不可逆操作。返回 true 表示用户确认；取消或点空白关闭返回
/// false / null，调用方用 `confirmed != true` 统一判断。
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = true,
  Key? confirmKey,
  Key? cancelKey,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      // 主题取自 dialogContext：对话框跟随自身路由的上下文，
      // 而不是调用方页面的 context。
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            key: cancelKey,
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel ?? l10n.common_ui_cancel),
          ),
          FilledButton(
            key: confirmKey,
            style: FilledButton.styleFrom(
              backgroundColor:
                  destructive ? colorScheme.error : colorScheme.primary,
              foregroundColor:
                  destructive ? colorScheme.onError : colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}
