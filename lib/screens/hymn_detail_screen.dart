import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/hymn.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/file_upload_service.dart';

class HymnDetailScreen extends StatefulWidget {
  final Hymn? hymn;
  final bool isNew;

  const HymnDetailScreen({
    super.key,
    this.hymn,
    this.isNew = false,
  }) : assert(hymn != null || isNew);

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isFavorite = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _notesController = TextEditingController();
  String? _audioUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.hymn != null) {
      _isFavorite = widget.hymn!.isFavorite ?? false;
      _titleController.text = widget.hymn!.title ?? '';
      _categoryController.text = widget.hymn!.category ?? '';
      _lyricsController.text = widget.hymn!.lyrics ?? '';
      _notesController.text = widget.hymn!.notes ?? '';
      _audioUrl = widget.hymn!.audioUrl;
      if (_audioUrl != null) {
        _audioPlayer.setUrl(_audioUrl!);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _lyricsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (widget.isNew) return;
    try {
      await FirebaseFirestore.instance
          .collection('hymns')
          .doc(widget.hymn!.id)
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

  Future<void> _saveHymn() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final hymnData = {
        'title': _titleController.text,
        'category': _categoryController.text,
        'lyrics': _lyricsController.text,
        'notes': _notesController.text,
        'audioUrl': _audioUrl,
        'isFavorite': false,
      };

      if (widget.isNew) {
        final docRef = await FirebaseFirestore.instance.collection('hymns').add(hymnData);
        if (_audioUrl != null) {
          // Update the audio URL with the new document ID
          await docRef.update({
            'audioUrl': _audioUrl,
          });
        }
      } else {
        await FirebaseFirestore.instance
            .collection('hymns')
            .doc(widget.hymn!.id)
            .update(hymnData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving hymn: $e')),
        );
      }
    }
  }

  Future<void> _uploadAudio() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final documentId = widget.isNew ? 'temp_${DateTime.now().millisecondsSinceEpoch}' : widget.hymn!.id ?? '';
      final newAudioUrl = await FileUploadService.pickAndUploadFile(
        collection: 'hymns',
        documentId: documentId,
        field: 'audio',
        fileType: 'audio',
        allowedExtensions: ['mp3', 'wav', 'm4a'],
      );

      if (newAudioUrl != null) {
        // Delete old audio if it exists
        if (_audioUrl != null) {
          await FileUploadService.deleteFile(_audioUrl!);
        }

        setState(() {
          _audioUrl = newAudioUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading audio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Hymn' : widget.hymn!.title ?? ''),
        actions: [
          if (!widget.isNew)
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lyricsController,
                decoration: const InputDecoration(labelText: 'Lyrics'),
                maxLines: 10,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Lyrics are required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadAudio,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.audio_file),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Audio'),
              ),
              if (_audioUrl != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _isUploading ? null : () async {
                      if (_audioUrl != null) {
                        await FileUploadService.deleteFile(_audioUrl!);
                        setState(() {
                          _audioUrl = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove Audio'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveHymn,
                  child: Text(widget.isNew ? 'Create Hymn' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
