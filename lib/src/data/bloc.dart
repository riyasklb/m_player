// import 'dart:async';
// import 'dart:io';

// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:just_waveform/just_waveform.dart';
// import 'package:m_player/src/data/get_data.dart';
// import 'package:m_player/src/data/get_data.dart';
// import 'package:m_player/src/data/get_data.dart';
// import 'package:path_provider/path_provider.dart';

// part 'audio_event.dart';
// part 'audio_state.dart';

// class AudioBloc extends Bloc<AudioEvent, AudioState> {
//   late final AudioPlayer player;
//   StreamSubscription<Duration>? _durationSubscription;
//   StreamSubscription<Duration>? _positionSubscription;
//   StreamSubscription<void>? _playerCompleteSubscription;
//   StreamSubscription<PlayerState>? _playerStateChangeSubscription;

//   AudioBloc() : super(AudioInitial()) {
//     player = AudioPlayer();
//     _initStreams();

//     on<LoadAudioEvent>(_onLoadAudio);
//     on<PlayPauseAudioEvent>(_onPlayPauseAudio);
//     on<UpdatePositionEvent>(_onUpdatePosition);
//   }

//   Future<void> _onLoadAudio(LoadAudioEvent event, Emitter<AudioState> emit) async {
//     String filePath = await _getData();
//     if (filePath.isNotEmpty) {
//       emit(AudioLoaded(filePath: filePath));
//       final waveform = await _getWaveData(filePath);
//       emit(AudioReady(waveform: waveform));
//     } else {
//       emit(AudioError("Failed to load audio"));
//     }
//   }

//   Future<void> _onPlayPauseAudio(PlayPauseAudioEvent event, Emitter<AudioState> emit) async {
//     if (state is AudioPlaying) {
//       await player.pause();
//       emit(AudioPaused());
//     } else if (state is AudioPaused || state is AudioReady) {
//       await player.resume();
//       emit(AudioPlaying());
//     }
//   }

//   Future<void> _onUpdatePosition(UpdatePositionEvent event, Emitter<AudioState> emit) async {
//     emit(AudioPositionUpdated(position: event.position));
//   }

//   Future<String> _getData() async {
//     String url = "https://codeskulptor-demos.commondatastorage.googleapis.com/descent/background%20music.mp3";
//     String path = "";
//     try {
//       var response = await http.get(Uri.parse(url), headers: {
//         "X-Microsoft-OutputFormat": "audio-48khz-96kbitrate-mono-mp3",
//         "Content-Type": "application/ssml+xml"
//       });

//       if (response.statusCode == 200) {
//         var bytes = response.bodyBytes;

//         final tempDir = await getTemporaryDirectory();
//         File file = await File('${tempDir.path}/audio.mp3').create();
//         await file.writeAsBytes(bytes);

//         path = file.path;
//       }
//     } catch (e) {
//       print("Error occurred: $e");
//     }
//     return path;
//   }

//   Future<Waveform?> _getWaveData(String path) async {
//     final tempDir = await getTemporaryDirectory();
//     File file = await File('${tempDir.path}/waveform.wave').create();
//     final progressStream = JustWaveform.extract(
//       audioInFile: File(path),
//       waveOutFile: file,
//       zoom: const WaveformZoom.pixelsPerSecond(100),
//     );

//     Waveform? waveform;
//     await for (final waveformProgress in progressStream) {
//       if (waveformProgress.waveform != null) {
//         waveform = waveformProgress.waveform;
//         break;
//       }
//     }
//     return waveform;
//   }

//   void _initStreams() {
//     _durationSubscription = player.onDurationChanged.listen((duration) {
//       add(UpdatePositionEvent(duration));
//     });

//     _positionSubscription = player.onPositionChanged.listen((position) {
//       add(UpdatePositionEvent(position));
//     });

//     _playerCompleteSubscription = player.onPlayerComplete.listen((_) {
//       add(UpdatePositionEvent(Duration.zero));
//     });

//     _playerStateChangeSubscription = player.onPlayerStateChanged.listen((state) {
//       if (state == PlayerState.playing) {
//         add(PlayPauseAudioEvent());
//       } else {
//         add(PlayPauseAudioEvent());
//       }
//     });
//   }

//   @override
//   Future<void> close() {
//     player.dispose();
//     _durationSubscription?.cancel();
//     _positionSubscription?.cancel();
//     _playerCompleteSubscription?.cancel();
//     _playerStateChangeSubscription?.cancel();
//     return super.close();
//   }
// }
