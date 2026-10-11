import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers.dart';
import 'logic.dart';
import 'models.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: ListCard(
        children: [
          for (final todo in todos)
            TodoTile(
              todo: todo,
              onTap: () => ref.read(todosProvider.notifier).toggle(todo.id),
              onLongPress: () => _deleteTodo(context, ref, todo),
            ),
        ],
      ),
    );
  }

  Widget _userList(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    if (users.isEmpty) return const Center(child: EmptyState());
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: ListCard(
        children: [
          for (final user in users)
            UserTile(
              handle: user.handle,
              onTap: () => _openUser(context, user.handle),
              onLongPress: () => _deleteUser(context, ref, user),
            ),
        ],
      ),
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

  Future<void> _deleteTodo(BuildContext context, WidgetRef ref, Todo todo) async {
    if (await showDeleteConfirm(context, title: '删除这条待办？')) {
      await ref.read(todosProvider.notifier).remove(todo.id);
    }
  }

  Future<void> _deleteUser(BuildContext context, WidgetRef ref, TwitterUser user) async {
    if (await showDeleteConfirm(context, title: '删除该用户？')) {
      await ref.read(usersProvider.notifier).remove(user.id);
    }
  }

  Future<void> _openUser(BuildContext context, String handle) async {
    final outcome = await openTwitter(handle);
    if (!context.mounted) return;
    switch (outcome) {
      case LaunchOutcome.opened:
        break;
      case LaunchOutcome.webOpened:
        showToast(context, '未找到 Twitter 客户端，已用浏览器打开');
      case LaunchOutcome.failed:
        showToast(context, '无法打开：https://twitter.com/$handle');
    }
  }
}
