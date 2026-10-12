import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'folders_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final helper = DatabaseHelper();

  try {
    await helper.init();
  } catch (error, stackTrace) {
    debugPrint('Database initialization failed: $error\n$stackTrace');

    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Could not open local storage. Restart the app and check the logs.',
          ),
        ),
      ),
    ));
    return;
  }

  runApp(DirectoryApp(helper: helper));
}

class DirectoryApp extends StatelessWidget {
  final DatabaseHelper helper;

  const DirectoryApp({
    super.key,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DirectoryScreen(helper: helper),
    );
  }
}

class DirectoryScreen extends StatefulWidget {
  final DatabaseHelper helper;

  const DirectoryScreen({
    super.key,
    required this.helper,
  });

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  List<Map<String, dynamic>> _rows = [];
  int _count = 0;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadRows() async {
    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _count = count;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load festival guests.';
      });

      debugPrint('Database read failed: $error');
    }
  }

  Future<void> _saveGuest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());

    setState(() {
      _isBusy = true;
    });

    try {
      int affected;

      if (_selectedId == null) {
        affected = await widget.helper.insert({
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });
      } else {
        affected = await widget.helper.update({
          DatabaseHelper.columnId: _selectedId,
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });
      }

      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _count = count;
        _nameController.clear();
        _ageController.clear();
        _errorMessage = null;
        _selectedId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database result: $affected')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save guest.')),
      );

      debugPrint('Database write failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _startEdit(Map<String, dynamic> row) {
    setState(() {
      _selectedId = row[DatabaseHelper.columnId] as int;
      _nameController.text =
          row[DatabaseHelper.columnName].toString();
      _ageController.text =
          row[DatabaseHelper.columnAge].toString();
    });
  }

  void _cancelEdit() {
    setState(() {
      _selectedId = null;
      _nameController.clear();
      _ageController.clear();
    });
  }

  Future<void> _deleteGuest(Map<String, dynamic> row) async {
    final id = row[DatabaseHelper.columnId] as int;
    final name = row[DatabaseHelper.columnName].toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Guest'),
          content: Text('Delete $name (ID $id)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      final deleted = await widget.helper.delete(id);

      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _count = count;

        if (_selectedId == id) {
          _selectedId = null;
          _nameController.clear();
          _ageController.clear();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database result: $deleted')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete guest.')),
      );

      debugPrint('Database delete failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Festival Roster'),
        actions: [
          IconButton(
            tooltip: 'Open Card Folders',
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FoldersScreen(helper: widget.helper),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isBusy ? null : _loadRows,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                ),
                validator: (value) {
                  final age = int.tryParse(value?.trim() ?? '');

                  if (age == null) {
                    return 'Enter a whole number';
                  }

                  if (age < 0 || age > 130) {
                    return 'Age must be between 0 and 130';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isBusy ? null : _saveGuest,
                child: Text(_selectedId == null ? 'Add Guest' : 'Save Changes'),
              ),

              if (_selectedId != null) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isBusy ? null : _cancelEdit,
                  child: const Text('Cancel Edit'),
                ),
              ],

              const SizedBox(height: 8),

              ElevatedButton(
                onPressed: _isBusy ? null : _loadRows,
                child: const Text('Refresh'),
              ),

              const SizedBox(height: 16),

              Text('Record count: $_count'),
              const SizedBox(height: 16),
              if (_rows.isEmpty)
                const Text('No festival guests yet')
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _rows.length,
                    itemBuilder: (context, index) {
                      final row = _rows[index];

                      return ListTile(
                        title: Text(row[DatabaseHelper.columnName].toString()),
                        subtitle: Text(
                          'ID: ${row[DatabaseHelper.columnId]} | Age: ${row[DatabaseHelper.columnAge]}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _isBusy ? null : () => _startEdit(row),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: _isBusy ? null : () => _deleteGuest(row),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}