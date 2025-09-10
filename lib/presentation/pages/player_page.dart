import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';

class PlayerPage extends StatefulWidget {
  final MusicEntity music;

  const PlayerPage({Key? key, required this.music}) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    try {
      final videoId = YoutubePlayer.convertUrlToId(widget.music.videoUrl);

      if (videoId == null || videoId.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid YouTube URL';
        });
        return;
      }

      _controller =
          YoutubePlayerController(
              initialVideoId: videoId,
              flags: const YoutubePlayerFlags(
                autoPlay: true,
                mute: false,
                enableCaption: false,
                hideControls: false,
                controlsVisibleAtStart: true,
              ),
            )
            ..addListener(_listener)
            ..onError.listen((error) {
              if (mounted) {
                setState(() {
                  _errorMessage = error.toString();
                });
              }
            });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize player: $e';
      });
    }
  }

  void _listener() {
    if (_controller?.value.hasError == true) {
      if (mounted) {
        setState(() {
          _errorMessage =
              _controller?.value.errorCode.toString() ?? 'Unknown error';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_listener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.music.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = '';
                    _isPlayerReady = false;
                  });
                  _initializePlayer();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.music.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        onReady: () {
          if (mounted) {
            setState(() {
              _isPlayerReady = true;
            });
          }
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.music.title, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Implement share functionality if needed
                },
              ),
            ],
          ),
          body: Column(
            children: [
              player,
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.music.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Duration: ${_formatDuration(widget.music.duration)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildControlPanel(),
                      const SizedBox(height: 24),
                      if (_controller != null &&
                          _controller?.value.position != null)
                        _buildProgressInfo(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.replay_10),
              onPressed: _isPlayerReady && _controller != null
                  ? () {
                      final currentPosition =
                          _controller?.value.position ?? Duration.zero;
                      final newPosition =
                          currentPosition - const Duration(seconds: 10);
                      _controller?.seekTo(
                        newPosition.isNegative ? Duration.zero : newPosition,
                        allowSeekAhead: true,
                      );
                    }
                  : null,
            ),
            IconButton(
              iconSize: 48,
              icon: Icon(
                _controller?.value.isPlaying == true
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
              ),
              onPressed: _isPlayerReady && _controller != null
                  ? () {
                      if (_controller?.value.isPlaying == true) {
                        _controller?.pause();
                      } else {
                        _controller?.play();
                      }
                    }
                  : null,
            ),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.forward_10),
              onPressed: _isPlayerReady && _controller != null
                  ? () {
                      final currentPosition =
                          _controller?.value.position ?? Duration.zero;
                      final newPosition =
                          currentPosition + const Duration(seconds: 10);
                      _controller?.seekTo(newPosition, allowSeekAhead: true);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo() {
    final position = _controller?.value.position ?? Duration.zero;
    final duration =
        _controller?.value.metaData.duration ?? widget.music.duration;

    // Kiểm tra duration để tránh chia cho 0
    if (duration == null || duration.inMilliseconds == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: position.inMilliseconds / duration.inMilliseconds,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position)),
                Text(_formatDuration(duration)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
