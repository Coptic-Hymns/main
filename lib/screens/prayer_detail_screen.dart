import 'package:flutter/material.dart';
import '../models/prayer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/file_upload_service.dart';

class PrayerDetailScreen extends StatefulWidget {
  final Prayer? prayer;
  final bool isNew;

  const PrayerDetailScreen({
    super.key,
    this.prayer,
    this.isNew = false,
  }) : assert(prayer != null || isNew);

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  bool _isFavorite = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _contentController = TextEditingController();
  final _notesController = TextEditingController();
  String? _documentUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prayer != null) {
      _titleController.text = widget.prayer!.title ?? '';
      _categoryController.text = widget.prayer!.category ?? '';
      _contentController.text = widget.prayer!.content ?? '';
      _notesController.text = widget.prayer!.notes ?? '';
      _isFavorite = widget.prayer!.isFavorite ?? false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (widget.isNew) return;
    try {
      await FirebaseFirestore.instance
          .collection('prayers')
          .doc(widget.prayer!.firestoreId)
          .update({'isFavorite': !_isFavorite});
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling favorite: $e')),
        );
      }
    }
  }

  Future<void> _savePrayer() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prayerData = {
        'title': _titleController.text,
        'category': _categoryController.text,
        'content': _contentController.text,
        'notes': _notesController.text,
        'isFavorite': false,
      };

      if (widget.isNew) {
        final docRef = await FirebaseFirestore.instance
            .collection('prayers')
            .add(prayerData);
        if (_documentUrl != null) {
          // Update the document URL with the new document ID
          await docRef.update({
            'documentUrl': _documentUrl,
          });
        }
      } else {
        await FirebaseFirestore.instance
            .collection('prayers')
            .doc(widget.prayer!.firestoreId)
            .update(prayerData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving prayer: $e')),
        );
      }
    }
  }

  Future<void> _uploadDocument() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final documentId = widget.isNew
          ? 'temp_${DateTime.now().millisecondsSinceEpoch}'
          : widget.prayer!.firestoreId ?? '';
      final newDocumentUrl = await FileUploadService.pickAndUploadFile(
        collection: 'prayers',
        documentId: documentId,
        field: 'document',
        fileType: 'document',
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (newDocumentUrl != null) {
        // Delete old document if it exists
        if (_documentUrl != null) {
          await FileUploadService.deleteFile(_documentUrl!);
        }

        setState(() {
          _documentUrl = newDocumentUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
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
        title: Text(widget.isNew ? 'New Prayer' : widget.prayer!.title ?? ''),
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
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 10,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Content is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadDocument,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Document'),
              ),
              if (_documentUrl != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            if (_documentUrl != null) {
                              await FileUploadService.deleteFile(_documentUrl!);
                              setState(() {
                                _documentUrl = null;
                              });
                            }
                          },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove Document'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _savePrayer,
                  child: Text(widget.isNew ? 'Create Prayer' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
