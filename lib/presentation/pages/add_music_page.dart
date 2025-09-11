import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';
import 'package:o_song_app/presentation/blocs/music_list_bloc/music_list_bloc.dart';

class AddMusicPage extends StatefulWidget {
  const AddMusicPage({Key? key}) : super(key: key);

  @override
  State<AddMusicPage> createState() => _AddMusicPageState();
}

class _AddMusicPageState extends State<AddMusicPage> {
  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';

  bool _isValidYouTubeUrl(String url) {
    final regExp = RegExp(
      r'^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?$',
      caseSensitive: false,
    );
    return regExp.hasMatch(url);
  }

  String _extractVideoId(String url) {
    try {
      // Handle youtu.be format
      if (url.contains('youtu.be/')) {
        final parts = url.split('youtu.be/');
        if (parts.length > 1) {
          return parts[1].split('?')[0].split('&')[0];
        }
      }
      // Handle youtube.com format
      if (url.contains('watch?v=')) {
        final parts = url.split('watch?v=');
        if (parts.length > 1) {
          return parts[1].split('&')[0];
        }
      }
      // Handle embed format
      if (url.contains('/embed/')) {
        final parts = url.split('/embed/');
        if (parts.length > 1) {
          return parts[1].split('?')[0];
        }
      }
      // Fallback
      return DateTime.now().millisecondsSinceEpoch.toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future<void> _addMusic() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = _urlController.text.trim();

      if (!_isValidYouTubeUrl(url)) {
        throw Exception('Invalid YouTube URL');
      }

      final videoId = _extractVideoId(url);

      final music = MusicEntity(
        id: videoId,
        title: 'Loading...',
        // Will be updated by repository
        thumbnailUrl: 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
        videoUrl: url,
        duration: const Duration(minutes: 3, seconds: 45),
      );

      // Add music via BLoC
      context.read<MusicListBloc>().add(AddMusicItem(music: music));

      // Clear form
      _urlController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Music added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back after short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add music: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _urlController.text = clipboardData!.text!;
        setState(() {
          _errorMessage = '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to paste from clipboard'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MusicListBloc, MusicListState>(
      listener: (context, state) {
        if (state is MusicListError) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Music'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('How to add music'),
                    content: const Text(
                      'Copy a YouTube video URL and paste it in the text field below. '
                      'Supported formats:\n'
                      '• https://www.youtube.com/watch?v=VIDEO_ID\n'
                      '• https://youtu.be/VIDEO_ID\n'
                      '• https://m.youtube.com/watch?v=VIDEO_ID',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add YouTube Video',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Paste a YouTube video URL to add it to your music collection',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'YouTube URL',
                    hintText: 'https://www.youtube.com/watch?v=...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.link),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: _pasteFromClipboard,
                      tooltip: 'Paste from clipboard',
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _addMusic(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a YouTube URL';
                    }
                    if (!_isValidYouTubeUrl(value.trim())) {
                      return 'Please enter a valid YouTube URL';
                    }
                    return null;
                  },
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 24),
                if (_isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                  const Text(
                    'Adding music...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ] else
                  ElevatedButton.icon(
                    onPressed: _addMusic,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Music'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Supported formats:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• https://www.youtube.com/watch?v=VIDEO_ID',
                        ),
                        const Text('• https://youtu.be/VIDEO_ID'),
                        const Text('• https://m.youtube.com/watch?v=VIDEO_ID'),
                        const Text('• YouTube embed URLs'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
