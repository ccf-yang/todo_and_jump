class Todo {
  const Todo({required this.id, required this.text, this.done = false});

  final int id;
  final String text;
  final bool done;

  Todo copyWith({bool? done}) => Todo(id: id, text: text, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: (json['id'] as num?)?.toInt() ?? 0,
        text: (json['text'] as String?) ?? '',
        done: (json['done'] as bool?) ?? false,
      );
}

/// [handle] 不含前导 @，展示时再补。
class TwitterUser {
  const TwitterUser({required this.id, required this.handle});

  final int id;
  final String handle;

  Map<String, dynamic> toJson() => {'id': id, 'handle': handle};

  factory TwitterUser.fromJson(Map<String, dynamic> json) => TwitterUser(
        id: (json['id'] as num?)?.toInt() ?? 0,
        handle: (json['handle'] as String?) ?? '',
      );
}
