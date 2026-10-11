import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'logic.dart';
import 'models.dart';

/// 清单模式、待办、用户列表都各自存一条 JSON（需求 §5.2）：改一次存一次，
/// 启动时读回来恢复模式与列表。
class PrefsRepository {
  PrefsRepository(this._prefs);

  static const _modeKey = 'todo.mode';
  static const _todosKey = 'todo.todos';
  static const _usersKey = 'todo.users';

  final SharedPreferences _prefs;

  static Future<PrefsRepository> open() async =>
      PrefsRepository(await SharedPreferences.getInstance());

  AppMode loadMode() =>
      _prefs.getString(_modeKey) == AppMode.twitter.name ? AppMode.twitter : AppMode.todo;

  Future<void> saveMode(AppMode mode) => _prefs.setString(_modeKey, mode.name);

  List<Todo> loadTodos() => _decodeList(_prefs.getString(_todosKey), Todo.fromJson);

  Future<void> saveTodos(List<Todo> todos) => _prefs.setString(
        _todosKey,
        jsonEncode(todos.map((e) => e.toJson()).toList()),
      );

  List<TwitterUser> loadUsers() => _decodeList(_prefs.getString(_usersKey), TwitterUser.fromJson);

  Future<void> saveUsers(List<TwitterUser> users) => _prefs.setString(
        _usersKey,
        jsonEncode(users.map((e) => e.toJson()).toList()),
      );

  List<T> _decodeList<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } on Object {
      return [];
    }
  }
}
