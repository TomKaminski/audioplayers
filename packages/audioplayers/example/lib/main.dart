import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

import 'components/btn.dart';
import 'components/tab_wrapper.dart';
import 'player_widget.dart';

typedef OnError = void Function(Exception exception);

const kUrl1 = 'https://luan.xyz/files/audio/ambient_c_motion.mp3';
const kUrl2 = 'https://luan.xyz/files/audio/nasa_on_a_mission.mp3';
const kUrl3 = 'http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio1xtra_mf_p';

void main() {
  runApp(MaterialApp(home: ExampleApp()));
}

class ExampleApp extends StatefulWidget {
  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  AudioCache audioCache = AudioCache();
  AudioPlayer advancedPlayer = AudioPlayer();
  String? localFilePath;
  String? localAudioCacheURI;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // Calls to Platform.isIOS fails on web
      return;
    }
  }

  Future _loadFile() async {
    final bytes = await readBytes(Uri.parse(kUrl1));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/audio.mp3');

    await file.writeAsBytes(bytes);
    if (file.existsSync()) {
      setState(() => localFilePath = file.path);
    }
  }

  Widget remoteUrl() {
    return const SingleChildScrollView(
      child: TabWrapper(
        children: [
          Text(
            'Sample 1 ($kUrl1)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget localFile() {
    return TabWrapper(
      children: [
        const Text(' -- manually load bytes (no web!) --'),
        const Text('File: $kUrl1'),
        Btn(txt: 'Download File to your Device', onPressed: _loadFile),
        Text('Current local file path: $localFilePath'),
        if (localFilePath != null) PlayerWidget(url: localFilePath!),
        Container(
          constraints: const BoxConstraints.expand(width: 1.0, height: 20.0),
        ),
        const Text(' -- via AudioCache --'),
        const Text('File: $kUrl2'),
        Btn(txt: 'Download File to your Device', onPressed: _loadFileAC),
        Text('Current AC loaded: $localAudioCacheURI'),
        if (localAudioCacheURI != null) PlayerWidget(url: localAudioCacheURI!),
      ],
    );
  }

  void _loadFileAC() async {
    final uri = await audioCache.load(kUrl2);
    setState(() => localAudioCacheURI = uri.toString());
  }

  Widget localAsset() {
    return SingleChildScrollView(
      child: TabWrapper(
        children: [
          const Text("Play Local Asset 'audio.mp3':"),
          Btn(txt: 'Play', onPressed: () => audioCache.play('audio.mp3')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Local File'),
            ],
          ),
          title: const Text('audioplayers Example'),
        ),
        body: TabBarView(
          children: [
            localFile(),
          ],
        ),
      ),
    );
  }
}
