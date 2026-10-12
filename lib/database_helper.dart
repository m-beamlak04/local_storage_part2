import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'folder.dart';
import 'card_record.dart';

class DatabaseHelper {
  static const _databaseName = "MyDatabase.db";
  static const _databaseVersion = 2;
  static const table = 'my_table';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnAge = 'age';
  late Database _db;
  // this opens the database (and creates it if it doesn't exist)
  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
CREATE TABLE $table (
$columnId INTEGER PRIMARY KEY,
$columnName TEXT NOT NULL,
$columnAge INTEGER NOT NULL
)
''');

    await _createCatalogueTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCatalogueTables(db);
    }
  }

  Future<void> _createCatalogueTables(Database db) async {
    await db.execute('''
    CREATE TABLE folders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      created_at TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      suit TEXT NOT NULL,
      notes TEXT NOT NULL DEFAULT '',
      image_ref TEXT,
      folder_id INTEGER NOT NULL,
      FOREIGN KEY (folder_id)
        REFERENCES folders(id) ON DELETE CASCADE
    )
  ''');

    await db.execute('''
    CREATE INDEX idx_cards_folder_id
    ON cards(folder_id)
  ''');
  }

  // Helper methods
  // Inserts a row in the database where each key in the
  //Map is a column name
  // and the value is the column value. The return value
  //is the id of the
  // inserted row.
  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(table);
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int> queryRowCount() async {
    final results = await _db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(results) ?? 0;
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(Map<String, dynamic> row) async {
    int id = row[columnId];
    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(int id) async {
    return await _db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // Insert a new folder.
  Future<int> insertFolder(Folder folder) async {
    return await _db.insert('folders', folder.toMap());
  }

// Get all folders along with their card counts.
  Future<List<Map<String, dynamic>>> getFoldersWithCounts() async {
    return await _db.rawQuery('''
    SELECT folders.id,
           folders.name,
           folders.created_at,
           COUNT(cards.id) AS card_count
    FROM folders
    LEFT JOIN cards ON cards.folder_id = folders.id
    GROUP BY folders.id, folders.name, folders.created_at
    ORDER BY folders.name COLLATE NOCASE ASC
  ''');
  }

// Delete a folder using its ID.
  Future<int> deleteFolder(int folderId) async {
    return await _db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [folderId],
    );
  }

  // Add a card to a folder.
  Future<int> insertCard(CardRecord card) async {
    return await _db.insert('cards', card.toMap());
  }

// Get cards belonging to one folder.
  Future<List<CardRecord>> getCards(int folderId) async {
    final rows = await _db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'title COLLATE NOCASE ASC',
    );

    return rows.map((row) => CardRecord.fromMap(row)).toList();
  }

// Update an existing card using its ID.
  Future<int> updateCard(CardRecord card) async {
    if (card.id == null) {
      throw ArgumentError('Cannot update a card without an ID');
    }

    final values = card.toMap()..remove('id');

    return await _db.update(
      'cards',
      values,
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

// Delete a card using its ID.
  Future<int> deleteCard(int cardId) async {
    return await _db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}
