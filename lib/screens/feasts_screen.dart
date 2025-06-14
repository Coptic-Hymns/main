import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feast.dart';
import 'feast_detail_screen.dart';

class FeastsScreen extends StatefulWidget {
  const FeastsScreen({super.key});

  @override
  State<FeastsScreen> createState() => _FeastsScreenState();
}

class _FeastsScreenState extends State<FeastsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _toggleFavorite(Feast feast) async {
    try {
      await FirebaseFirestore.instance
          .collection('feasts')
          .doc(feast.firestoreId)
          .update({'isFavorite': !(feast.isFavorite ?? false)});
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
        title: const Text('Coptic Feasts'),
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
                hintText: 'Search feasts...',
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
                  .collection('feasts')
                  .where('name', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name', isLessThanOrEqualTo: '${_searchQuery}z')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No feasts found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final feast = Feast.fromFirestore(doc);
                    return ListTile(
                      leading: feast.imageUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(feast.imageUrl!),
                            )
                          : const CircleAvatar(
                              child: Icon(Icons.calendar_today),
                            ),
                      title: Text(feast.name ?? ''),
                      subtitle: Text(
                        feast.date != null
                            ? '${feast.date!.day}/${feast.date!.month}/${feast.date!.year}'
                            : '',
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          feast.isFavorite == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: feast.isFavorite == true ? Colors.red : null,
                        ),
                        onPressed: () => _toggleFavorite(feast),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FeastDetailScreen(feast: feast),
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
          // TODO: Add new feast
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
