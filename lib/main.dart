import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'hymn_cache.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/feasts_screen.dart';
import 'screens/hymns_screen.dart';
import 'screens/prayers_screen.dart';
import 'screens/saints_screen.dart';

// Global Isar instance
late Isar isar;

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase
      .initializeApp(); // Ensure Firebase is initialized for background messages
  // You can perform heavy data fetching or other logic here
  log('Handling a background message: ${message.messageId}');
  // For simplicity, just show a local notification
  _showLocalNotification(message);
}

// Shared function to show local notification
Future<void> _showLocalNotification(RemoteMessage message) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel', // id
    'High Importance Notifications', // name
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: DarwinNotificationDetails(), // Use default iOS settings
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode, // Notification ID
    message.notification?.title,
    message.notification?.body,
    platformChannelSpecifics,
    payload: message.data['payload'],
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SharedPreferences.getInstance(); // Initialize SharedPreferences
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Everything Coptic',
      theme: themeProvider.theme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CalendarScreen(),
    const FeastsScreen(),
    const HymnsScreen(),
    const PrayersScreen(),
    const SaintsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'Feasts',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note),
            label: 'Hymns',
          ),
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'Prayers',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Saints',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminPanelScreen(),
            ),
          );
        },
        child: const Icon(Icons.admin_panel_settings),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return FutureBuilder<void>(
            future: _ensureSuperAdmin(snapshot.data!),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return const MainScreen();
            },
          );
        }
        return const SignInScreen();
      },
    );
  }
}

Future<void> _ensureSuperAdmin(User user) async {
  final usersRef = FirebaseFirestore.instance.collection('users');
  final doc = await usersRef.doc(user.uid).get();
  if (!doc.exists) {
    await usersRef.doc(user.uid).set({
      'email': user.email,
      'role':
          user.email == 'philopatersalama16@gmail.com' ? 'super_admin' : 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
  } else if (user.email == 'philopatersalama16@gmail.com' &&
      doc['role'] != 'super_admin') {
    await usersRef.doc(user.uid).update({'role': 'super_admin'});
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EmailPasswordSignIn(),
              const SizedBox(height: 16),
              _GoogleSignInButton(),
              if (!Platform.isAndroid &&
                  !Platform.isWindows &&
                  !Platform.isLinux &&
                  !Platform.isFuchsia)
                _AppleSignInButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailPasswordSignIn extends StatefulWidget {
  @override
  State<_EmailPasswordSignIn> createState() => _EmailPasswordSignInState();
}

class _EmailPasswordSignInState extends State<_EmailPasswordSignIn> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            try {
              await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              );
            } on FirebaseAuthException catch (e) {
              setState(() => _error = e.message);
            }
          },
          child: const Text('Sign In'),
        ),
        TextButton(
          onPressed: () async {
            try {
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              );
            } on FirebaseAuthException catch (e) {
              setState(() => _error = e.message);
            }
          },
          child: const Text('Register'),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.login),
      label: const Text('Sign in with Google'),
      onPressed: () async {
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.apple),
      label: const Text('Sign in with Apple'),
      onPressed: () async {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        final oauthCredential = OAuthProvider('apple.com').credential(
          idToken: credential.identityToken,
          accessToken: credential.authorizationCode,
        );
        await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      },
    );
  }
}

class MainHome extends StatefulWidget {
  const MainHome({super.key});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  String? _userRole;
  bool _showLangModal = false;
  bool _showAdminModal = false;
  List<String> _selectedLangs = ['en', 'cop', 'ar'];
  String _search = '';
  Map<String, dynamic>? _selectedHymnData;
  bool _showSlideshow = false;
  bool _offline = false;
  Isar? _isar;
  Stream<List<IsarHymn>>? _isarStream;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    if (!kIsWeb) {
      _initIsar();
    }
    _setupConnectivity();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      _userRole = doc['role'] ?? 'user';
    });
  }

  Future<void> _initIsar() async {
    if (kIsWeb) return; // Skip Isar initialization for web
    
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [IsarHymnSchema],
      directory: dir.path,
      inspector: true,
      maxSizeMiB: 512,
    );
    setState(() {
      _isarStream = _isar!.isarHymns.where().watch(fireImmediately: true);
    });
    _cacheHymnsFromFirestore();
  }

  void _setupConnectivity() {
    if (kIsWeb) {
      // For web, we'll just use Firestore directly
      setState(() => _offline = false);
      return;
    }

    FirebaseFirestore.instance
        .collection('hymns')
        .limit(1)
        .get(const GetOptions(source: Source.serverAndCache))
        .then((snapshot) {
      setState(() => _offline = !snapshot.metadata.isFromCache);
      if (!snapshot.metadata.isFromCache) {
        _cacheHymnsFromFirestore();
      }
    }).catchError((_) {
      setState(() => _offline = true);
      return null;
    });

    FirebaseFirestore.instance.collection('hymns').snapshots().listen((
      snapshot,
    ) {
      if (kIsWeb) return; // Skip caching for web
      
      _isar?.writeTxn(() async {
        final currentFirestoreIds = snapshot.docs.map((e) => e.id).toSet();
        final existingIsarHymns = await _isar!.isarHymns.where().findAll();

        for (final isarHymn in existingIsarHymns) {
          if (!currentFirestoreIds.contains(isarHymn.firestoreId)) {
            await _isar!.isarHymns.delete(isarHymn.id);
          }
        }

        for (final doc in snapshot.docs) {
          final existingIsarHymn = await _isar!.isarHymns
              .filter()
              .firestoreIdEqualTo(doc.id)
              .findFirst();
          final newIsarHymn = IsarHymn.fromFirestore(doc.id, doc.data());
          if (existingIsarHymn == null) {
            await _isar!.isarHymns.put(newIsarHymn);
          } else if (existingIsarHymn.updatedAt?.isBefore(
                newIsarHymn.updatedAt ?? DateTime.now(),
              ) ??
              true) {
            newIsarHymn.id = existingIsarHymn.id;
            await _isar!.isarHymns.put(newIsarHymn);
          }
        }
      });
    });
  }

  Future<void> _cacheHymnsFromFirestore() async {
    if (kIsWeb || _isar == null) return; // Skip caching for web
    
    try {
      final snapshot = await FirebaseFirestore.instance.collection('hymns').get();
      await _isar!.writeTxn(() async {
        await _isar!.isarHymns.clear();
        for (final doc in snapshot.docs) {
          await _isar!.isarHymns.put(
            IsarHymn.fromFirestore(doc.id, doc.data()),
          );
        }
      });
    } catch (e) {
      log("Error caching hymns: $e");
    }
  }

  bool get isAdmin =>
      _userRole == 'super_admin' ||
      _userRole == 'admin' ||
      _userRole == 'regional_admin' ||
      _userRole == 'content_editor';

  @override
  Widget build(BuildContext context) {
    if (_showSlideshow && _selectedHymnData != null) {
      return _SlideshowScreen(
        hymnData: _selectedHymnData!,
        langs: _selectedLangs,
        onClose: () => setState(() => _showSlideshow = false),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Everything Coptic'),
        actions: [
          if (_offline)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.cloud_off, color: Colors.red),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 350,
            color: Colors.grey[100],
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search hymns...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim()),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<IsarHymn>>(
                    stream: _isarStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final isarHymns = snapshot.data!;

                      final filteredIsarHymns = isarHymns.where((hymn) {
                        final title = hymn.titleMap;
                        return _search.isEmpty ||
                            title.values.any(
                              (v) => v.toLowerCase().contains(
                                    _search.toLowerCase(),
                                  ),
                            );
                      }).toList();

                      if (filteredIsarHymns.isEmpty) {
                        return const Center(child: Text('No hymns found.'));
                      }
                      return ListView.builder(
                        itemCount: filteredIsarHymns.length,
                        itemBuilder: (context, i) {
                          final hymn = filteredIsarHymns[i];
                          final title = hymn.titleMap;
                          return ListTile(
                            title: Text(
                              title[_selectedLangs.first] ??
                                  title['en'] ??
                                  'Untitled',
                            ),
                            subtitle: Text(title['en'] ?? ''),
                            onTap: () => setState(
                              () => _selectedHymnData = hymn.toFirestore(),
                            ),
                            selected: _selectedHymnData?['firestoreId'] ==
                                hymn.firestoreId,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedHymnData == null
                ? Center(
                    child: Text(
                      'Select a hymn to view',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  )
                : _HymnDisplay(
                    hymnData: _selectedHymnData!,
                    langs: _selectedLangs,
                    onSelectLangs: () => setState(() => _showLangModal = true),
                    onSlideshow: () => setState(() => _showSlideshow = true),
                  ),
          ),
        ],
      ),
      persistentFooterButtons: [
        if (_showLangModal)
          _LanguageSelectionModal(
            selected: _selectedLangs,
            onClose: () => setState(() => _showLangModal = false),
            onChanged: (langs) => setState(() => _selectedLangs = langs),
          ),
        if (_showAdminModal)
          _AdminPortalModal(
            onClose: () => setState(() => _showAdminModal = false),
          ),
      ],
      floatingActionButton: isAdmin && kIsWeb
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showAdminModal = true),
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Admin'),
            )
          : null,
    );
  }
}

class _HymnDisplay extends StatefulWidget {
  final Map<String, dynamic> hymnData;
  final List<String> langs;
  final VoidCallback onSelectLangs;
  final VoidCallback onSlideshow;
  const _HymnDisplay({
    required this.hymnData,
    required this.langs,
    required this.onSelectLangs,
    required this.onSlideshow,
  });

  @override
  State<_HymnDisplay> createState() => _HymnDisplayState();
}

class _HymnDisplayState extends State<_HymnDisplay> {
  AudioPlayer? _player;
  bool _playing = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String url) async {
    _player ??= AudioPlayer();
    try {
      await _player!.setUrl(url);
      await _player!.play();
      setState(() => _playing = true);
      _player!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _playing = false);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Audio error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = List<Map<String, dynamic>>.from(
      widget.hymnData['blocks'] ?? [],
    );
    final audioUrl = widget.hymnData['audioUrl'] as String?;
    final youtubeUrl = widget.hymnData['youtubeUrl'] as String?;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: widget.onSelectLangs,
                icon: const Icon(Icons.language),
                label: const Text('Languages'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: widget.onSlideshow,
                icon: const Icon(Icons.slideshow),
                label: const Text('Slideshow'),
              ),
              const Spacer(),
              if (audioUrl != null)
                IconButton(
                  icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                  tooltip: _playing ? 'Stop Audio' : 'Play Audio',
                  onPressed: _playing
                      ? () async {
                          await _player?.stop();
                          setState(() => _playing = false);
                        }
                      : () => _playAudio(audioUrl),
                ),
              if (youtubeUrl != null && youtubeUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.ondemand_video),
                  tooltip: 'Open YouTube',
                  onPressed: () async {
                    final uri = Uri.tryParse(youtubeUrl);
                    if (uri != null) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: widget.langs
                    .map(
                      (lang) => DataColumn(
                        label: Text(
                          lang.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    .toList(),
                rows: blocks
                    .map(
                      (block) => DataRow(
                        cells: widget.langs
                            .map(
                              (lang) => DataCell(
                                Text(
                                  block[lang] ?? '',
                                  style: TextStyle(
                                    color: (block[lang] ?? '').isEmpty
                                        ? Colors.grey
                                        : null,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideshowScreen extends StatefulWidget {
  final Map<String, dynamic> hymnData;
  final List<String> langs;
  final VoidCallback onClose;
  const _SlideshowScreen({
    required this.hymnData,
    required this.langs,
    required this.onClose,
  });
  @override
  State<_SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<_SlideshowScreen> {
  int _index = 0;
  bool _autoPlay = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = List<Map<String, dynamic>>.from(
      widget.hymnData['blocks'] ?? [],
    );
    final total = blocks.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _autoPlay = !_autoPlay),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: total == 0
                ? const Text(
                    'No blocks',
                    style: TextStyle(color: Colors.white, fontSize: 32),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.langs
                        .map(
                          (lang) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                blocks[_index][lang] ?? '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'prev',
            backgroundColor: Colors.white,
            onPressed: _index > 0 ? () => setState(() => _index--) : null,
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          const Spacer(),
          FloatingActionButton(
            heroTag: 'close',
            backgroundColor: Colors.red,
            onPressed: widget.onClose,
            child: const Icon(Icons.close, color: Colors.white),
          ),
          const Spacer(),
          FloatingActionButton(
            heroTag: 'next',
            backgroundColor: Colors.white,
            onPressed: _index < (blocks.length - 1)
                ? () => setState(() => _index++)
                : null,
            child: const Icon(Icons.arrow_forward, color: Colors.black),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _LanguageSelectionModal extends StatefulWidget {
  final List<String> selected;
  final void Function() onClose;
  final void Function(List<String>) onChanged;
  const _LanguageSelectionModal({
    required this.selected,
    required this.onClose,
    required this.onChanged,
  });
  @override
  State<_LanguageSelectionModal> createState() =>
      _LanguageSelectionModalState();
}

class _LanguageSelectionModalState extends State<_LanguageSelectionModal> {
  late List<String> _langs;
  String? _error;
  final List<Map<String, String>> _allLangs = [
    {'code': 'en', 'name': 'English'},
    {'code': 'cop', 'name': 'Coptic'},
    {'code': 'ar', 'name': 'Arabic'},
    {'code': 'cop-en', 'name': 'Coptic–English'},
    {'code': 'cop-ar', 'name': 'Coptic–Arabic'},
  ];

  @override
  void initState() {
    super.initState();
    _langs = List.from(widget.selected);
  }

  bool _isValid(List<String> langs) {
    if (langs.length > 3) {
      return false;
    }
    if (langs.isEmpty) {
      return false;
    }
    if (langs.contains('cop-en') && langs.contains('cop-ar')) {
      return false;
    }
    if (langs.contains('cop') &&
        (langs.contains('cop-en') || langs.contains('cop-ar'))) {
      return false;
    }
    if (!langs.contains('cop') &&
        !langs.contains('cop-en') &&
        !langs.contains('cop-ar')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select up to 3 languages'),
            ..._allLangs.map(
              (lang) => CheckboxListTile(
                value: _langs.contains(lang['code']),
                title: Text(lang['name']!),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _langs.add(lang['code']!);
                    } else {
                      _langs.remove(lang['code']);
                    }
                    if (!_isValid(_langs)) {
                      _error = 'Invalid combination.';
                    } else {
                      _error = null;
                    }
                  });
                },
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isValid(_langs)
                      ? () {
                          widget.onChanged(_langs);
                          widget.onClose();
                        }
                      : null,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminPortalModal extends StatefulWidget {
  final VoidCallback onClose;
  const _AdminPortalModal({required this.onClose});
  @override
  State<_AdminPortalModal> createState() => _AdminPortalModalState();
}

class _AdminPortalModalState extends State<_AdminPortalModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 1100,
        height: 850,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Admin Portal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: const [
                Tab(icon: Icon(Icons.people), text: 'Users'),
                Tab(icon: Icon(Icons.event), text: 'Feasts'),
                Tab(icon: Icon(Icons.music_note), text: 'Hymns'),
                Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _UsersTab(),
                  _FeastsTab(),
                  _HymnsTab(),
                  _NotificationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _roles = const [
    'super_admin',
    'admin',
    'regional_admin',
    'content_editor',
    'user',
  ];
  bool _inviting = false;

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteUserDialog(
        onInvite: (email, role) async {
          setState(() => _inviting = true);
          final invites = FirebaseFirestore.instance.collection('invites');
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          await invites.add({
            'email': email,
            'role': role,
            'invitedAt': FieldValue.serverTimestamp(),
            'accepted': false,
          });
          if (!mounted) return;
          setState(() => _inviting = false);
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Invitation sent!')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = snapshot.data!.docs;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FloatingActionButton.extended(
                        heroTag: 'inviteUser',
                        onPressed: _showInviteDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Invite User'),
                        backgroundColor: Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final user = users[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(user['email'][0].toUpperCase()),
                          ),
                          title: Text(user['email']),
                          subtitle: Text('Role: ${user['role']}'),
                          trailing: DropdownButton<String>(
                            value: user['role'],
                            items: _roles
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.id)
                                    .update({'role': val});
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_inviting)
          Container(
            color: Colors.black.withValues(alpha: 0.2),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _InviteUserDialog extends StatefulWidget {
  final Future<void> Function(String email, String role) onInvite;
  const _InviteUserDialog({required this.onInvite});
  @override
  State<_InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<_InviteUserDialog> {
  final _emailController = TextEditingController();
  String _role = 'user';
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Invite User',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(
                  value: 'content_editor',
                  child: Text('Content Editor'),
                ),
                DropdownMenuItem(
                  value: 'regional_admin',
                  child: Text('Regional Admin'),
                ),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(
                  value: 'super_admin',
                  child: Text('Super Admin'),
                ),
              ],
              onChanged: (val) => setState(() => _role = val ?? 'user'),
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          final email = _emailController.text.trim();
                          if (!email.contains('@')) {
                            setState(() => _error = 'Enter a valid email');
                            return;
                          }
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          try {
                            await widget.onInvite(email, _role);
                          } catch (e) {
                            setState(() => _error = e.toString());
                          } finally {
                            setState(() => _loading = false);
                          }
                        },
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Send Invite'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeastsTab extends StatefulWidget {
  @override
  State<_FeastsTab> createState() => _FeastsTabState();
}

class _FeastsTabState extends State<_FeastsTab> {
  bool _showDialog = false;
  DocumentSnapshot? _editingFeast;

  void _openFeastDialog([DocumentSnapshot? feast]) {
    setState(() {
      _editingFeast = feast;
      _showDialog = true;
    });
  }

  void _closeFeastDialog() {
    setState(() {
      _showDialog = false;
      _editingFeast = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Feasts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  FloatingActionButton.extended(
                    heroTag: 'addFeast',
                    onPressed: () => _openFeastDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Feast'),
                    backgroundColor: Colors.deepPurple,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('feasts')
                      .orderBy('names.en')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final feasts = snapshot.data!.docs;
                    if (feasts.isEmpty) {
                      return const Center(child: Text('No feasts found.'));
                    }
                    return ListView.separated(
                      itemCount: feasts.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final feast = feasts[i];
                        final names = feast['names'] as Map<String, dynamic>;
                        return ListTile(
                          leading: feast['iconUrl'] != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    feast['iconUrl'],
                                  ),
                                )
                              : const CircleAvatar(child: Icon(Icons.event)),
                          title: Text(names['en'] ?? 'No English Name'),
                          subtitle: Text('Type: ${feast['type'] ?? ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _openFeastDialog(feast),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('feasts')
                                      .doc(feast.id)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_showDialog)
          _FeastDialog(feast: _editingFeast, onClose: _closeFeastDialog),
      ],
    );
  }
}

class _FeastDialog extends StatefulWidget {
  final DocumentSnapshot? feast;
  final VoidCallback onClose;
  const _FeastDialog({this.feast, required this.onClose});
  @override
  State<_FeastDialog> createState() => _FeastDialogState();
}

class _FeastDialogState extends State<_FeastDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _nameCtrls = {
    'en': TextEditingController(),
    'ar': TextEditingController(),
    'cop': TextEditingController(),
    'cop-en': TextEditingController(),
    'cop-ar': TextEditingController(),
  };
  String _type = 'Lordly';
  String _calendar = 'fixed';
  String? _iconUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.feast != null) {
      final names = widget.feast!['names'] as Map<String, dynamic>;
      for (final lang in _nameCtrls.keys) {
        _nameCtrls[lang]!.text = names[lang] ?? '';
      }
      _type = widget.feast!['type'] ?? 'Lordly';
      _calendar = widget.feast!['calendar'] ?? 'fixed';
      _iconUrl = widget.feast!['iconUrl'];
    }
  }

  @override
  void dispose() {
    for (final ctrl in _nameCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _saveFeast() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'names': {
        for (final lang in _nameCtrls.keys) lang: _nameCtrls[lang]!.text,
      },
      'type': _type,
      'calendar': _calendar,
      'iconUrl': _iconUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final feasts = FirebaseFirestore.instance.collection('feasts');
    if (widget.feast == null) {
      await feasts.add({...data, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await feasts.doc(widget.feast!.id).update(data);
    }
    widget.onClose();
  }

  Future<void> _pickIcon() async {
    setState(() => _uploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final ref = FirebaseStorage.instance.ref().child(
              'feast_icons/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
            );
        final uploadTask = ref.putData(
          file.bytes ?? await File(file.path!).readAsBytes(),
        );
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        if (!mounted) return;
        setState(() => _iconUrl = url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Icon upload failed: $e')));
    }
    if (!mounted) return;
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.feast == null ? 'Add Feast' : 'Edit Feast',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _uploading ? null : _pickIcon,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage:
                            _iconUrl != null ? NetworkImage(_iconUrl!) : null,
                        child: _iconUrl == null
                            ? const Icon(Icons.add_a_photo, size: 32)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _uploading
                        ? const CircularProgressIndicator()
                        : const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 16),
                ..._nameCtrls.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: e.key.toUpperCase(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'Lordly', child: Text('Lordly')),
                    DropdownMenuItem(value: 'Marian', child: Text('Marian')),
                    DropdownMenuItem(value: 'Saint', child: Text('Saint')),
                    DropdownMenuItem(value: 'Fasting', child: Text('Fasting')),
                  ],
                  onChanged: (val) => setState(() => _type = val ?? 'Lordly'),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _calendar,
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                    DropdownMenuItem(
                      value: 'computed',
                      child: Text('Computed'),
                    ),
                  ],
                  onChanged: (val) =>
                      setState(() => _calendar = val ?? 'fixed'),
                  decoration: const InputDecoration(
                    labelText: 'Calendar Logic',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onClose,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveFeast,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HymnsTab extends StatefulWidget {
  @override
  State<_HymnsTab> createState() => _HymnsTabState();
}

class _HymnsTabState extends State<_HymnsTab> {
  bool _showDialog = false;
  DocumentSnapshot? _editingHymn;

  void _openHymnDialog([DocumentSnapshot? hymn]) {
    setState(() {
      _editingHymn = hymn;
      _showDialog = true;
    });
  }

  void _closeHymnDialog() {
    setState(() {
      _showDialog = false;
      _editingHymn = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hymns',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  FloatingActionButton.extended(
                    heroTag: 'addHymn',
                    onPressed: () => _openHymnDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Hymn'),
                    backgroundColor: Colors.deepPurple,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('hymns')
                      .orderBy('title.en')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final hymns = snapshot.data!.docs;
                    if (hymns.isEmpty) {
                      return const Center(child: Text('No hymns found.'));
                    }
                    return ListView.separated(
                      itemCount: hymns.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final hymn = hymns[i];
                        final title =
                            (hymn['title'] as Map<String, dynamic>?) ?? {};
                        return ListTile(
                          leading: hymn['audioUrl'] != null
                              ? const Icon(
                                  Icons.audiotrack,
                                  color: Colors.deepPurple,
                                )
                              : const Icon(Icons.music_note),
                          title: Text(title['en'] ?? 'No English Title'),
                          subtitle: Text(
                            'Tags: ${(hymn['tags'] as List<dynamic>?)?.join(", ") ?? ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _openHymnDialog(hymn),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('hymns')
                                      .doc(hymn.id)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_showDialog)
          _HymnDialog(hymn: _editingHymn, onClose: _closeHymnDialog),
      ],
    );
  }
}

class _HymnDialog extends StatefulWidget {
  final DocumentSnapshot? hymn;
  final VoidCallback onClose;
  const _HymnDialog({this.hymn, required this.onClose});
  @override
  State<_HymnDialog> createState() => _HymnDialogState();
}

class _HymnDialogState extends State<_HymnDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _titleCtrls = {
    'en': TextEditingController(),
    'ar': TextEditingController(),
    'cop': TextEditingController(),
    'cop-en': TextEditingController(),
    'cop-ar': TextEditingController(),
  };
  List<Map<String, String>> _blocks = [];
  List<String> _tags = [];
  String _season = 'Annual';
  String? _audioUrl;
  String? _youtubeUrl;
  bool _uploading = false;
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    if (widget.hymn != null) {
      final title = widget.hymn!['title'] as Map<String, dynamic>;
      for (final lang in _titleCtrls.keys) {
        _titleCtrls[lang]!.text = title[lang] ?? '';
      }
      _blocks = List<Map<String, String>>.from(widget.hymn!['blocks'] ?? []);
      _tags = List<String>.from(widget.hymn!['tags'] ?? []);
      _season = widget.hymn!['season'] ?? 'Annual';
      _audioUrl = widget.hymn!['audioUrl'];
      _youtubeUrl = widget.hymn!['youtubeUrl'];
      _scheduledAt = widget.hymn!['scheduledAt'] != null
          ? (widget.hymn!['scheduledAt'] as Timestamp).toDate()
          : null;
    }
  }

  @override
  void dispose() {
    for (final ctrl in _titleCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _saveHymn() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'title': {
        for (final lang in _titleCtrls.keys) lang: _titleCtrls[lang]!.text,
      },
      'blocks': _blocks,
      'tags': _tags,
      'season': _season,
      'audioUrl': _audioUrl,
      'youtubeUrl': _youtubeUrl,
      'scheduledAt': _scheduledAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final hymns = FirebaseFirestore.instance.collection('hymns');
    if (widget.hymn == null) {
      await hymns.add({...data, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await hymns.doc(widget.hymn!.id).update(data);
    }
    widget.onClose();
  }

  Future<void> _pickAudio() async {
    setState(() => _uploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final ref = FirebaseStorage.instance.ref().child(
              'hymn_audio/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
            );
        final uploadTask = ref.putData(
          file.bytes ?? await File(file.path!).readAsBytes(),
        );
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        if (!mounted) return;
        setState(() => _audioUrl = url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Audio upload failed: $e')));
    }
    if (!mounted) return;
    setState(() => _uploading = false);
  }

  void _editBlock(int index) {
    showDialog(
      context: context,
      builder: (context) => _PhraseBlockDialog(
        block: _blocks[index],
        onSave: (block) {
          setState(() => _blocks[index] = block);
        },
      ),
    );
  }

  void _addBlock() {
    showDialog(
      context: context,
      builder: (context) => _PhraseBlockDialog(
        block: const {'en': '', 'ar': '', 'cop': '', 'cop-en': '', 'cop-ar': ''},
        onSave: (block) {
          setState(() => _blocks.add(block));
        },
      ),
    );
  }

  void _openAlignBlocks() async {
    final result = await showDialog<List<Map<String, String>>>(
      context: context,
      builder: (context) =>
          _AlignBlocksDialog(blocks: List<Map<String, String>>.from(_blocks)),
    );
    if (result != null) {
      setState(() => _blocks = result);
    }
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    final initialTime = TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now());
    final initialDate = _scheduledAt ?? DateTime.now();

    showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((picked) {
      if (!mounted || picked == null) return;
      showTimePicker(context: context, initialTime: initialTime).then((
        time,
      ) {
        if (!mounted || time == null) return;
        setState(() {
          _scheduledAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.hymn == null ? 'Add Hymn' : 'Edit Hymn',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ..._titleCtrls.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: e.key.toUpperCase(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Phrase Blocks',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: 'addBlock',
                      onPressed: _addBlock,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _blocks.isNotEmpty ? _openAlignBlocks : null,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Align Blocks'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._blocks.asMap().entries.map(
                      (entry) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(entry.value['en'] ?? ''),
                          subtitle: Text('Coptic: ${entry.value['cop'] ?? ''}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editBlock(entry.key),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    setState(() => _blocks.removeAt(entry.key)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                  ),
                  initialValue: _tags.join(', '),
                  onChanged: (v) => _tags = v
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _season,
                  items: const [
                    DropdownMenuItem(value: 'Annual', child: Text('Annual')),
                    DropdownMenuItem(value: 'Festal', child: Text('Festal')),
                    DropdownMenuItem(value: 'Lent', child: Text('Lent')),
                    DropdownMenuItem(value: 'Advent', child: Text('Advent')),
                  ],
                  onChanged: (val) => setState(() => _season = val ?? 'Annual'),
                  decoration: const InputDecoration(labelText: 'Season'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _uploading ? null : _pickAudio,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Audio'),
                    ),
                    const SizedBox(width: 8),
                    if (_audioUrl != null)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'YouTube Link'),
                  initialValue: _youtubeUrl ?? '',
                  onChanged: (v) => _youtubeUrl = v.trim(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Schedule:'),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showDateTimePicker(context);
                      },
                      child: Text(
                        _scheduledAt == null
                            ? 'Pick Date & Time'
                            : _scheduledAt.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onClose,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveHymn,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for _NotificationsTab
class _NotificationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('_NotificationsTab placeholder'));
  }
}

// Placeholder for _PhraseBlockDialog
class _PhraseBlockDialog extends StatelessWidget {
  final Map<String, String> block;
  final void Function(Map<String, String>) onSave;
  const _PhraseBlockDialog({required this.block, required this.onSave});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('_PhraseBlockDialog placeholder'),
      content: Text('Block: ${block.toString()}'),
      actions: [
        TextButton(
          onPressed: () {
            onSave(block);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Placeholder for _AlignBlocksDialog
class _AlignBlocksDialog extends StatelessWidget {
  final List<Map<String, String>> blocks;
  const _AlignBlocksDialog({required this.blocks});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('_AlignBlocksDialog placeholder'),
      content: Text('Blocks: ${blocks.length}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, blocks),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Firestore structure (for reference):
// users: {uid, email, role, createdAt}
// hymns: {id, blocks: [{id, en, ar, cop, cop-en, cop-ar, audioUrl, ...}], tags, seasons, ...}
// feasts: {id, names: {en, ar, cop, ...}, type, calendar, icon, readings, hymns}
// settings: {theme, defaultLangs, interlinear, textSize, slideshowEnabled, ...}
//
