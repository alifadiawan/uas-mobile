import 'package:flutter/material.dart';
import 'package:mobile_uas/widgets/CustomBottomNavBar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_uas/Category/CategoryCreate.dart';

class Categoryindex extends StatefulWidget {
  const Categoryindex({super.key});

  @override
  State<Categoryindex> createState() => _CategoryindexState();
}

class _CategoryindexState extends State<Categoryindex> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    // Added a small delay to show loading indicator for quick fetches
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final response = await Supabase.instance.client
          .from('category')
          .select('id, nama_kategori')
          .order('nama_kategori');

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load categories.')),
        );
      }
    }
  }

  // --- NEW: Implemented Delete Function with Confirmation ---
  Future<void> _deleteCategory(int id, String categoryName) async {
    // Show a confirmation dialog before deleting
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to delete the category "$categoryName"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User cancels
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true), // User confirms
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // If the user did not confirm, do nothing.
    if (confirm != true) {
      return;
    }

    // If confirmed, proceed with deletion from Supabase
    try {
      await Supabase.instance.client.from('category').delete().match({
        'id': id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$categoryName" was deleted.'),
            backgroundColor: Colors.green,
          ),
        );
        // Remove the category from the local list instantly for a smoother UI response
        setState(() {
          _categories.removeWhere((category) => category['id'] == id);
        });
      }
    } catch (e) {
      print('Error deleting category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Placeholder for edit function
  void _editCategory(Map<String, dynamic> category) {
    // TODO: Navigate to an edit screen, passing the category data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulating edit for: ${category['nama_kategori']}'),
      ),
    );
  }

  void _navigateAndRefresh() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryCreate()),
    );
    if (created == true && mounted) {
      _fetchCategories(); // Refresh after adding
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Categories',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildCategoryContent(),
      floatingActionButton: _buildFloatingActionButton(), // Use the FAB
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        _navigateAndRefresh(); // Navigate to create category screen
      },
      backgroundColor: Colors.grey.shade800,
      icon: const Icon(Icons.add, size: 32.0, color: Colors.white),
      label: const Text(
        'New Category',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryContent() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No categories found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the "+" button to create your first one.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _CategoryListItem(
          category: category,
          onEdit: () => _editCategory(category),
          // Pass category name to delete function for the confirmation dialog
          onDelete:
              () => _deleteCategory(category['id'], category['nama_kategori']),
        );
      },
    );
  }
}

// This widget does not need any changes.
class _CategoryListItem extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryListItem({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.folder_outlined, color: theme.colorScheme.primary),
        ),
        title: Text(
          category['nama_kategori'] ?? 'Unnamed Category',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder:
              (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
          icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}
