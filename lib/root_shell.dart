import 'package:flutter/cupertino.dart';

import 'list_page.dart';
import 'settings_page.dart';
import 'theme.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      backgroundColor: AppColors.scaffold,
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: '清单',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: '设置',
          ),
        ],
      ),
      tabBuilder: (context, index) => CupertinoTabView(
        builder: (context) => index == 0 ? const ListPage() : const SettingsPage(),
      ),
    );
  }
}
