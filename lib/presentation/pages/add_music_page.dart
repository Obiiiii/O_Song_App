import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';
import 'package:o_song_app/presentation/blocs/music_list_bloc/music_list_bloc.dart';

class AddMusicPage extends StatefulWidget {
  const AddMusicPage({Key? key}) : super(key: key);

  @override
  _AddMusicPageState createState() => _AddMusicPageState();
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

  Future<void> _addMusic() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!_isValidYouTubeUrl(_urlController.text)) {
        throw Exception('Invalid YouTube URL');
      }

      // Trong thực tế, bạn sẽ gọi YouTube API ở đây
      final videoId = _urlController.text.contains('youtu')
          ? _urlController.text.split('v=')[1].split('&')[0]
          : DateTime.now().millisecondsSinceEpoch.toString();

      final music = MusicEntity(
        id: videoId,
        title: 'Video từ URL',
        // Sẽ được cập nhật sau khi gọi API
        thumbnailUrl: 'https://img.youtube.com/vi/$videoId/default.jpg',
        videoUrl: _urlController.text,
        duration: const Duration(minutes: 3, seconds: 45),
      );

      context.read<MusicListBloc>().add(AddMusicItem(music: music));

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Music')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'YouTube URL',
                  hintText: 'Paste YouTube video URL here',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a YouTube URL';
                  }
                  if (!_isValidYouTubeUrl(value)) {
                    return 'Please enter a valid YouTube URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _addMusic,
                  child: const Text('Add Music'),
                ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Theme.of(context).errorColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}