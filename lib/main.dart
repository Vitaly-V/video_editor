import 'dart:io';

import 'package:flutter/material.dart';
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
  List<Map<String, String>> sources = [
    {
      'image':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg",
      'video':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    },
    {
      'image':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg",
      'video':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
    },
    {
      'image':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg",
      'video':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
    },
    {
      'image':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerJoyrides.jpg",
      'video':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
    },
    {
      'image':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerMeltdowns.jpg",
      'video':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
    },
    {
      'image':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/Sintel.jpg",
      'video':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
    },
    {
      'image':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/SubaruOutbackOnStreetAndDirt.jpg",
      'video':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
    },
    {
      'image':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/TearsOfSteel.jpg",
      'video':
          "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4"
    }
  ];

  final List<String> videos = [];
  bool _progressVisibility = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Happy We"),
      ),
      body: Column(children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            children: List.generate(sources.length, (index) {
              return InkWell(
                onTap: () {
                  if (videos.contains(sources[index]['video'])) {
                    videos.remove(sources[index]['video']);
                  } else {
                    videos.add(sources[index]['video']);
                  }
                  setState(() {});
                },
                child: Stack(children: [
                  Container(
                    padding: EdgeInsets.all(5),
                    child: Image.network(sources[index]['image']),
                  ),
                  if (videos.contains(sources[index]['video']))
                    Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(Icons.check_circle, color: Colors.green))
                ]),
              );
            }),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Text('Selected videos: ${videos.length}'),
        SizedBox(
          height: 10,
        ),
        Visibility(
          visible: _progressVisibility,
          child: LinearProgressIndicator(
            backgroundColor: Colors.red,
          ),
        ),
        Container(
          child: RaisedButton(
            child: Text("PROCESS VIDEO"),
            onPressed: () async {
              final tempDir = await getTemporaryDirectory();
              String rawDocumentPath = tempDir.path;
              final outputPath = '$rawDocumentPath/output.mp4';

              final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
              setState(() {
                _progressVisibility = true;
              });
              String commandToExecute =
                  '-y -i ${videos[0]} -i ${videos[1]} -preset ultrafast -r 65535/2733 -vsync 2 -filter_complex \'[0:v][0:a][1:v][1:a]concat=n=${videos.length}:v=1:a=1 [outv] [outa]\' -map \'[outv]\' -map \'[outa]\' $outputPath';
              var rc = await _flutterFFmpeg.execute(commandToExecute);
              setState(() {
                _progressVisibility = false;
              });
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
        SizedBox(
          height: 10,
        ),
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
        centerTitle: true,
        title: Text("Happy We"),
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
                  child: Text("Save video"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
