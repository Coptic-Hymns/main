import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/file_upload_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appNameController = TextEditingController();
  final _appDescriptionController = TextEditingController();
  String? _appLogoUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadAppSettings();
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _appDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAppSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_settings')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _appNameController.text = data['appName'] ?? '';
          _appDescriptionController.text = data['appDescription'] ?? '';
          _appLogoUrl = data['appLogoUrl'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveAppSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('app_settings')
          .set({
        'appName': _appNameController.text,
        'appDescription': _appDescriptionController.text,
        'appLogoUrl': _appLogoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _uploadLogo() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final newLogoUrl = await FileUploadService.pickAndUploadFile(
        collection: 'settings',
        documentId: 'app_settings',
        field: 'logo',
        fileType: 'image',
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
      );

      if (newLogoUrl != null) {
        // Delete old logo if it exists
        if (_appLogoUrl != null) {
          await FileUploadService.deleteFile(_appLogoUrl!);
        }

        setState(() {
          _appLogoUrl = newLogoUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading logo: $e')),
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (_appLogoUrl != null)
                Center(
                  child: Image.network(
                    _appLogoUrl!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 100);
                    },
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadLogo,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'Uploading...' : 'Upload App Logo'),
              ),
              if (_appLogoUrl != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _isUploading ? null : () async {
                      if (_appLogoUrl != null) {
                        await FileUploadService.deleteFile(_appLogoUrl!);
                        setState(() {
                          _appLogoUrl = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove Logo'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _appNameController,
                decoration: const InputDecoration(
                  labelText: 'App Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'App name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _appDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'App Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'App description is required' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Content Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Manage Feasts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to feast management
                },
              ),
              ListTile(
                leading: const Icon(Icons.music_note),
                title: const Text('Manage Hymns'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to hymn management
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Manage Saints'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to saint management
                },
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Manage Prayers'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to prayer management
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'User Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Manage Users'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to user management
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Manage Admins'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to admin management
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveAppSettings,
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 