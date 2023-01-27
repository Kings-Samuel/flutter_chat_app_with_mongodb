import 'package:flutter_video_info/flutter_video_info.dart';

Future<VideoData> getVideoInfo(String path) async {
  final videoInfo = FlutterVideoInfo();

  VideoData? info = await videoInfo.getVideoInfo(path);

  return info!;
}
