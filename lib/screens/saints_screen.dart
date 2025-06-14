import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saint.dart';
import 'saint_detail_screen.dart';

class SaintsScreen extends StatefulWidget {
  const SaintsScreen({super.key});

  @override
  State<SaintsScreen> createState() => _SaintsScreenState();
}

class _SaintsScreenState extends State<SaintsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _toggleFavorite(Saint saint) async {
    try {
      await FirebaseFirestore.instance
          .collection('saints')
          .doc(saint.firestoreId)
          .update({'isFavorite': !(saint.isFavorite ?? false)});
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
        title: const Text('Coptic Saints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              // TODO: Navigate to favorites
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
                hintText: 'Search saints...',
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
                  .collection('saints')
                  .where('name', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name', isLessThanOrEqualTo: '${_searchQuery}z')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No saints found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final saint = Saint.fromFirestore(doc);
                    return ListTile(
                      leading: saint.imageUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(saint.imageUrl!),
                            )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(saint.name ?? ''),
                      subtitle: Text(saint.feastDay ?? ''),
                      trailing: IconButton(
                        icon: Icon(
                          saint.isFavorite == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: saint.isFavorite == true ? Colors.red : null,
                        ),
                        onPressed: () => _toggleFavorite(saint),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SaintDetailScreen(saint: saint),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new saint
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
