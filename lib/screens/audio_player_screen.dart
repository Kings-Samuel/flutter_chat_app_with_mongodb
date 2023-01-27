import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../helpers/utils/color_palette.dart';
import '../helpers/utils/format_duration.dart';
import '../helpers/widgets/custom_texts.dart';

class AudioPlayerScreen extends StatefulWidget {
  final File? audioFile;
  final Uint8List? audioBytes;
  final String? title;
  const AudioPlayerScreen({Key? key, this.audioFile, this.audioBytes, this.title}) : super(key: key);

  @override
  AudioPlayerScreenState createState() => AudioPlayerScreenState();
}

class AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  File? _audioFile;
  Uint8List? _audioBytes;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioFile = widget.audioFile;
    _audioBytes = widget.audioBytes;
    setAudioForPreview();
    setAudioForPreview();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });
  }

  Future<void> setAudioForPreview() async {
    if (_audioFile != null) {
      await _audioPlayer.setSource(DeviceFileSource(_audioFile!.path));
      await _audioPlayer.setSourceDeviceFile(_audioFile!.path);
    } else {
      await _audioPlayer.setSource(BytesSource(_audioBytes!));
      // await _audioPlayer.setSourceBytes(_audioBytes!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _audioFile != null ? null : AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // image
            Container(
              alignment: Alignment.center,
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(image: AssetImage('assets/music.jpg'), fit: BoxFit.fill)),
            ),
            const SizedBox(
              height: 10,
            ),
            // title
            Center(
              child: bodyText(text: widget.title ?? path.basenameWithoutExtension(_audioFile!.path)),
            ),
            const SizedBox(
              height: 10,
            ),
            // slider
            Center(
              child: Slider(
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  value: _position.inSeconds.toDouble(),
                  onChanged: (value) async {
                    final dur = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(dur);
                  }),
            ),
            const SizedBox(
              height: 5,
            ),
            // durations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [bodyText(text: formatDuration(_position)), bodyText(text: formatDuration(_duration))],
            ),
            const SizedBox(
              height: 5,
            ),
            // play & pause button
            InkWell(
              onTap: () async {
                if (_isPlaying == true) {
                  await _audioPlayer.pause();
                  setState(() {});
                } else {
                  await _audioPlayer.resume();
                  setState(() {});
                }
              },
              child: Center(
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Palette.purple,
                  child: AnimatedContainer(
                      alignment: Alignment.center,
                      duration: const Duration(milliseconds: 500),
                      child: Icon(_isPlaying == true ? Icons.pause : Icons.play_arrow, size: 50)),
                ),
              ),
            ),
            // upload progress indicator
            // Visibility(
            //   visible: _isLocal == true,
            //   child: Selector<MesagesProvider, UploadStatus>(
            //     selector: (_, mProvider) => mProvider.uploadStatus,
            //     builder: (context, status, child) {
            //       if (status == UploadStatus.done) {
            //         return Center(
            //           child: bodyText(text: 'Upload complete'),
            //         );
            //       } else if (status == UploadStatus.started) {
            //         return Selector<MesagesProvider, int>(
            //           selector: (_, mProvider) => mProvider.percentProgress,
            //           builder: (context, percent, child) {
            //             if (percent == 0) {
            //               return Container();
            //             } else {
            //               return Center(
            //                 child: bodyText(text: 'Uploading $percent%'),
            //               );
            //             }
            //           },
            //         );
            //       } else {
            //         return Container();
            //       }
            //     },
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
