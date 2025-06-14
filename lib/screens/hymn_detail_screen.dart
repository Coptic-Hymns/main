import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/hymn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HymnDetailScreen extends StatefulWidget {
  final Hymn hymn;

  const HymnDetailScreen({super.key, required this.hymn});

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.hymn.isFavorite ?? false;
    if (widget.hymn.audioUrl != null) {
      _audioPlayer.setUrl(widget.hymn.audioUrl!);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    try {
      await FirebaseFirestore.instance
          .collection('hymns')
          .doc(widget.hymn.firestoreId)
          .update({'isFavorite': !_isFavorite});
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error toggling favorite: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hymn.title ?? ''),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.hymn.audioUrl != null) ...[
              StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      width: 64.0,
                      height: 64.0,
                      child: const CircularProgressIndicator(),
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_arrow),
                      iconSize: 64.0,
                      onPressed: _audioPlayer.play,
                    );
                  } else if (processingState != ProcessingState.completed) {
                    return IconButton(
                      icon: const Icon(Icons.pause),
                      iconSize: 64.0,
                      onPressed: _audioPlayer.pause,
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(Icons.replay),
                      iconSize: 64.0,
                      onPressed: () => _audioPlayer.seek(Duration.zero),
                    );
                  }
                },
              ),
              StreamBuilder<Duration?>(
                stream: _audioPlayer.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return Slider(
                    value: position.inMilliseconds.toDouble(),
                    min: 0.0,
                    max:
                        _audioPlayer.duration?.inMilliseconds.toDouble() ?? 0.0,
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    },
                  );
                },
              ),
            ],
            if (widget.hymn.category != null) ...[
              const SizedBox(height: 16.0),
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.hymn.category!),
            ],
            if (widget.hymn.lyrics != null) ...[
              const SizedBox(height: 16.0),
              Text('Lyrics', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.hymn.lyrics!),
            ],
            if (widget.hymn.notes != null) ...[
              const SizedBox(height: 16.0),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.hymn.notes!),
            ],
          ],
        ),
      ),
    );
  }
}
