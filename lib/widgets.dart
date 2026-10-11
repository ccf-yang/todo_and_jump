import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'theme.dart';

/// iOS 风格的悬浮提示：底部圆角胶囊，两秒自动消失。
void showToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late final OverlayEntry entry;
  Timer? timer;
  entry = OverlayEntry(
    builder: (_) => _ToastOverlay(message: message),
  );
  timer = Timer(const Duration(milliseconds: 2000), () {
    if (entry.mounted) entry.remove();
    timer?.cancel();
  });
  overlay.insert(entry);
}

class _ToastOverlay extends StatelessWidget {
  const _ToastOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 130,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xD6000000),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13.5, letterSpacing: .2),
            ),
          ),
        ),
      ),
    );
  }
}

/// 大标题栏：左标题，右侧可放「+」按钮。
class LargeTitleBar extends StatelessWidget {
  const LargeTitleBar(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -.8,
                color: AppColors.text,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class InsetDivider extends StatelessWidget {
  const InsetDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      height: .5,
      color: AppColors.separator,
    );
  }
}

/// 白色圆角卡片；children 之间自动插入左缩进的分隔线。
class ListCard extends StatelessWidget {
  const ListCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.hMargin),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const InsetDivider(),
            children[i],
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Text('暂无事项', style: TextStyle(fontSize: 15, color: AppColors.secondary)),
    );
  }
}

class AddButton extends StatelessWidget {
  const AddButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: AppColors.chipBg, shape: BoxShape.circle),
        child: const Icon(Icons.add, size: 22, color: AppColors.accent),
      ),
    );
  }
}

class TodoTile extends StatelessWidget {
  const TodoTile({required this.todo, required this.onTap, required this.onLongPress, super.key});

  final Todo todo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return _PressableRow(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          _CheckBox(done: todo.done),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              todo.text,
              style: TextStyle(
                fontSize: 17,
                color: todo.done ? AppColors.placeholder : AppColors.text,
                decoration: todo.done ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  const UserTile({required this.handle, required this.onTap, required this.onLongPress, super.key});

  final String handle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return _PressableRow(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '@$handle',
              style: const TextStyle(fontSize: 17, color: AppColors.text, letterSpacing: .2),
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, size: 15, color: AppColors.placeholder),
        ],
      ),
    );
  }
}

class _PressableRow extends StatelessWidget {
  const _PressableRow({required this.child, required this.onTap, required this.onLongPress});

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.tileMinHeight),
        child: Padding(padding: AppSizes.tilePadding, child: child),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.accent : Colors.transparent,
        border: Border.all(color: done ? AppColors.accent : AppColors.placeholder, width: 1.8),
      ),
      child: done ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
    );
  }
}

/// 设置页的分组卡片容器。
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.hMargin),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const InsetDivider(),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 设置页一行：左标题 + 右灰色值（可选 chevron 与点击）。
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.title,
    this.value,
    this.showChevron = false,
    this.onTap,
    super.key,
  });

  final String title;
  final String? value;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableRow(
      onTap: onTap ?? () {},
      onLongPress: () {},
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, color: AppColors.text))),
          if (value != null)
            Text(value!, style: const TextStyle(fontSize: 16, color: AppColors.secondary)),
          if (showChevron) ...[
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: AppColors.placeholder),
          ],
        ],
      ),
    );
  }
}

/// 底部弹输入框的多行文本弹窗；确认返回文本，取消返回 null。
Future<String?> showInputSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? placeholder,
}) async {
  final controller = TextEditingController();
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 13),
              TextField(
                controller: controller,
                minLines: 5,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: placeholder,
                  filled: true,
                  fillColor: AppColors.fieldBg,
                  contentPadding: const EdgeInsets.all(12),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.separator),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.separator),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    final text = data?.text;
                    if (text != null && text.isNotEmpty && sheetContext.mounted) {
                      controller.text =
                          controller.text.isEmpty ? text : '${controller.text}\n$text';
                      controller.selection =
                          TextSelection.collapsed(offset: controller.text.length);
                    }
                  },
                  icon: const Icon(Icons.paste_rounded, size: 16),
                  label: const Text('粘贴剪贴板', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _SheetButton(
                      label: '取消',
                      ghost: true,
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: _SheetButton(
                      label: confirmLabel,
                      onPressed: () => Navigator.pop(sheetContext, controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  controller.dispose();
  return result;
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.label, required this.onPressed, this.ghost = false});

  final String label;
  final VoidCallback onPressed;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: ghost ? AppColors.scaffold : AppColors.accent,
        foregroundColor: AppColors.accent,
        minimumSize: const Size.fromHeight(46),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        padding: EdgeInsets.zero,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ghost ? AppColors.accent : Colors.white,
        ),
      ),
    );
  }
}

/// 长按删除的系统确认框。
Future<bool> showDeleteConfirm(BuildContext context, {String title = '删除？'}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      actions: [
        CupertinoDialogAction(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('删除'),
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
  return result ?? false;
}
