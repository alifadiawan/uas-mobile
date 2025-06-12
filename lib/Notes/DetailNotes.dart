import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Detailnotes extends StatefulWidget {
  final String noteId;

  const Detailnotes({Key? key, required this.noteId}) : super(key: key);

  @override
  State<Detailnotes> createState() => _DetailnotesState();
}

class _DetailnotesState extends State<Detailnotes> {
  // Store the future in a state variable to avoid re-fetching on every build
  late final Future<Map<String, dynamic>> _noteFuture;

  @override
  void initState() {
    super.initState();
    _noteFuture = _getNoteDetails();
  }

  // Fetches note details including the category name from Supabase
  Future<Map<String, dynamic>> _getNoteDetails() async {
    try {
      final response =
          await Supabase.instance.client
              .from('notes')
              .select('*, category(nama_kategori)') // Also fetch category name
              .eq('id', widget.noteId)
              .single();
      return response;
    } catch (e) {
      // Throw an exception to be caught by the FutureBuilder
      throw Exception('Error fetching note details: $e');
    }
  }

  // Handles the deletion of the note
  Future<void> _deleteNote() async {
    try {
      await Supabase.instance.client
          .from('notes')
          .delete()
          .eq('id', widget.noteId);

      if (mounted) {
        // Pop the screen and signal that a deletion occurred
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Shows a themed confirmation dialog for deletion
  Future<void> _showDeleteDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text(
            'Are you sure you want to permanently delete this note?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: colorScheme.error)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _deleteNote();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _noteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text(
                "Error: Could not load note.",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }

          final note = snapshot.data!;
          return _buildNoteContent(context, note);
        },
      ),
    );
  }

  /// Builds the themed AppBar for the details screen
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.background,
      foregroundColor: Theme.of(context).colorScheme.onBackground,
      title: const Text("Note Details"),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () {
            // TODO: Implement navigation to an Edit Note page
            // You can pass the noteId and refresh upon return
          },
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: _showDeleteDialog,
        ),
      ],
    );
  }

  /// Builds the main scrollable content of the note
  Widget _buildNoteContent(BuildContext context, Map<String, dynamic> note) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final createdDate = DateTime.parse(note['created_at']);
    final formattedDate = DateFormat(
      'MMMM d, yyyy • hh:mm a',
    ).format(createdDate);
    final categoryName = note['category']?['nama_kategori'] ?? 'Uncategorized';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note Title
          Text(
            note['title'] ?? 'No Title',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Metadata Row (Date & Category)
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: theme.hintColor,
              ),
              const SizedBox(width: 8),
              Text(formattedDate, style: theme.textTheme.bodySmall),
              const SizedBox(width: 16),
              Icon(Icons.label_outline, size: 14, color: theme.hintColor),
              const SizedBox(width: 8),
              Text(categoryName, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: colorScheme.outline.withOpacity(0.5)),
          const SizedBox(height: 24),

          // Note Description/Content
          Text(
            note['notes'] ?? 'No content for this note.',
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5, // Improves readability
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
