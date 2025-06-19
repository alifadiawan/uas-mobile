import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryCreate extends StatefulWidget {
  const CategoryCreate({super.key});

  @override
  State<CategoryCreate> createState() => _CategoryCreateState();
}

class _CategoryCreateState extends State<CategoryCreate> {
  final _formKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();
  bool _isLoading = false;

  // Supabase client is already available via the singleton instance
  final _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _categoryNameController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    // 1. Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Set loading state
    setState(() {
      _isLoading = true;
    });

    final categoryName = _categoryNameController.text.trim();

    try {
      // 3. Perform the insert operation
      await _supabase
          .from('category') // Your table name
          .insert({'nama_kategori': categoryName});

      // 4. Show success feedback and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$categoryName" added successfully!'),
            backgroundColor: Colors.green[600],
          ),
        );
        // Pop the screen and return 'true' to indicate success
        Navigator.of(context).pop(true);
      }
    } on PostgrestException catch (e) {
      // Handle potential database errors, like unique constraint violations
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add category: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // Handle other generic errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // 5. Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
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
        title: const Text('New Category'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- Enhanced Text Field ---
                TextFormField(
                  controller: _categoryNameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.folder_open_outlined),
                    labelText: 'Category Name',
                    hintText: 'e.g., Work, Personal, Shopping',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a category name.';
                    }
                    if (value.length > 50) {
                      return 'Name cannot exceed 50 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // --- Improved Submit Button with Loading Indicator ---
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(
                      'Create Category',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _isLoading ? null : _addCategory,
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
