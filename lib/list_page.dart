// 保留 onReorder：onReorderItem 会自动调整 newIndex，而 reorderList 已按旧语义手动
// 处理「下移减一」，两者都用会双重调整。deprecation 仅 info，CI 用 --no-fatal-infos 容忍。
// ignore_for_file: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers.dart';
import 'logic.dart';
import 'theme.dart';
import 'twitter_launcher.dart';
import 'widgets.dart';

class ListPage extends ConsumerWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.scaffold,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LargeTitleBar('待办', action: AddButton(onPressed: () => _onAdd(context, ref, mode))),
            Expanded(child: mode == AppMode.todo ? _todoList(context, ref) : _userList(context, ref)),
          ],
        ),
      ),
    );
  }

  Widget _todoList(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider);
    if (todos.isEmpty) return const Center(child: EmptyState());
    return _card(
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: EdgeInsets.zero,
        itemCount: todos.length,
        onReorder: (from, to) => ref.read(todosProvider.notifier).reorder(from, to),
        itemBuilder: (context, index) {
          final todo = todos[index];
          return ReorderableDelayedDragStartListener(
            key: ValueKey('todo-${todo.id}'),
            index: index,
            child: Dismissible(
              key: ValueKey('dis-${todo.id}'),
              direction: DismissDirection.endToStart,
              background: slidingDeleteBackground(),
              onDismissed: (_) => ref.read(todosProvider.notifier).remove(todo.id),
              child: _row(
                index,
                TodoTile(
                  todo: todo,
                  onTap: () => ref.read(todosProvider.notifier).toggle(todo.id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _userList(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    if (users.isEmpty) return const Center(child: EmptyState());
    return Column(
      children: [
        Expanded(
          child: _card(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: EdgeInsets.zero,
              itemCount: users.length,
              onReorder: (from, to) => ref.read(usersProvider.notifier).reorder(from, to),
              itemBuilder: (context, index) {
                final user = users[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey('user-${user.id}'),
                  index: index,
                  child: Dismissible(
                    key: ValueKey('dis-${user.id}'),
                    direction: DismissDirection.endToStart,
                    background: slidingDeleteBackground(),
                    onDismissed: (_) => ref.read(usersProvider.notifier).remove(user.id),
                    child: _row(
                      index,
                      UserTile(handle: user.handle, onTap: () => _openUser(context, user.handle)),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _ExportBar(handles: users.map((e) => e.handle).toList()),
      ],
    );
  }

  /// 白色圆角卡片容器；底部留白，避免最后一条被 Tab 栏挡住。
  Widget _card({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.hMargin, 0, AppSizes.hMargin, 100),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _row(int index, Widget tile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (index > 0) const InsetDivider(),
        tile,
      ],
    );
  }

  Future<void> _onAdd(BuildContext context, WidgetRef ref, AppMode mode) async {
    if (mode == AppMode.todo) {
      final raw = await showInputSheet(
        context,
        title: '新建待办',
        confirmLabel: '添加',
        placeholder: '每行一条待办',
      );
      if (raw == null || !context.mounted) return;
      final lines = splitTodoLines(raw);
      if (lines.isEmpty) {
        showToast(context, '没有新的内容');
        return;
      }
      final added = await ref.read(todosProvider.notifier).addAll(lines);
      if (!context.mounted) return;
      showToast(context, added == 0 ? '没有新的内容' : '已添加');
    } else {
      final raw = await showInputSheet(
        context,
        title: '导入用户',
        confirmLabel: '导入',
        placeholder: '每行一个用户名或主页链接',
      );
      if (raw == null || !context.mounted) return;
      final handles = parseHandles(raw);
      if (handles.isEmpty) {
        showToast(context, '没有新的内容');
        return;
      }
      final added = await ref.read(usersProvider.notifier).import(handles);
      if (!context.mounted) return;
      showToast(context, added == 0 ? '没有新的内容' : '已导入');
    }
  }

  Future<void> _openUser(BuildContext context, String handle) async {
    final outcome = await openTwitter(handle);
    if (!context.mounted) return;
    switch (outcome) {
      case LaunchOutcome.opened:
        break;
      case LaunchOutcome.webOpened:
        showToast(context, '未找到 T 客户端，已用浏览器打开');
      case LaunchOutcome.failed:
        showToast(context, '无法打开：$handle');
    }
  }
}

/// T 模式列表底部的导出条：把全部用户名（每行一个）复制到剪贴板。
class _ExportBar extends ConsumerWidget {
  const _ExportBar({required this.handles});

  final List<String> handles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.hMargin, 0, AppSizes.hMargin, 16),
      child: GestureDetector(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: handles.join('\n')));
          if (context.mounted) showToast(context, '已导出 ${handles.length} 个用户名');
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
            ],
          ),
          child: const Center(
            child: Text('导出全部用户名', style: TextStyle(fontSize: 16, color: AppColors.accent)),
          ),
        ),
      ),
    );
  }
}
