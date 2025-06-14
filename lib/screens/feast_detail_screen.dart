import 'package:flutter/material.dart';
import '../models/feast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/file_upload_service.dart';
import 'package:intl/intl.dart';

class FeastDetailScreen extends StatefulWidget {
  final Feast? feast;
  final bool isNew;

  const FeastDetailScreen({
    super.key,
    this.feast,
    this.isNew = false,
  }) : assert(feast != null || isNew);

  @override
  State<FeastDetailScreen> createState() => _FeastDetailScreenState();
}

class _FeastDetailScreenState extends State<FeastDetailScreen> {
  bool _isFavorite = false;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  String? _imageUrl;
  bool _isUploading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.feast != null) {
      _isFavorite = widget.feast!.isFavorite ?? false;
      _titleController.text = widget.feast!.title ?? '';
      _selectedDate = widget.feast!.date;
      _dateController.text = _selectedDate != null
          ? DateFormat('MMMM d, y').format(_selectedDate!)
          : '';
      _categoryController.text = widget.feast!.category ?? '';
      _descriptionController.text = widget.feast!.description ?? '';
      _notesController.text = widget.feast!.notes ?? '';
      _imageUrl = widget.feast!.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (widget.isNew) return;
    try {
      await FirebaseFirestore.instance
          .collection('feasts')
          .doc(widget.feast!.firestoreId)
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

  Future<void> _saveFeast() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final feastData = {
        'title': _titleController.text,
        'date': _selectedDate,
        'category': _categoryController.text,
        'description': _descriptionController.text,
        'notes': _notesController.text,
        'imageUrl': _imageUrl,
        'isFavorite': false,
      };

      if (widget.isNew) {
        final docRef = await FirebaseFirestore.instance.collection('feasts').add(feastData);
        if (_imageUrl != null) {
          // Update the image URL with the new document ID
          await docRef.update({
            'imageUrl': _imageUrl,
          });
        }
      } else {
        await FirebaseFirestore.instance
            .collection('feasts')
            .doc(widget.feast!.firestoreId)
            .update(feastData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving feast: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('MMMM d, y').format(picked);
      });
    }
  }

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final documentId = widget.isNew ? 'temp_${DateTime.now().millisecondsSinceEpoch}' : widget.feast!.firestoreId ?? '';
      final newImageUrl = await FileUploadService.pickAndUploadFile(
        collection: 'feasts',
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
        title: Text(widget.isNew ? 'New Feast' : widget.feast!.title ?? ''),
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
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(_selectedDate == null
                    ? 'No date selected'
                    : DateFormat('MMMM d, y').format(_selectedDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 5,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
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
                  onPressed: _isUploading ? null : _saveFeast,
                  child: Text(widget.isNew ? 'Create Feast' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
