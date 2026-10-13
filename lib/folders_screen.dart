import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'folder.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  final DatabaseHelper helper;

  const FoldersScreen({super.key, required this.helper});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<Map<String, dynamic>> _folders = [];
  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await widget.helper.getFoldersWithCounts();

      if (!mounted) return;

      setState(() {
        _folders = folders;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load folders.';
      });

      debugPrint('Folder loading failed: $error');
    }
  }

  Future<void> _addFolder() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Folder'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Folder name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter a folder name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || !mounted) return;

    setState(() => _isBusy = true);

    try {
      await widget.helper.insertFolder(
        Folder(
          name: name,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      await _loadFolders();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add folder. The name may already exist.'),
        ),
      );
      debugPrint('Folder insert failed: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteFolder(Map<String, dynamic> folder) async {
    final id = folder['id'] as int;
    final name = folder['name'].toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(
          'Delete "$name" and all cards inside it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);

    try {
      final deleted = await widget.helper.deleteFolder(id);

      if (!mounted) return;

      if (deleted == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder no longer exists.')),
        );
      }

      await _loadFolders();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete folder.')),
      );
      debugPrint('Folder delete failed: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Folders'),
        actions: [
          IconButton(
            tooltip: 'Refresh folders',
            onPressed: _isBusy ? null : _loadFolders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isBusy ? null : _addFolder,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            ElevatedButton(
              onPressed: _loadFolders,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _folders.isEmpty
          ? const Center(
        child: Text('No folders yet. Tap + to add one.'),
      )
          : ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final folder = _folders[index];
          final count = folder['card_count'] ?? 0;

          return ListTile(
            title: Text(folder['name'].toString()),
            subtitle: Text('$count cards'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isBusy
                  ? null
                  : () => _deleteFolder(folder),
            ),
            onTap: _isBusy
                ? null
                : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardsScreen(
                    helper: widget.helper,
                    folderId: folder['id'] as int,
                    folderName: folder['name'].toString(),
                  ),
                ),
              );

              if (!mounted) return;
              await _loadFolders();
            },
          );
        },
      ),
    );
  }
}
