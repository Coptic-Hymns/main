import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? event;
  final bool isNew;
  final DateTime selectedDate;

  const EventDetailScreen({
    super.key,
    this.event,
    required this.isNew,
    required this.selectedDate,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedType;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?['title']);
    _descriptionController = TextEditingController(text: widget.event?['description']);
    _selectedType = widget.event?['type'] ?? 'feast';
    _selectedDate = widget.event?['date']?.toDate() ?? widget.selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final eventData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': _selectedType,
        'date': Timestamp.fromDate(_selectedDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.isNew) {
        eventData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('events').add(eventData);
      } else {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event!['id'])
            .update(eventData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving event: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'New Event' : 'Edit Event'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Event Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'feast', child: Text('Feast')),
                DropdownMenuItem(value: 'saint', child: Text('Saint')),
                DropdownMenuItem(value: 'prayer', child: Text('Prayer')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(_selectedDate?.toString().split(' ')[0] ?? ''),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveEvent,
              child: Text(widget.isNew ? 'Create Event' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
} 