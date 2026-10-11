/// 清单页当前展示哪种列表。
enum AppMode { todo, twitter, instagram }

/// 该模式是否是「社交用户跳转页」（T / I 共用同一套增删改导入导出逻辑）。
bool isSocialMode(AppMode mode) => mode != AppMode.todo;

final RegExp _notePattern = RegExp(r'^(\d+)(w?)$', caseSensitive: false);
final RegExp _handleLink =
    RegExp(r'(?:twitter\.com|x\.com)/(?:#!/)?@?([A-Za-z0-9_]+)', caseSensitive: false);
final RegExp _plainHandle = RegExp(r'^@?([A-Za-z0-9_]{1,15})$');
final RegExp _validHandle = RegExp(r'^[A-Za-z0-9_]{1,15}$');

final RegExp _igLink = RegExp(r'instagram\.com/(?:p|reel|explore|stories|tv)/@?([A-Za-z0-9._]+)',
    caseSensitive: false);
final RegExp _igProfileLink = RegExp(r'instagram\.com/@?([A-Za-z0-9._]+)', caseSensitive: false);
final RegExp _igPlainHandle = RegExp(r'^@?([A-Za-z0-9._]{1,30})$');
final RegExp _igValidHandle = RegExp(r'^[A-Za-z0-9._]{1,30}$');

/// 解析设置页「备注」。`数字` + `w` 后缀按数字选平台（2→T，3→I）；纯数字 → 待办模式；
/// 其余（含空串、未认识的数字+w）返回 null，由调用方决定「不处理」还是「仅保存」。
AppMode? parseNote(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return null;
  final match = _notePattern.firstMatch(input);
  if (match == null) return null;
  if ((match.group(2) ?? '').isEmpty) return AppMode.todo;
  switch (match.group(1)) {
    case '2':
      return AppMode.twitter;
    case '3':
      return AppMode.instagram;
    default:
      return null;
  }
}

/// 把导入文本拆成 @handle 列表：按换行/逗号/空格切分，认纯用户名、`@用户名`
/// 以及对应平台的主页链接；小写去重、保留首次出现的原始大小写，非法项丢弃。
/// [instagram] 为真时按 IG 规则（允许点号、上限 30、认 instagram.com）。
/// 调用方拿它和已有列表比对，得到「真正新增」的部分。
List<String> parseHandles(String raw, {bool instagram = false}) {
  final segments = raw.split(RegExp(r'[\s,;，；、]+'));
  final seen = <String>{};
  final result = <String>[];
  for (final segment in segments) {
    final token = segment.trim();
    if (token.isEmpty) continue;
    final String? handle;
    if (instagram) {
      if (token.contains('instagram.com')) {
        handle = _igLink.firstMatch(token)?.group(1) ?? _igProfileLink.firstMatch(token)?.group(1);
      } else {
        handle = _igPlainHandle.firstMatch(token)?.group(1);
      }
      final cleaned = handle?.replaceAll(RegExp(r'[.?/]+$'), '');
      if (cleaned == null || !_igValidHandle.hasMatch(cleaned)) continue;
      if (seen.add(cleaned.toLowerCase())) result.add(cleaned);
    } else {
      if (token.contains('twitter.com') || token.contains('x.com')) {
        handle = _handleLink.firstMatch(token)?.group(1);
      } else {
        handle = _plainHandle.firstMatch(token)?.group(1);
      }
      if (handle == null || !_validHandle.hasMatch(handle)) continue;
      if (seen.add(handle.toLowerCase())) result.add(handle);
    }
  }
  return result;
}

/// 多行文本 → 每条非空、去首尾空白的待办。
List<String> splitTodoLines(String raw) => raw
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList();

/// 按 ReorderableListView 的索引语义重排：`newIndex` 是「移除 oldIndex 之前」的下标，
/// 所以向下移动时要先减一。越界与非法下标都安全返回原序。
List<T> reorderList<T>(List<T> items, int oldIndex, int newIndex) {
  final result = [...items];
  if (oldIndex < 0 || oldIndex >= result.length) return result;
  var target = newIndex;
  final moved = result.removeAt(oldIndex);
  if (target > oldIndex) target -= 1;
  target = target.clamp(0, result.length);
  result.insert(target, moved);
  return result;
}
