import 'package:flutter/material.dart';
import '../models/feast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FeastDetailScreen extends StatefulWidget {
  final Feast feast;

  const FeastDetailScreen({super.key, required this.feast});

  @override
  State<FeastDetailScreen> createState() => _FeastDetailScreenState();
}

class _FeastDetailScreenState extends State<FeastDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.feast.isFavorite ?? false;
  }

  Future<void> _toggleFavorite() async {
    try {
      await FirebaseFirestore.instance
          .collection('feasts')
          .doc(widget.feast.firestoreId)
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
        title: Text(widget.feast.name ?? ''),
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
            if (widget.feast.imageUrl != null)
              Center(
                child: Image.network(
                  widget.feast.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, size: 200);
                  },
                ),
              ),
            if (widget.feast.date != null) ...[
              const SizedBox(height: 16.0),
              Text('Date', style: Theme.of(context).textTheme.titleMedium),
              Text(DateFormat('MMMM d, y').format(widget.feast.date!)),
            ],
            if (widget.feast.category != null) ...[
              const SizedBox(height: 16.0),
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.feast.category!),
            ],
            if (widget.feast.description != null) ...[
              const SizedBox(height: 16.0),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(widget.feast.description!),
            ],
          ],
        ),
      ),
    );
  }
}
