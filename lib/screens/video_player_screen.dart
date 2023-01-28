import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import '../helpers/utils/get_video_info.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String path;
  const VideoPlayerScreen({Key? key, required this.path}) : super(key: key);

  @override
  VideoPlayerScreenState createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FutureBuilder(
          future: getVideoInfo(widget.path),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container();
            } else {
              int height = snapshot.data!.height!;
              int width = snapshot.data!.width!;

              double ratio = width / height;

              return BetterPlayer.file(
                widget.path,
                betterPlayerConfiguration: BetterPlayerConfiguration(
                  aspectRatio: ratio,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
