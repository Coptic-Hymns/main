import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hymn.dart';
import '../models/prayer.dart';
import '../models/saint.dart';
import '../models/feast.dart';
import 'hymn_detail_screen.dart';
import 'prayer_detail_screen.dart';
import 'saint_detail_screen.dart';
import 'feast_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hymns'),
              Tab(text: 'Prayers'),
              Tab(text: 'Saints'),
              Tab(text: 'Feasts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFavoritesList<Hymn>(
              context,
              'hymns',
              (hymn) => Hymn.fromFirestore(hymn),
              (hymn) => HymnDetailScreen(hymn: hymn),
            ),
            _buildFavoritesList<Prayer>(
              context,
              'prayers',
              (prayer) => Prayer.fromFirestore(prayer),
              (prayer) => PrayerDetailScreen(prayer: prayer),
            ),
            _buildFavoritesList<Saint>(
              context,
              'saints',
              (saint) => Saint.fromFirestore(saint),
              (saint) => SaintDetailScreen(saint: saint),
            ),
            _buildFavoritesList<Feast>(
              context,
              'feasts',
              (feast) => Feast.fromFirestore(feast),
              (feast) => FeastDetailScreen(feast: feast),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList<T>(
    BuildContext context,
    String collection,
    T Function(DocumentSnapshot) fromFirestore,
    Widget Function(T) detailScreen,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('isFavorite', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data?.docs.map(fromFirestore).toList() ?? [];

        if (items.isEmpty) {
          return const Center(child: Text('No favorites yet'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            String title = '';
            String? subtitle;

            if (item is Hymn) {
              title = item.title ?? '';
              subtitle = item.category;
            } else if (item is Prayer) {
              title = item.title ?? '';
              subtitle = item.category;
            } else if (item is Saint) {
              title = item.name ?? '';
              subtitle = item.category;
            } else if (item is Feast) {
              title = item.name ?? '';
              subtitle = item.category;
            }

            return ListTile(
              title: Text(title),
              subtitle: subtitle != null ? Text(subtitle) : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => detailScreen(item),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
