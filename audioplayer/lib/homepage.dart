import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final player = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  double volume = 0.5;
  File? audioFile;
  bool isLoading = false;
  bool hasError = false;

  @override
  void initState() {
    super.initState();

    player.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    player.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    player.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });

    player.setVolume(volume);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        audioFile = File(path);

        if (isPlaying) {
          player.stop();
          setState(() {
            isPlaying = false;
            position = Duration.zero;
          });
        }

        await player.setSource(DeviceFileSource(path));
        await Future.delayed(const Duration(milliseconds: 500));

        // Get the duration of the audio file
        duration = await player.getDuration() ?? Duration.zero;

        setState(() {
          position = Duration.zero;
        });
      }
    } catch (e, stackTrace) {
      print("Error picking file: $e");
      print(stackTrace);
      setState(() {
        hasError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return [if (d.inHours > 0) hours, minutes, seconds].join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: const Text(
          "AudioPlayer Created By Asim",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                image: const DecorationImage(
                  image: AssetImage('assets/animated_image.gif'),
                  fit: BoxFit.cover,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/animated_image.gif',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (hasError)
              const Text(
                'An error occurred. Please try again.',
                style: TextStyle(color: Colors.red),
              ),
            if (isLoading) const CircularProgressIndicator(),
            if (!isLoading && !hasError)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fast_rewind),
                    onPressed: () {
                      Duration newPosition =
                          position - const Duration(seconds: 10);
                      if (newPosition.inSeconds < 0) {
                        newPosition = const Duration(seconds: 0);
                      }
                      player.seek(newPosition);
                      setState(() {
                        position = newPosition;
                      });
                    },
                  ),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.black,
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          player.pause();
                        } else {
                          if (audioFile != null) {
                            player.play(DeviceFileSource(audioFile!.path));
                          }
                        }
                        setState(() {
                          isPlaying = !isPlaying;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fast_forward),
                    onPressed: () {
                      Duration newPosition =
                          position + const Duration(seconds: 10);
                      if (newPosition > duration) {
                        newPosition = duration;
                      }
                      player.seek(newPosition);
                      setState(() {
                        position = newPosition;
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 20),
            if (duration != Duration.zero)
              Column(
                children: [
                  Slider(
                    min: 0.0,
                    max: duration.inSeconds.toDouble(),
                    value: position.inSeconds.toDouble(),
                    onChanged: (value) {
                      setState(() {
                        position = Duration(seconds: value.toInt());
                      });
                      player.seek(position);
                    },
                    activeColor: Colors
                        .black, // Color of the portion of the slider that is active
                    inactiveColor: Colors.black.withOpacity(
                        0.3), // Color of the inactive portion of the slider
                    thumbColor: Colors.grey, // Color of the thumb
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatTime(position)),
                        Text(formatTime(duration - position)),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("VOLUME"),
                SizedBox(
                  width: 100,
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    value: volume,
                    onChanged: (value) {
                      setState(() {
                        volume = value;
                      });
                      player.setVolume(volume);
                    },
                  ),
                ),
                TextButton(
                  onPressed: pickFile,
                  child: const Text("Pick Audio File"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
