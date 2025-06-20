import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'package:mobile_uas/Notes/DetailNotes.dart';
import 'package:mobile_uas/Notes/InsertNotes.dart';
import 'package:mobile_uas/Notes/SearchPage.dart';
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
    Future.wait([_fetchCategories(), _loadNotes()]).then((_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  // --- DATA FETCHING (No changes needed here) ---
  Future<void> _loadNotes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final notes = await _fetchNotes(user.id);
    if (mounted) {
      setState(() => _allNotes = notes);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNotes(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('notes')
          .select('*, category(nama_kategori)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
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
        setState(() => _categories = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  // --- GETTERS & HELPERS (No changes needed here) ---
  List<Map<String, dynamic>> get _filteredNotes {
    if (_selectedCategory == 'All') return _allNotes;
    return _allNotes.where((note) {
      return note['category'] != null &&
          note['category']['nama_kategori'] == _selectedCategory;
    }).toList();
  }

  String _getInitials(String email) {
    if (email.isEmpty) return '??';
    List<String> parts = email.split('@').first.split('.');
    if (parts.length > 1) {
      return (parts.first.isNotEmpty ? parts.first[0] : '') +
          (parts.last.isNotEmpty ? parts.last[0] : '');
    }
    return email.substring(0, 2);
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context, user),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _buildCategoryFilters(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Your Notes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          _buildNotesList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InsertNotes()),
          );
        },
        backgroundColor: Colors.grey.shade800,
        icon: const Icon(Icons.add, size: 32.0, color: Colors.white),
        label: const Text(
          'New Note',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNavBar(currentIndex: 0),
    );
  }

  // --- RE-STYLED WIDGETS ---

  PreferredSizeWidget _buildAppBar(BuildContext context, User user) {
    final theme = Theme.of(context);

    // Get user's photo URL from Google or other providers
    String? photoUrl = user.userMetadata?['avatar_url'] ??
        user.userMetadata?['picture'];

    String displayName = user.userMetadata?['name'] ??
        user.userMetadata?['full_name'] ??
        user.userMetadata?['username'] ??
        user.email ??
        'No name';

    String getInitials(String name) {
      if (name.isEmpty) return '??';
      List<String> parts = name.trim().split(' ');
      if (parts.length == 1) {
        return parts[0].substring(0, 2).toUpperCase();
      }
      return (parts[0][0] + parts.last[0]).toUpperCase();
    }

    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.background,
      title: Text(
        'My Notes',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: theme.iconTheme.color, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 8.0),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Text(
                    getInitials(displayName),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final List<String> chipLabels = [
      'All',
      ..._categories.map((c) => c['nama_kategori'].toString()),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children:
            chipLabels.map((label) {
              final isSelected = _selectedCategory == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: OutlinedButton(
                  onPressed: () => setState(() => _selectedCategory = label),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isSelected
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                    backgroundColor:
                        isSelected ? Colors.grey.shade800 : Colors.transparent,
                    side: BorderSide(
                      color:
                          isSelected
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(label),
                ),
              );
            }).toList(),
      ),
    );
  }

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
              Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No notes found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategory == 'All'
                    ? 'Tap the "+" button to create one.'
                    : 'Create a note in this category.',
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: _filteredNotes.length,
        itemBuilder: (context, index) {
          return _NoteCard(note: _filteredNotes[index], onUpdate: _loadNotes);
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      elevation: 2,
      backgroundColor:
          Colors.grey.shade800, // Matching the primary button style
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InsertNotes()),
        ).then((_) => _loadNotes()); // Refresh notes after returning
      },
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 32.0, color: Colors.white),
    );
  }
}

// --- RE-STYLED NOTE CARD ---

class _NoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onUpdate; // Callback to refresh the list

  const _NoteCard({required this.note, required this.onUpdate});

  String _formatDate(String isoDate) {
    try {
      final dateTime = DateTime.parse(isoDate);
      return DateFormat('d MMM yy').format(dateTime); // e.g., "18 Jun 25"
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryName = note['category']?['nama_kategori'] ?? 'Uncategorized';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => Detailnotes(noteId: note['id'].toString()),
              ),
            ).then(
              (_) => onUpdate(),
            ); // Refresh list after returning from detail
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note['title'] ?? 'No Title',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  note['notes'] ?? 'No content...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        categoryName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
