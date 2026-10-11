import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers.dart';
import 'logic.dart';
import 'theme.dart';
import 'widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void notReady() => showToast(context, '功能开发中');
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const LargeTitleBar('设置'),
            const SettingsGroup(children: [_NoteField()]),
            const SizedBox(height: 22),
            SettingsGroup(
              children: [
                SettingsRow(title: '外观', value: '跟随系统', onTap: notReady),
                SettingsRow(title: '提醒', value: '开启', onTap: notReady),
                SettingsRow(title: '默认清单', value: '清单一', onTap: notReady),
              ],
            ),
            const SizedBox(height: 22),
            SettingsGroup(
              children: [
                SettingsRow(title: 'iCloud 同步', value: '已开启', onTap: notReady),
                const SettingsRow(title: '版本', value: '1.0.0'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 核心开关：在「备注」里输入指令即可切换清单页模式。
class _NoteField extends ConsumerStatefulWidget {
  const _NoteField();

  @override
  ConsumerState<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends ConsumerState<_NoteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commit(_controller.text);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _commit(String raw) async {
    if (_committing) return;
    final value = raw.trim();
    if (value.isEmpty) return;
    _committing = true;
    try {
      final mode = parseNote(value);
      if (mode != null) {
        await ref.read(modeProvider.notifier).set(mode);
        if (!mounted) return;
        _controller.clear();
        _focusNode.unfocus();
      }
      if (!mounted) return;
      showToast(context, '已保存');
    } finally {
      _committing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 整行都可点：光点在右侧文字区之外（如「备注」标签）时也能唤起输入。
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.hasFocus ? null : FocusScope.of(context).requestFocus(_focusNode),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Text('备注', style: TextStyle(fontSize: 17, color: AppColors.text)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 16, color: AppColors.text),
                onChanged: (_) {},
                onSubmitted: _commit,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: '备注',
                  hintStyle: TextStyle(fontSize: 16, color: AppColors.placeholder),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
