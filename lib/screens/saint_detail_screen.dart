import 'package:flutter/material.dart';
import '../models/saint.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/file_upload_service.dart';

class SaintDetailScreen extends StatefulWidget {
  final Saint? saint;
  final bool isNew;

  const SaintDetailScreen({
    super.key,
    this.saint,
    this.isNew = false,
  }) : assert(saint != null || isNew);

  @override
  State<SaintDetailScreen> createState() => _SaintDetailScreenState();
}

class _SaintDetailScreenState extends State<SaintDetailScreen> {
  bool _isFavorite = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _feastDayController = TextEditingController();
  final _categoryController = TextEditingController();
  final _biographyController = TextEditingController();
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.saint != null) {
      _isFavorite = widget.saint!.isFavorite ?? false;
      _nameController.text = widget.saint!.name ?? '';
      _feastDayController.text = widget.saint!.feastDay ?? '';
      _categoryController.text = widget.saint!.category ?? '';
      _biographyController.text = widget.saint!.biography ?? '';
      _imageUrl = widget.saint!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feastDayController.dispose();
    _categoryController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (widget.isNew) return;
    try {
      await FirebaseFirestore.instance
          .collection('saints')
          .doc(widget.saint!.firestoreId)
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

  Future<void> _saveSaint() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final saintData = {
        'name': _nameController.text,
        'feastDay': _feastDayController.text,
        'category': _categoryController.text,
        'biography': _biographyController.text,
        'imageUrl': _imageUrl,
        'isFavorite': false,
      };

      if (widget.isNew) {
        final docRef = await FirebaseFirestore.instance.collection('saints').add(saintData);
        if (_imageUrl != null) {
          // Update the image URL with the new document ID
          await docRef.update({
            'imageUrl': _imageUrl,
          });
        }
      } else {
        await FirebaseFirestore.instance
            .collection('saints')
            .doc(widget.saint!.firestoreId)
            .update(saintData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving saint: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final documentId = widget.isNew ? 'temp_${DateTime.now().millisecondsSinceEpoch}' : widget.saint!.firestoreId ?? '';
      final newImageUrl = await FileUploadService.pickAndUploadFile(
        collection: 'saints',
        documentId: documentId,
        field: 'image',
        fileType: 'image',
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
      );

      if (newImageUrl != null) {
        // Delete old image if it exists
        if (_imageUrl != null) {
          await FileUploadService.deleteFile(_imageUrl!);
        }

        setState(() {
          _imageUrl = newImageUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
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
        title: Text(widget.isNew ? 'New Saint' : widget.saint!.name ?? ''),
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
              if (!widget.isNew && _imageUrl != null)
                Center(
                  child: Image.network(
                    _imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 200);
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feastDayController,
                decoration: const InputDecoration(labelText: 'Feast Day'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _biographyController,
                decoration: const InputDecoration(labelText: 'Biography'),
                maxLines: 10,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Biography is required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadImage,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Image'),
              ),
              if (_imageUrl != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _isUploading ? null : () async {
                      if (_imageUrl != null) {
                        await FileUploadService.deleteFile(_imageUrl!);
                        setState(() {
                          _imageUrl = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove Image'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveSaint,
                  child: Text(widget.isNew ? 'Create Saint' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
