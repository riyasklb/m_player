import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:m_player/src/data/get_data.dart';
import 'package:m_player/src/widgets/line_visualizer_custom_paint.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocProvider(
        create: (context) => AudioPlayerBloc()..add(LoadAudio()),
        child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            if (state is AudioPlayerLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AudioPlayerLoaded) {
              return Center(
                child: Container(
                  height: 140,
                  width: size.width - 30,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            BlocProvider.of<AudioPlayerBloc>(context)
                                .add(TogglePlayPause());
                          },
                          icon: Icon(
                            state.playerState == PlayerState.playing
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        Stack(
                          children: [
                            Center(
                              child: Container(
                                height: 80,
                                width: size.width - 100,
                                child: CustomPaint(
                                  isComplex: true,
                                  painter: AudioWaveformPainter(
                                      duration: state.waveform.duration,
                                      start: Duration.zero,
                                      waveColor: Colors.white,
                                      waveform: state.waveform),
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(seconds:  1),
                              height: 100,
                              width: state.position != null
                                  ? size.width *
                                      5.6 *
                                      (state.position.inSeconds / 100)
                                  : 0,
                              color: Colors.blue.withOpacity(0.6),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if (state is AudioPlayerError) {
              return Center(child: Text(state.message));
            } else {
              return const Center(child: Text("Please wait ...."));
            }
          },
        ),
      ),
    );
  }
}
