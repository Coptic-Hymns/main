import 'package:flutter/material.dart';
import '../models/prayer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrayerDetailScreen extends StatefulWidget {
  final Prayer prayer;

  const PrayerDetailScreen({super.key, required this.prayer});

  @override
  State<PrayerDetailScreen> createState() => _PrayerDetailScreenState();
}

class _PrayerDetailScreenState extends State<PrayerDetailScreen> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.prayer.isFavorite ?? false;
  }

  Future<void> _toggleFavorite() async {
    try {
      await FirebaseFirestore.instance
          .collection('prayers')
          .doc(widget.prayer.firestoreId)
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
        title: Text(widget.prayer.title ?? ''),
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
            if (widget.prayer.category != null) ...[
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.prayer.category!),
              const SizedBox(height: 16.0),
            ],
            if (widget.prayer.content != null) ...[
              Text('Content', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.prayer.content!),
              const SizedBox(height: 16.0),
            ],
            if (widget.prayer.notes != null) ...[
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              Text(widget.prayer.notes!),
            ],
          ],
        ),
      ),
    );
  }
}
