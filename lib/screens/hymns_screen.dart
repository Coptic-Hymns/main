import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hymn.dart';
import 'hymn_detail_screen.dart';

class HymnsScreen extends StatefulWidget {
  final bool showFavoritesOnly;
  const HymnsScreen({super.key, this.showFavoritesOnly = false});

  @override
  State<HymnsScreen> createState() => _HymnsScreenState();
}

class _HymnsScreenState extends State<HymnsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _toggleFavorite(Hymn hymn) async {
    try {
      await FirebaseFirestore.instance
          .collection('hymns')
          .doc(hymn.id)
          .update({'isFavorite': !(hymn.isFavorite ?? false)});
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
        title: Text(widget.showFavoritesOnly ? 'Favorite Hymns' : 'Coptic Hymns'),
        actions: [
          if (!widget.showFavoritesOnly)
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HymnsScreen(
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
                hintText: 'Search hymns...',
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
                  .collection('hymns')
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
                  return const Center(child: Text('No hymns found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final hymn = Hymn.fromFirestore(doc);
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.music_note),
                      ),
                      title: Text(hymn.title ?? ''),
                      subtitle: Text(hymn.category ?? ''),
                      trailing: IconButton(
                        icon: Icon(
                          hymn.isFavorite == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: hymn.isFavorite == true ? Colors.red : null,
                        ),
                        onPressed: () => _toggleFavorite(hymn),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HymnDetailScreen(hymn: hymn),
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
              builder: (context) => const HymnDetailScreen(isNew: true),
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
