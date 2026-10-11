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
    // 列表内容会一路延伸到屏幕底部、探到半透明 Tab 栏后面，这里预留出 Tab 栏
    // 的高度再加一点呼吸空间，保证最后一条能完整滚到 Tab 栏上方、不会弹回藏住。
    final tabClearance = 49 + MediaQuery.paddingOf(context).bottom + 16;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.scaffold,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LargeTitleBar('待办', action: _actions(context, ref, mode)),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: tabClearance),
                child: mode == AppMode.todo
                    ? _todoList(context, ref)
                    : _userList(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部右侧操作区：T 模式在「+」左边多一个导出按钮，待办模式只有「+」。
  Widget _actions(BuildContext context, WidgetRef ref, AppMode mode) {
    final add = AddButton(onPressed: () => _onAdd(context, ref, mode));
    if (mode != AppMode.twitter) return add;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExportButton(onPressed: () => _exportUsers(context, ref)),
        const SizedBox(width: 10),
        add,
      ],
    );
  }

  Widget _todoList(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider);
    if (todos.isEmpty) return const Center(child: EmptyState());
    return _card(
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
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
    return _card(
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
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
    );
  }

  /// 白色圆角卡片容器。高度随内容收缩（列表 shrinkWrap），底部留白统一由
  /// build 里的 tabClearance 负责，避免最后一条探到 Tab 栏后面。
  Widget _card({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.hMargin),
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

  /// 把全部用户名（每行一个）复制到剪贴板。
  Future<void> _exportUsers(BuildContext context, WidgetRef ref) async {
    final handles = ref.read(usersProvider).map((e) => e.handle).toList();
    if (handles.isEmpty) {
      showToast(context, '暂无可导出的用户名');
      return;
    }
    await Clipboard.setData(ClipboardData(text: handles.join('\n')));
    if (!context.mounted) return;
    showToast(context, '已导出 ${handles.length} 个用户名到剪贴板');
  }
}
