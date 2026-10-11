import 'package:url_launcher/url_launcher.dart';

import 'logic.dart';

/// 结果只用于决定要不要提示兜底文案，不做其它分支。
enum LaunchOutcome { opened, webOpened, failed }

/// 按当前模式跳对应客户端的用户主页；打不开就退到网页，再失败返回 failed。
Future<LaunchOutcome> openSocialUser(AppMode mode, String handle) =>
    mode == AppMode.instagram ? openInstagram(handle) : openTwitter(handle);

/// 优先用 `twitter://user?screen_name=` 直接进对方主页；打不开（多半是没装
/// 客户端）就退到网页，网页也失败则返回 failed 让界面显示链接供复制。
Future<LaunchOutcome> openTwitter(String handle) async {
  final scheme = Uri.parse('twitter://user?screen_name=$handle');
  try {
    if (await canLaunchUrl(scheme) && await launchUrl(scheme)) {
      return LaunchOutcome.opened;
    }
  } on Object {
    // 未声明该 scheme / 无法查询时 canLaunchUrl 会抛，走网页兜底。
  }
  final web = Uri.https('twitter.com', '/$handle');
  try {
    if (await launchUrl(web, mode: LaunchMode.externalApplication)) {
      return LaunchOutcome.webOpened;
    }
  } on Object {
    return LaunchOutcome.failed;
  }
  return LaunchOutcome.failed;
}

/// `instagram://user?username=` 进 IG 主页，兜底网页同 openTwitter。
Future<LaunchOutcome> openInstagram(String handle) async {
  final scheme = Uri.parse('instagram://user?username=$handle');
  try {
    if (await canLaunchUrl(scheme) && await launchUrl(scheme)) {
      return LaunchOutcome.opened;
    }
  } on Object {
    // IG 未安装或未在 LSApplicationQueriesSchemes 声明，走网页兜底。
  }
  final web = Uri.https('instagram.com', '/$handle');
  try {
    if (await launchUrl(web, mode: LaunchMode.externalApplication)) {
      return LaunchOutcome.webOpened;
    }
  } on Object {
    return LaunchOutcome.failed;
  }
  return LaunchOutcome.failed;
}
