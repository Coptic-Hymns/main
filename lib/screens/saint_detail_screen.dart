import 'package:flutter/material.dart';
import '../models/saint.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaintDetailScreen extends StatefulWidget {
  final Saint saint;

  const SaintDetailScreen({super.key, required this.saint});

  @override
  State<SaintDetailScreen> createState() => _SaintDetailScreenState();
}

class _SaintDetailScreenState extends State<SaintDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.saint.isFavorite ?? false;
  }

  Future<void> _toggleFavorite() async {
    try {
      await FirebaseFirestore.instance
          .collection('saints')
          .doc(widget.saint.firestoreId)
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
        title: Text(widget.saint.name ?? ''),
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
            if (widget.saint.imageUrl != null)
              Center(
                child: Image.network(
                  widget.saint.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, size: 200);
                  },
                ),
              ),
            if (widget.saint.feastDay != null) ...[
              const SizedBox(height: 16.0),
              Text('Feast Day', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.saint.feastDay!),
            ],
            if (widget.saint.category != null) ...[
              const SizedBox(height: 16.0),
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.saint.category!),
            ],
            if (widget.saint.biography != null) ...[
              const SizedBox(height: 16.0),
              Text('Biography', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.saint.biography!),
            ],
          ],
        ),
      ),
    );
  }
}
