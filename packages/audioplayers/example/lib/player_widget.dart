import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class PlayerWidget extends StatefulWidget {
  final String url;

  const PlayerWidget({
    Key? key,
    required this.url,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PlayerWidgetState(url);
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  String url;

  late AudioPlayer _audioPlayer;

  _PlayerWidgetState(this.url);

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('play_button'),
              onPressed: _play,
              iconSize: 64.0,
              icon: const Icon(Icons.play_arrow),
              color: Colors.cyan,
            ),
            IconButton(
              key: const Key('pause_button'),
              onPressed: _pause,
              iconSize: 64.0,
              icon: const Icon(Icons.pause),
              color: Colors.cyan,
            ),
            IconButton(
              key: const Key('stop_button'),
              onPressed: _stop,
              iconSize: 64.0,
              icon: const Icon(Icons.stop),
              color: Colors.cyan,
            ),
          ],
        ),
      ],
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
  }

  Future<int> _play() async {
    final result = await _audioPlayer.play(url);
    return result;
  }

  Future<int> _pause() async {
    final result = await _audioPlayer.pause();
    return result;
  }

  Future<int> _stop() async {
    final result = await _audioPlayer.stop();
    return result;
  }
}
