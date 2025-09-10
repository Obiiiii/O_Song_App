import 'package:flutter/material.dart';
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
        return url.split('youtu.be/')[1].split('?')[0];
      }
      // Handle youtube.com format
      if (url.contains('watch?v=')) {
        return url.split('watch?v=')[1].split('&')[0];
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
      if (!_isValidYouTubeUrl(_urlController.text.trim())) {
        throw Exception('Invalid YouTube URL');
      }

      final videoId = _extractVideoId(_urlController.text.trim());

      final music = MusicEntity(
        id: videoId,
        title: 'Loading...',
        // Will be updated by repository
        thumbnailUrl: 'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
        videoUrl: _urlController.text.trim(),
        duration: const Duration(minutes: 3, seconds: 45),
      );

      context.read<MusicListBloc>().add(AddMusicItem(music: music));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Music added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add music: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Music')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add a YouTube video to your music collection',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'YouTube URL',
                  hintText: 'https://www.youtube.com/watch?v=...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a YouTube URL';
                  }
                  if (!_isValidYouTubeUrl(value.trim())) {
                    return 'Please enter a valid YouTube URL';
                  }
                  return null;
                },
                maxLines: 2,
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
              const Text(
                'Supported formats:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• https://www.youtube.com/watch?v=VIDEO_ID'),
              const Text('• https://youtu.be/VIDEO_ID'),
              const Text('• https://m.youtube.com/watch?v=VIDEO_ID'),
            ],
          ),
        ),
      ),
    );
  }
}
