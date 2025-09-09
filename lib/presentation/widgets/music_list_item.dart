import 'package:flutter/material.dart';
import 'package:o_song_app/domain/entities/music_entity.dart';

class MusicListItem extends StatelessWidget {
  final MusicEntity music;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MusicListItem({
    Key? key,
    required this.music,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network(
        music.thumbnailUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.music_note);
        },
      ),
      title: Text(music.title),
      subtitle: Text(
        '${music.duration.inMinutes}:${(music.duration.inSeconds % 60).toString().padLeft(2, '0')}',
      ),
      onTap: onTap,
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
        color: Colors.red,
      ),
    );
  }
}