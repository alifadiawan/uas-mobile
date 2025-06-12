import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'package:mobile_uas/Notes/DetailNotes.dart';
import 'package:mobile_uas/Notes/InsertNotes.dart';
import 'package:mobile_uas/widgets/CustomBottomNavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotesIndex extends StatefulWidget {
  const NotesIndex({super.key});

  @override
  State<NotesIndex> createState() => _NotesIndexState();
}

class _NotesIndexState extends State<NotesIndex> {
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _allNotes = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use Future.wait to fetch notes and categories in parallel for faster loading
    Future.wait([_fetchCategories(), _loadNotes()]).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadNotes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final notes = await _fetchNotes(user.id);
    if (mounted) {
      setState(() {
        _allNotes = notes;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotes(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('notes')
          .select('*, category(nama_kategori)')
          .eq('user_id', userId)
          .order('created_at', ascending: false); // Show newest notes first

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      // You can show a SnackBar here to notify the user
      print('Error fetching notes: $e');
      return [];
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await Supabase.instance.client
          .from('category')
          .select('nama_kategori');

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // A getter for filtered notes, making the build method cleaner
  List<Map<String, dynamic>> get _filteredNotes {
    if (_selectedCategory == 'All') return _allNotes;
    return _allNotes.where((note) {
      return note['category'] != null &&
          note['category']['nama_kategori'] == _selectedCategory;
    }).toList();
  }

  // A helper to generate initials from email
  String _getInitials(String email) {
    if (email.isEmpty) return '??';
    List<String> parts = email.split('@').first.split('.');
    if (parts.length > 1) {
      return (parts.first.isNotEmpty ? parts.first[0] : '') +
          (parts.last.isNotEmpty ? parts.last[0] : '');
    }
    return email.substring(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: _buildAppBar(context, user),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildCategoryChips(),
            const SizedBox(height: 20),
            Text('Your Notes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildNotesList(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Builds the AppBar for the screen
  PreferredSizeWidget _buildAppBar(BuildContext context, User user) {
    final theme = Theme.of(context);
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.background,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back,',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          Text(
            user.email!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: theme.iconTheme.color),
          onPressed: () {
            // TODO: Implement search functionality
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              _getInitials(user.email!).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the horizontal list of category filter chips
  Widget _buildCategoryChips() {
    // Combine 'All' with fetched categories
    final List<String> chipLabels = [
      'All',
      ..._categories.map((c) => c['nama_kategori'].toString()),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            chipLabels.map((label) {
              final isSelected = _selectedCategory == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = label;
                      });
                    }
                  },
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          isSelected
                              ? Colors.transparent
                              : Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  /// Builds the list of notes or an empty state message
  Widget _buildNotesList() {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (_filteredNotes.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No notes found.',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              Text(
                _selectedCategory == 'All'
                    ? 'Tap the "+" button to create your first note!'
                    : 'Create a note in the "$_selectedCategory" category.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _filteredNotes.length,
        itemBuilder: (context, index) {
          final note = _filteredNotes[index];
          return _NoteCard(note: note); // Use the improved NoteCard widget
        },
      ),
    );
  }

  /// Builds the centered Floating Action Button
  Widget _buildFloatingActionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        elevation: 0,
        backgroundColor: Colors.transparent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InsertNotes()),
          ).then((_) => _loadNotes()); // Refresh notes after returning
        },
        child: Icon(Icons.add, size: 32.0, color: colorScheme.onPrimary),
      ),
    );
  }
}

/// A dedicated widget for displaying a single note card with a modern UI
class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;

  const _NoteCard({required this.note});

  // A simple utility to format the date
  String _formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      return DateFormat('d MMM yyyy').format(dateTime); // e.g., "12 Jun 2025"
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryName = note['category']?['nama_kategori'] ?? 'Uncategorized';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Detailnotes(noteId: note['id'].toString()),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note['title'] ?? 'No Title',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatDate(note['created_at']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Content Snippet
              Text(
                note['notes'] ?? 'No content...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Category Tag
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    categoryName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
