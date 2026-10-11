import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic.dart';
import 'models.dart';
import 'repository.dart';

/// main() 里用实例 override，避免每个 controller 各 await 一次 getInstance。
final prefsProvider =
    Provider<PrefsRepository>((ref) => throw StateError('prefsProvider 未 override'));

class ModeController extends Notifier<AppMode> {
  @override
  AppMode build() => ref.read(prefsProvider).loadMode();

  Future<void> set(AppMode mode) async {
    state = mode;
    await ref.read(prefsProvider).saveMode(mode);
  }
}

final modeProvider = NotifierProvider<ModeController, AppMode>(ModeController.new);

class TodosController extends Notifier<List<Todo>> {
  @override
  List<Todo> build() => ref.read(prefsProvider).loadTodos();

  /// 一次把多行文本收成待办，追加到底部；返回新增条数。
  Future<int> addAll(List<String> texts) async {
    var next = [...state];
    var id = _nextId(next);
    var added = 0;
    for (final text in texts) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) continue;
      next.add(Todo(id: id++, text: trimmed));
      added++;
    }
    await _write(next);
    return added;
  }

  Future<void> toggle(int id) async =>
      _write(state.map((e) => e.id == id ? e.copyWith(done: !e.done) : e).toList());

  Future<void> remove(int id) async => _write(state.where((e) => e.id != id).toList());

  Future<void> _write(List<Todo> next) async {
    state = next;
    await ref.read(prefsProvider).saveTodos(next);
  }
}

int _nextId(List<Todo> items) => items.fold<int>(0, (max, e) => e.id > max ? e.id : max) + 1;

final todosProvider = NotifierProvider<TodosController, List<Todo>>(TodosController.new);

class UsersController extends Notifier<List<TwitterUser>> {
  @override
  List<TwitterUser> build() => ref.read(prefsProvider).loadUsers();

  /// 导入一批 handle：跳过已存在的（不区分大小写），只追加新的；返回新增条数。
  Future<int> import(List<String> handles) async {
    final existing = state.map((e) => e.handle.toLowerCase()).toSet();
    var next = [...state];
    var id = _nextUserId(next);
    var added = 0;
    for (final handle in handles) {
      final key = handle.toLowerCase();
      if (existing.contains(key)) continue;
      existing.add(key);
      next.add(TwitterUser(id: id++, handle: handle));
      added++;
    }
    await _write(next);
    return added;
  }

  Future<void> remove(int id) async => _write(state.where((e) => e.id != id).toList());

  Future<void> _write(List<TwitterUser> next) async {
    state = next;
    await ref.read(prefsProvider).saveUsers(next);
  }
}

int _nextUserId(List<TwitterUser> items) =>
    items.fold<int>(0, (max, e) => e.id > max ? e.id : max) + 1;

final usersProvider = NotifierProvider<UsersController, List<TwitterUser>>(UsersController.new);
