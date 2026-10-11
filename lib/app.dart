import 'package:flutter/material.dart';

import 'root_shell.dart';
import 'theme.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '待办',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const RootShell(),
    );
  }
}
