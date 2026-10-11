import 'package:url_launcher/url_launcher.dart';

/// 结果只用于决定要不要提示兜底文案，不做其它分支。
enum LaunchOutcome { opened, webOpened, failed }

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
