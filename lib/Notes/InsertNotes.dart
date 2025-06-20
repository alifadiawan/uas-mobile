import 'package:flutter/material.dart';
import 'package:mobile_uas/Notes/NotesIndex.dart'; // This import might not be needed anymore
import 'package:supabase_flutter/supabase_flutter.dart';

class InsertNotes extends StatefulWidget {
  const InsertNotes({super.key});

  @override
  State<InsertNotes> createState() => _InsertNotesState();
}

class _InsertNotesState extends State<InsertNotes> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  final _supabase = Supabase.instance.client;

  // State variables
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to safely show a SnackBar if loading fails
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _supabase.from('category').select('id, nama_kategori');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _saveNote() async {
    // 1. Validate the form, including the category dropdown
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check for user session
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    // 2. Set loading state
    setState(() {
      _isSaving = true;
    });

    try {
      // 3. Perform the insert
      await _supabase.from('notes').insert({
        'user_id': user.id,
        'title': _titleController.text.trim(),
        'notes': _notesController.text.trim(),
        'category_id': _selectedCategoryId,
      });

      // 4. Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return 'true' to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // 5. Reset loading state
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('New Note'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        actions: [
          // --- Improved Save Button in AppBar ---
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveNote,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Redesigned Title Field ---
                      TextFormField(
                        controller: _titleController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'What is this note about?',
                          prefixIcon: Icon(Icons.title_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Title cannot be empty' : null,
                      ),
                      const SizedBox(height: 20),

                      // --- Redesigned Notes Field ---
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Write down your thoughts...',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 120), // Adjust alignment
                            child: Icon(Icons.article_outlined),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Notes cannot be empty' : null,
                      ),
                      const SizedBox(height: 20),

                      // --- Redesigned Category Dropdown ---
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.folder_open_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<int>(
                            value: category['id'] as int,
                            child: Text(category['nama_kategori'].toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a category' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}