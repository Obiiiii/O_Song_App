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
  PlayerState _playerState = PlayerState.unknown;
  YoutubeMetaData _videoMetaData = const YoutubeMetaData();

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

      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
          hideControls: false,
          controlsVisibleAtStart: true,
          disableDragSeek: false,
          loop: false,
          isLive: false,
          forceHD: false,
          startAt: 0,
        ),
      );

      _controller!.addListener(_listener);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize player: $e';
      });
    }
  }

  void _listener() {
    if (!mounted) return;

    final controller = _controller;
    if (controller == null) return;

    setState(() {
      _playerState = controller.value.playerState;
      _videoMetaData = controller.metadata;
    });

    if (controller.value.hasError) {
      setState(() {
        _errorMessage = 'Player error: ${controller.value.errorCode}';
      });
    }

    if (controller.value.isReady && !_isPlayerReady) {
      setState(() {
        _isPlayerReady = true;
        _errorMessage = '';
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_listener);
    _controller?.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _errorMessage = '';
      _isPlayerReady = false;
      _playerState = PlayerState.unknown;
    });
    _controller?.dispose();
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.music.title, overflow: TextOverflow.ellipsis),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Playback Error',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.music.title, overflow: TextOverflow.ellipsis),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading player...'),
            ],
          ),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _videoMetaData.title.isNotEmpty
                  ? _videoMetaData.title
                  : widget.music.title,
              style: const TextStyle(color: Colors.white, fontSize: 18.0),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        onReady: () {
          if (mounted) {
            setState(() {
              _isPlayerReady = true;
            });
          }
        },
        onEnded: (data) {
          // Handle video end if needed
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _videoMetaData.title.isNotEmpty
                  ? _videoMetaData.title
                  : widget.music.title,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'quality':
                      // Could implement quality selection if needed
                      break;
                    case 'speed':
                      // Could implement speed selection if needed
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'quality',
                    child: Row(
                      children: [
                        Icon(Icons.high_quality),
                        SizedBox(width: 8),
                        Text('Quality'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'speed',
                    child: Row(
                      children: [
                        Icon(Icons.speed),
                        SizedBox(width: 8),
                        Text('Speed'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              player,
              if (!_isPlayerReady)
                Container(
                  height: 60,
                  color: Colors.black87,
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 16),
                        Text(
                          'Loading video...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVideoInfo(),
                      const SizedBox(height: 16),
                      _buildControlPanel(),
                      const SizedBox(height: 16),
                      if (_controller != null && _isPlayerReady)
                        _buildProgressInfo(),
                      const SizedBox(height: 16),
                      _buildPlayerStatus(),
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

  Widget _buildVideoInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _videoMetaData.title.isNotEmpty
                  ? _videoMetaData.title
                  : widget.music.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_videoMetaData.author.isNotEmpty) ...[
              Text(
                'By: ${_videoMetaData.author}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Duration: ${_formatDuration(widget.music.duration)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controls', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.replay_10),
                  onPressed: _isPlayerReady && _controller != null
                      ? () {
                          final currentPosition = _controller!.value.position;
                          final newPosition =
                              currentPosition - const Duration(seconds: 10);
                          _controller!.seekTo(
                            newPosition.isNegative
                                ? Duration.zero
                                : newPosition,
                            allowSeekAhead: true,
                          );
                        }
                      : null,
                  tooltip: 'Replay 10 seconds',
                ),
                IconButton(
                  iconSize: 48,
                  icon: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                  ),
                  onPressed: _isPlayerReady && _controller != null
                      ? () {
                          if (_playerState == PlayerState.playing) {
                            _controller!.pause();
                          } else {
                            _controller!.play();
                          }
                        }
                      : null,
                  tooltip: _playerState == PlayerState.playing
                      ? 'Pause'
                      : 'Play',
                ),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.forward_10),
                  onPressed: _isPlayerReady && _controller != null
                      ? () {
                          final currentPosition = _controller!.value.position;
                          final newPosition =
                              currentPosition + const Duration(seconds: 10);
                          _controller!.seekTo(
                            newPosition,
                            allowSeekAhead: true,
                          );
                        }
                      : null,
                  tooltip: 'Forward 10 seconds',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _isPlayerReady && _controller != null
                      ? () => _controller!.seekTo(Duration.zero)
                      : null,
                  icon: const Icon(Icons.skip_previous),
                  label: const Text('Start'),
                ),
                TextButton.icon(
                  onPressed: _isPlayerReady && _controller != null
                      ? () => _controller!.toggleFullScreenMode()
                      : null,
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Fullscreen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo() {
    return StreamBuilder<Duration>(
      stream: Stream.periodic(const Duration(milliseconds: 100), (_) {
        return _controller?.value.position ?? Duration.zero;
      }),
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = _videoMetaData.duration.inMilliseconds > 0
            ? _videoMetaData.duration
            : widget.music.duration;

        if (duration.inMilliseconds == 0) {
          return const SizedBox.shrink();
        }

        final progress = position.inMilliseconds / duration.inMilliseconds;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      _formatDuration(duration),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerStatus() {
    return Card(
      color: _getStatusColor(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(_getStatusIcon(), color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getStatusText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_playerState) {
      case PlayerState.playing:
        return Colors.green;
      case PlayerState.paused:
        return Colors.orange;
      case PlayerState.buffering:
        return Colors.blue;
      case PlayerState.ended:
        return Colors.purple;
      case PlayerState.cued:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (_playerState) {
      case PlayerState.playing:
        return Icons.play_arrow;
      case PlayerState.paused:
        return Icons.pause;
      case PlayerState.buffering:
        return Icons.hourglass_empty;
      case PlayerState.ended:
        return Icons.stop;
      case PlayerState.cued:
        return Icons.queue;
      default:
        return Icons.info;
    }
  }

  String _getStatusText() {
    if (!_isPlayerReady) {
      return 'Loading player...';
    }

    switch (_playerState) {
      case PlayerState.playing:
        return 'Playing';
      case PlayerState.paused:
        return 'Paused';
      case PlayerState.buffering:
        return 'Buffering...';
      case PlayerState.ended:
        return 'Video ended';
      case PlayerState.cued:
        return 'Ready to play';
      default:
        return 'Unknown state';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
