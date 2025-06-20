import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Remove GoogleFonts and custom color constants for consistency with InsertNotes ---

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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNote();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchNote() async {
    try {
      final response = await Supabase.instance.client
          .from('notes')
          .select()
          .eq('id', widget.noteId)
          .single();

      if (mounted) {
        _titleController.text = response['title'] ?? '';
        _notesController.text = response['notes'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch note: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _updateNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await Supabase.instance.client
          .from('notes')
          .update({
            'title': _titleController.text.trim(),
            'notes': _notesController.text.trim(),
          })
          .eq('id', widget.noteId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update note: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Edit Note'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _loading ? null : _updateNote,
              child: _loading
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
      body: _loading && _titleController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Title Field (same as InsertNotes) ---
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

                      // --- Notes Field (same as InsertNotes) ---
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Write down your thoughts...',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 120),
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
                      // No category dropdown for edit (unless you want to add it)
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
