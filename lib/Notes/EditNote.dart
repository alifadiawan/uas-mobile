import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditNote extends StatefulWidget {
  final String noteId;
  const EditNote({Key? key, required this.noteId}) : super(key: key);

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchNote();
  }

  Future<void> _fetchNote() async {
    final note = await Supabase.instance.client
        .from('notes')
        .select()
        .eq('id', widget.noteId)
        .single();
    _titleController.text = note['title'] ?? '';
    _notesController.text = note['notes'] ?? '';
  }

  Future<void> _updateNote() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client
          .from('notes')
          .update({
            'title': _titleController.text,
            'notes': _notesController.text,
          })
          .eq('id', widget.noteId);
      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh detail page
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update note: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        backgroundColor: const Color(0xFFF5E8FF),
        foregroundColor: const Color(0xFF9D6BC9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 6,
                validator: (v) => v == null || v.isEmpty ? 'Content required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _updateNote,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D6BC9),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}