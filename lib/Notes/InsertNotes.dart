import 'package:flutter/material.dart';
import 'package:mobile_uas/Notes/NotesIndex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InsertNotes extends StatefulWidget {
  const InsertNotes({super.key});

  @override
  State<InsertNotes> createState() => _InsertNotesState();
}

class _InsertNotesState extends State<InsertNotes> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final supabase = Supabase.instance.client;

  // List to hold categories fetched from Supabase
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId; // to store selected category

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await supabase.from('category').select();

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _categories = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<void> insertNote() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    try {
      await supabase.from('notes').insert({
        'user_id': user.id,
        'title': _titleController.text,
        'notes': _notesController.text,
        'category_id': _selectedCategoryId,
      });

      if (!mounted) return;

      // Navigate back to NotesIndex and refresh it
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NotesIndex()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insert failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Create Note',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: InputBorder.none,
                        labelStyle: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Title is required' : null,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notes Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: InputBorder.none,
                        labelStyle: TextStyle(fontWeight: FontWeight.w500),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 7,
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Notes are required' : null,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Category Dropdown Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: InputBorder.none,
                        labelStyle: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      value: _selectedCategoryId,
                      items:
                          _categories.map((category) {
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
                      icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                      isExpanded: true,
                      validator:
                          (value) =>
                              value == null ? 'Please select a category' : null,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      insertNote();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Note',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
