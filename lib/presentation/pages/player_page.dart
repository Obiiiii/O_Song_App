import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';

class PlayerPage extends StatefulWidget {
  final MusicEntity music;

  const PlayerPage({Key? key, required this.music}) : super(key: key);

  @override
  _PlayerPageState createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    try {
      final videoId = YoutubePlayer.convertUrlToId(widget.music.videoUrl);

      if (videoId == null) {
        setState(() {
          _errorMessage = 'Invalid YouTube URL';
        });
        return;
      }

      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
        ),
      )..addListener(_listener);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize player: $e';
      });
    }
  }

  void _listener() {
    if (_controller.value.hasError) {
      setState(() {
        _errorMessage = _controller.value.errorCode.toString();
      });
    }

    if (mounted && _isPlayerReady) {
      setState(() {});
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.music.title)),
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.music.title),
      ),
      body: Column(
        children: [
          YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.blueAccent,
            onReady: () {
              setState(() {
                _isPlayerReady = true;
              });
            },
            onError: (error) {
              setState(() {
                _errorMessage = error;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.music.title,
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: _isPlayerReady ? () {} : null,
                    ),
                    IconButton(
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: _isPlayerReady
                          ? () {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: _isPlayerReady ? () {} : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}