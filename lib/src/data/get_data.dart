import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
// BLoC States
abstract class AudioPlayerState {}

class AudioPlayerInitial extends AudioPlayerState {}

class AudioPlayerLoading extends AudioPlayerState {}

class AudioPlayerLoaded extends AudioPlayerState {
  final Waveform waveform;
  final Duration duration;
  final Duration position;
  final PlayerState playerState;

  AudioPlayerLoaded({
    required this.waveform,
    required this.duration,
    required this.position,
    required this.playerState,
  });
}

class AudioPlayerError extends AudioPlayerState {
  final String message;

  AudioPlayerError(this.message);
}

// BLoC Events
abstract class AudioPlayerEvent {}

class LoadAudio extends AudioPlayerEvent {}

class TogglePlayPause extends AudioPlayerEvent {}

class UpdatePosition extends AudioPlayerEvent {
  final Duration position;

  UpdatePosition(this.position);
}

// BLoC Class
class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  late AudioPlayer _player;
  Waveform? _waveform;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState _playerState = PlayerState.stopped;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  AudioPlayerBloc() : super(AudioPlayerInitial()) {
    _player = AudioPlayer();

    on<LoadAudio>(_onLoadAudio);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<UpdatePosition>(_onUpdatePosition);
  }

  Future<void> _onLoadAudio(LoadAudio event, Emitter<AudioPlayerState> emit) async {
    emit(AudioPlayerLoading());

    try {
      String filePath = await _getData();
      await _getWaveData(filePath);
      await _player.setSource(DeviceFileSource(filePath));
      _initStreams();
      emit(AudioPlayerLoaded(
        waveform: _waveform!,
        duration: _duration,
        position: _position,
        playerState: _playerState,
      ));
    } catch (e) {
      emit(AudioPlayerError(e.toString()));
    }
  }

  Future<void> _onTogglePlayPause(TogglePlayPause event, Emitter<AudioPlayerState> emit) async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.resume();
    }
    _playerState = _player.state;
    emit(AudioPlayerLoaded(
      waveform: _waveform!,
      duration: _duration,
      position: _position,
      playerState: _playerState,
    ));
  }

  Future<void> _onUpdatePosition(UpdatePosition event, Emitter<AudioPlayerState> emit) async {
    _position = event.position;
    emit(AudioPlayerLoaded(
      waveform: _waveform!,
      duration: _duration,
      position: _position,
      playerState: _playerState,
    ));
  }

  Future<String> _getData() async {
    String url = "https://codeskulptor-demos.commondatastorage.googleapis.com/descent/background%20music.mp3";
    String path = "";
    try {
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var bytes = response.bodyBytes;

        final tempDir = await getTemporaryDirectory();
        File file = await File('${tempDir.path}/audio.mp3').create();
        await file.writeAsBytes(bytes);

        path = file.path;
      } else {
        throw Exception("Failed to download file. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error occurred: $e");
    }
    return path;
  }

  Future<void> _getWaveData(String path) async {
    final tempDir = await getTemporaryDirectory();
    File file = await File('${tempDir.path}/waveform.wave').create();
    final progressStream = JustWaveform.extract(
      audioInFile: File(path),
      waveOutFile: file,
      zoom: const WaveformZoom.pixelsPerSecond(100),
    );
    await for (var waveformProgress in progressStream) {
      if (waveformProgress.waveform != null) {
        _waveform = waveformProgress.waveform;
      }
    }
  }

  void _initStreams() {
    _positionSubscription = _player.onPositionChanged.listen((position) {
      add(UpdatePosition(position));
    });

    _playerStateChangeSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      add(UpdatePosition(_position));  // To trigger a UI update
    });
  }

  @override
  Future<void> close() {
    _player.dispose();
    _positionSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    return super.close();
  }
}
