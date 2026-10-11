import 'package:flutter_test/flutter_test.dart';

import 'package:todo/logic.dart';

void main() {
  group('parseNote', () {
    test('2w 进 T 跳转页，3w 进 I 跳转页，纯数字回待办模式', () {
      expect(parseNote('2w'), AppMode.twitter);
      expect(parseNote('3W'), AppMode.instagram);
      expect(parseNote('1'), AppMode.todo);
      expect(parseNote('12'), AppMode.todo);
    });

    test('未认识的数字+w 不处理（返回 null）', () {
      expect(parseNote('0w'), isNull);
      expect(parseNote('4w'), isNull);
    });

    test('前后空白会被忽略', () {
      expect(parseNote('  2w  '), AppMode.twitter);
    });

    test('空串、非数字、缺数字都返回 null（交调用方决定不处理或仅保存）', () {
      expect(parseNote(''), isNull);
      expect(parseNote('   '), isNull);
      expect(parseNote('abc'), isNull);
      expect(parseNote('w'), isNull);
      expect(parseNote('2 w'), isNull);
      expect(parseNote('2w1'), isNull);
    });
  });

  group('parseHandles', () {
    test('用户名、@用户名、主页链接混合，按顺序解析', () {
      expect(
        parseHandles('elonmusk\n@naval\ntwitter.com/paulg'),
        ['elonmusk', 'naval', 'paulg'],
      );
      expect(parseHandles('https://x.com/sama'), ['sama']);
      expect(
        parseHandles('elonmusk, naval, https://twitter.com/paulg/with_replies, @sama'),
        ['elonmusk', 'naval', 'paulg', 'sama'],
      );
      expect(parseHandles('https://twitter.com/#!/jack'), ['jack']);
    });

    test('小写去重，保留首次出现的原始大小写', () {
      expect(parseHandles('ElonMusk elonmusk ELONMUSK'), ['ElonMusk']);
    });

    test('非法用户名被丢弃', () {
      expect(parseHandles(''), isEmpty);
      expect(parseHandles('toolongusername123456'), isEmpty); // >15 位
      expect(parseHandles('bad-name'), isEmpty); // 连字符非法
      expect(parseHandles('a b  c'), ['a', 'b', 'c']);
    });

    test('链接里带路径只取用户名段', () {
      expect(parseHandles('https://twitter.com/intent/follow?screen_name=jack'), ['intent']);
    });

    test('instagram：允许点号、上限 30、认 instagram.com 链接', () {
      expect(
        parseHandles('a.b_c\nhttps://www.instagram.com/some.user/\n@plain_name', instagram: true),
        ['a.b_c', 'some.user', 'plain_name'],
      );
      // 点号在 twitter 规则下非法，在 IG 规则下合法。
      expect(parseHandles('some.user'), isEmpty);
      // IG 链接尾部多余的斜杠/句点会被清掉。
      expect(parseHandles('instagram.com/xx/', instagram: true), ['xx']);
    });
  });

  group('splitTodoLines', () {
    test('按换行拆分并去掉空行与首尾空白', () {
      expect(splitTodoLines('买牛奶\n\n 预约牙医 \n'), ['买牛奶', '预约牙医']);
      expect(splitTodoLines('   '), isEmpty);
    });
  });

  group('reorderList', () {
    test('上移：把末条拖到最前', () {
      expect(reorderList(['a', 'b', 'c'], 2, 0), ['c', 'a', 'b']);
    });

    test('下移到末尾：newIndex 传列表长度', () {
      expect(reorderList(['a', 'b', 'c'], 0, 3), ['b', 'c', 'a']);
    });

    test('往下挪一格（newIndex=oldIndex+1）等于原地不动', () {
      expect(reorderList(['a', 'b', 'c'], 0, 1), ['a', 'b', 'c']);
    });

    test('越界下标安全返回原序', () {
      expect(reorderList(['a', 'b'], 5, 0), ['a', 'b']);
      expect(reorderList(['a', 'b'], -1, 0), ['a', 'b']);
    });
  });
}
