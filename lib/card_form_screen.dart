
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'card_record.dart';

class CardFormScreen extends StatefulWidget {
  final DatabaseHelper helper;
  final int folderId;
  final CardRecord? existingCard;

  const CardFormScreen({
    super.key,
    required this.helper,
    required this.folderId,
    this.existingCard,
  });

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _imageController = TextEditingController();

  static const _suits = [
    'Hearts',
    'Diamonds',
    'Clubs',
    'Spades',
  ];

  String? _selectedSuit;
  int? _selectedFolderId;
  List<Map<String, dynamic>> _folders = [];

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();

    final card = widget.existingCard;
    _selectedFolderId = card?.folderId ?? widget.folderId;

    if (card != null) {
      _titleController.text = card.title;
      _notesController.text = card.notes;
      _imageController.text = card.imageRef ?? '';

      for (final suit in _suits) {
        if (suit.toLowerCase() == card.suit.toLowerCase()) {
          _selectedSuit = suit;
          break;
        }
      }
    }

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

      debugPrint('Form folder loading failed: $error');
    }
  }

  Future<void> _saveCard() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final imageText = _imageController.text.trim();

    final card = CardRecord(
      id: widget.existingCard?.id,
      title: _titleController.text.trim(),
      suit: _selectedSuit!,
      notes: _notesController.text.trim(),
      imageRef: imageText.isEmpty ? null : imageText,
      folderId: _selectedFolderId!,
    );

    try {
      if (_isEditing) {
        final updated = await widget.helper.updateCard(card);

        if (updated == 0) {
          throw StateError('Card no longer exists.');
        }
      } else {
        await widget.helper.insertCard(card);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save card. Please try again.'),
        ),
      );

      debugPrint('Card save failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Card' : 'Add Card'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadFolders();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Card title',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a card title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedSuit,
              decoration: const InputDecoration(
                labelText: 'Suit',
              ),
              items: _suits.map((suit) {
                return DropdownMenuItem(
                  value: suit,
                  child: Text(suit),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                setState(() => _selectedSuit = value);
              },
              validator: (value) {
                if (value == null || !_suits.contains(value)) {
                  return 'Select a valid suit';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _folders.any(
                    (folder) => folder['id'] == _selectedFolderId,
              )
                  ? _selectedFolderId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Folder',
              ),
              items: _folders.map((folder) {
                return DropdownMenuItem<int>(
                  value: folder['id'] as int,
                  child: Text(folder['name'].toString()),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                setState(() => _selectedFolderId = value);
              },
              validator: (value) {
                if (value == null ||
                    !_folders.any(
                          (folder) => folder['id'] == value,
                    )) {
                  return 'Select a valid folder';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageController,
              decoration: const InputDecoration(
                labelText: 'Image reference (optional)',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveCard,
              child: Text(
                _isSaving
                    ? 'Saving...'
                    : _isEditing
                    ? 'Save Changes'
                    : 'Add Card',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
