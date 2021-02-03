import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Trimmer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Trimmer _trimmer = Trimmer();

  final ImagePicker _picker = ImagePicker();

  final List<String> videos = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Editor"),
      ),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Videos added: ${videos.length}'),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            child: RaisedButton(
              child: Text("LOAD VIDEO"),
              onPressed: () async {
                PickedFile file = await _picker.getVideo(
                  source: ImageSource.gallery,
                );
                setState(() {
                  videos.add(file.path);
                });
              },
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Container(
            child: RaisedButton(
              child: Text("PROCESS VIDEO"),
              onPressed: () async {
                final tempDir = await getTemporaryDirectory();
                String rawDocumentPath = tempDir.path;
                final outputPath = '$rawDocumentPath/output.mp4';

                final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

                String commandToExecute =
                    '-i ${videos[0]} -i ${videos[1]} -filter_complex \'[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1 [outv] [outa]\' -map \'[outv]\' -map \'[outa]\' $outputPath';
                var rc = await _flutterFFmpeg.execute(commandToExecute);
                print("FFmpeg process exited with rc $rc");
                File combinedFile = File(outputPath);
                if (combinedFile != null) {
                  await _trimmer.loadVideo(videoFile: combinedFile);
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return TrimmerView(_trimmer);
                  }));
                }
              },
            ),
          ),
        ]),
      ]),
    );
  }
}

class TrimmerView extends StatefulWidget {
  final Trimmer _trimmer;
  TrimmerView(this._trimmer);
  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  Future<String> _saveVideo() async {
    setState(() {
      _progressVisibility = true;
    });

    String _value;

    await widget._trimmer
        .saveTrimmedVideo(startValue: _startValue, endValue: _endValue)
        .then((value) {
      setState(() {
        _progressVisibility = false;
        _value = value;
      });
    });

    return _value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
      ),
      body: Builder(
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.only(bottom: 30.0),
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Visibility(
                  visible: _progressVisibility,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.red,
                  ),
                ),
                RaisedButton(
                  onPressed: _progressVisibility
                      ? null
                      : () async {
                          _saveVideo().then((outputPath) {
                            print('OUTPUT PATH: $outputPath');
                            final snackBar = SnackBar(
                                content: Text('Video Saved successfully'));
                            Scaffold.of(context).showSnackBar(snackBar);
                          });
                        },
                  child: Text("SAVE"),
                ),
                Expanded(
                  child: VideoViewer(),
                ),
                Center(
                  child: TrimEditor(
                    viewerHeight: 50.0,
                    viewerWidth: MediaQuery.of(context).size.width,
                    onChangeStart: (value) {
                      _startValue = value;
                    },
                    onChangeEnd: (value) {
                      _endValue = value;
                    },
                    onChangePlaybackState: (value) {
                      setState(() {
                        _isPlaying = value;
                      });
                    },
                  ),
                ),
                FlatButton(
                  child: _isPlaying
                      ? Icon(
                          Icons.pause,
                          size: 80.0,
                          color: Colors.white,
                        )
                      : Icon(
                          Icons.play_arrow,
                          size: 80.0,
                          color: Colors.white,
                        ),
                  onPressed: () async {
                    bool playbackState =
                        await widget._trimmer.videPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() {
                      _isPlaying = playbackState;
                    });
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
