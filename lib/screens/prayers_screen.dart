import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prayer.dart';
import 'prayer_detail_screen.dart';

class PrayersScreen extends StatefulWidget {
  final bool showFavoritesOnly;
  const PrayersScreen({super.key, this.showFavoritesOnly = false});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _toggleFavorite(Prayer prayer) async {
    try {
      await FirebaseFirestore.instance
          .collection('prayers')
          .doc(prayer.firestoreId)
          .update({'isFavorite': !(prayer.isFavorite ?? false)});
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
        title: Text(widget.showFavoritesOnly ? 'Favorite Prayers' : 'Coptic Prayers'),
        actions: [
          if (!widget.showFavoritesOnly)
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrayersScreen(
                      showFavoritesOnly: true,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search prayers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('prayers')
                  .where('title', isGreaterThanOrEqualTo: _searchQuery)
                  .where('title', isLessThanOrEqualTo: '${_searchQuery}z')
                  .where('isFavorite', isEqualTo: widget.showFavoritesOnly ? true : null)
                  .orderBy('title')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No prayers found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final prayer = Prayer.fromFirestore(doc);
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.book)),
                      title: Text(prayer.title ?? ''),
                      subtitle: Text(prayer.category ?? ''),
                      trailing: IconButton(
                        icon: Icon(
                          prayer.isFavorite == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: prayer.isFavorite == true ? Colors.red : null,
                        ),
                        onPressed: () => _toggleFavorite(prayer),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PrayerDetailScreen(prayer: prayer),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.showFavoritesOnly ? null : FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrayerDetailScreen(isNew: true),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
