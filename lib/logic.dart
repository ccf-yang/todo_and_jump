/// 清单页当前展示哪种列表。
enum AppMode { todo, twitter }

final RegExp _notePattern = RegExp(r'^(\d+)(w?)$', caseSensitive: false);
final RegExp _handleLink =
    RegExp(r'(?:twitter\.com|x\.com)/(?:#!/)?@?([A-Za-z0-9_]+)', caseSensitive: false);
final RegExp _plainHandle = RegExp(r'^@?([A-Za-z0-9_]{1,15})$');
final RegExp _validHandle = RegExp(r'^[A-Za-z0-9_]{1,15}$');

/// 解析设置页「备注」。命中 `数字` 且带 `w` 后缀 → 跳转模式；纯数字 → 待办模式；
/// 其余（含空串）返回 null，由调用方决定「不处理」还是「仅保存」。
AppMode? parseNote(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return null;
  final match = _notePattern.firstMatch(input);
  if (match == null) return null;
  final hasSuffix = (match.group(2) ?? '').isNotEmpty;
  return hasSuffix ? AppMode.twitter : AppMode.todo;
}

/// 把导入文本拆成 @handle 列表：按换行/逗号/空格切分，认纯用户名、`@用户名`
/// 以及 twitter/x 主页链接；小写去重、保留首次出现的原始大小写，非法项丢弃。
/// 调用方拿它和已有列表比对，得到「真正新增」的部分。
List<String> parseHandles(String raw) {
  final segments = raw.split(RegExp(r'[\s,;，；、]+'));
  final seen = <String>{};
  final result = <String>[];
  for (final segment in segments) {
    final token = segment.trim();
    if (token.isEmpty) continue;
    final String? handle;
    if (token.contains('twitter.com') || token.contains('x.com')) {
      handle = _handleLink.firstMatch(token)?.group(1);
    } else {
      handle = _plainHandle.firstMatch(token)?.group(1);
    }
    if (handle == null || !_validHandle.hasMatch(handle)) continue;
    if (seen.add(handle.toLowerCase())) result.add(handle);
  }
  return result;
}

/// 多行文本 → 每条非空、去首尾空白的待办。
List<String> splitTodoLines(String raw) => raw
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList();
