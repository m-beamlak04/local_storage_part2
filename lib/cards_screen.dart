import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'card_record.dart';
import 'card_form_screen.dart';

class CardsScreen extends StatefulWidget {
  final DatabaseHelper helper;
  final int folderId;
  final String folderName;

  const CardsScreen({
    super.key,
    required this.helper,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<CardRecord> _cards = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final cards = await widget.helper.getCards(widget.folderId);

      if (!mounted) return;

      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load cards.';
      });

      debugPrint('Card loading failed: $error');
    }
  }

  Future<void> _editCard(CardRecord card) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CardFormScreen(
          helper: widget.helper,
          folderId: widget.folderId,
          existingCard: card,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      await _loadCards();
    }
  }

  Future<void> _addCard() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CardFormScreen(
          helper: widget.helper,
          folderId: widget.folderId,
        ),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      await _loadCards();
    }
  }

  String _suitSymbol(String suit) {
    switch (suit.toLowerCase()) {
      case 'hearts':
        return '♥';
      case 'diamonds':
        return '♦';
      case 'clubs':
        return '♣';
      case 'spades':
        return '♠';
      default:
        return '🃏';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: [
          IconButton(
            tooltip: 'Refresh cards',
            icon: const Icon(Icons.refresh),
            onPressed: _loadCards,
          ),
        ],
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
              onPressed: _loadCards,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _cards.isEmpty
          ? const Center(
        child: Text('No cards in this folder yet.'),
      )
          : ListView.builder(
        itemCount: _cards.length,
        itemBuilder: (context, index) {
          final card = _cards[index];

          return ListTile(
            leading: Text(
              _suitSymbol(card.suit),
              style: const TextStyle(fontSize: 30),
            ),
            title: Text(card.title),
            subtitle: Text(
              'ID: ${card.id} | ${card.suit}',
            ),
            trailing: IconButton(
              tooltip: 'Edit card',
              icon: const Icon(Icons.edit),
              onPressed: () => _editCard(card),
            ),
          );
        },
      ),
    );
  }
}
