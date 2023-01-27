import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Future<Uint8List> getVidfeoThumbnail(String path) async {
  final uint8list = await VideoThumbnail.thumbnailData(
    video: path,
    imageFormat: ImageFormat.JPEG,
    maxWidth: 128,
    quality: 25,
  );

  return uint8list!;
}
