import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'api/release_mode.dart';

/// This represents a single AudioPlayer, which can play one audio at a time.
/// To play several audios at the same time, you must create several instances
/// of this class.
///
/// It holds methods to play, loop, pause, stop, seek the audio, and some useful
/// hooks for handlers and callbacks.
class AudioPlayer {
  static final MethodChannel _channel =
      const MethodChannel('xyz.luan/audioplayers')
        ..setMethodCallHandler(platformCallHandler);

  static const _uuid = Uuid();

  /// Reference [Map] with all the players created by the application.
  ///
  /// This is used to exchange messages with the [MethodChannel]
  /// (because there is only one channel for all players).
  static final players = <String, AudioPlayer>{};

  /// An unique ID generated for this instance of [AudioPlayer].
  ///
  /// This is used to properly exchange messages with the [MethodChannel].
  final String playerId;

  /// Creates a new instance and assigns an unique id to it.
  AudioPlayer({String? playerId}) : playerId = playerId ?? _uuid.v4() {
    players[this.playerId] = this;
  }

  Future<int> _invokeMethod(
    String method, [
    Map<String, dynamic> arguments = const <String, dynamic>{},
  ]) {
    final enhancedArgs = <String, dynamic>{
      ...arguments,
      'playerId': playerId,
    };
    return invokeMethod(method, enhancedArgs);
  }

  static Future<int> invokeMethod(
    String method,
    Map<String, dynamic> args,
  ) async {
    final result = await _channel.invokeMethod<int>(method, args);
    return result ?? 0; // if null, we assume error
  }

  /// Plays an audio.
  /// respectSilence and stayAwake are not implemented on macOS.
  Future<int> play(
    String url, {
    double volume = 1.0,
    bool respectSilence = false,
    bool stayAwake = false,
    bool duckAudio = false,
    bool recordingActive = false,
  }) async {
    final result = await _invokeMethod(
      'play',
      <String, dynamic>{'url': url},
    );

    return result;
  }

  /// Pauses the audio that is currently playing.
  ///
  /// If you call [resume] later, the audio will resume from the point that it
  /// has been paused.
  Future<int> pause() async {
    final result = await _invokeMethod('pause');
    return result;
  }

  /// Stops the audio that is currently playing.
  ///
  /// The position is going to be reset and you will no longer be able to resume
  /// from the last point.
  Future<int> stop() async {
    final result = await _invokeMethod('stop');
    return result;
  }

  /// Resumes the audio that has been paused or stopped, just like calling
  /// [play], but without changing the parameters.
  Future<int> resume() async {
    final result = await _invokeMethod('resume');
    return result;
  }

  /// Releases the resources associated with this media player.
  ///
  /// The resources are going to be fetched or buffered again as soon as you
  /// call [play] or [setUrl].
  Future<int> release() async {
    final result = await _invokeMethod('release');
    return result;
  }

  /// Sets the release mode.
  ///
  /// Check [ReleaseMode]'s doc to understand the difference between the modes.
  Future<int> setReleaseMode(ReleaseMode releaseMode) {
    return _invokeMethod(
      'setReleaseMode',
      <String, dynamic>{
        'releaseMode': releaseMode.toString(),
      },
    );
  }

  /// Sets the URL.
  ///
  /// Unlike [play], the playback will not resume.
  ///
  /// The resources will start being fetched or buffered as soon as you call
  /// this method.
  ///
  /// respectSilence is not implemented on macOS.
  Future<int> setUrl(
    String url, {
    bool? isLocal,
    bool respectSilence = false,
    bool recordingActive = false,
  }) {
    return _invokeMethod(
      'setUrl',
      <String, dynamic>{'url': url},
    );
  }

  static Future<void> platformCallHandler(MethodCall call) async {
    try {
      _doHandlePlatformCall(call);
    } catch (ex) {
      print('Unexpected error: $ex');
    }
  }

  static Future<void> _doHandlePlatformCall(MethodCall call) async {
    final callArgs = call.arguments as Map<dynamic, dynamic>;

    final playerId = callArgs['playerId'] as String;
    final player = players[playerId];

    if (!kReleaseMode && _isAndroid() && player == null) {
      final oldPlayer = AudioPlayer(playerId: playerId);
      await oldPlayer.release();
      oldPlayer.dispose();
      players.remove(playerId);
      return;
    }
    if (player == null) {
      return;
    }
  }

  /// Closes all [StreamController]s.
  ///
  /// You must call this method when your [AudioPlayer] instance is not going to
  /// be used anymore. If you try to use it after this you will get errors.
  Future<void> dispose() async {
    await release();
    players.remove(playerId);
  }

  bool isLocalUrl(String url) {
    return url.startsWith('/') ||
        url.startsWith('file://') ||
        url.substring(1).startsWith(':\\');
  }

  static bool _isAndroid() {
    // we need to be careful because the "isAndroid" check throws errors on web.
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid;
  }
}
