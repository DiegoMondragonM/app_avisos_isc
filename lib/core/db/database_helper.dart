import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'avisos_isc.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE publicaciones (
        id            INTEGER PRIMARY KEY,
        titulo        TEXT NOT NULL,
        descripcion   TEXT,
        tipo          TEXT NOT NULL,
        fuente        TEXT NOT NULL,
        estado        TEXT NOT NULL,
        link          TEXT,
        imagen_url    TEXT,
        fecha_inicio          TEXT,
        fecha_fin             TEXT,
        fecha_inscripcion_inicio TEXT,
        fecha_inscripcion_fin    TEXT,
        hash_origen   TEXT,
        created_at    TEXT,
        updated_at    TEXT,
        deleted_at    TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE publicacion_tags (
        publicacion_id INTEGER NOT NULL,
        tag_id         INTEGER NOT NULL,
        tag_nombre     TEXT NOT NULL,
        tag_slug       TEXT NOT NULL,
        PRIMARY KEY (publicacion_id, tag_id)
      )
    ''');
  }

  // ---- Publicaciones ----

  Future<void> upsertPublicacion(Map<String, dynamic> data) async {
    final db = await database;
    final tags = data['tags'] as List<dynamic>? ?? [];
    final row = Map<String, dynamic>.from(data)..remove('tags');

    await db.insert('publicaciones', row,
        conflictAlgorithm: ConflictAlgorithm.replace);

    await db.delete('publicacion_tags',
        where: 'publicacion_id = ?', whereArgs: [data['id']]);

    for (final tag in tags) {
      await db.insert('publicacion_tags', {
        'publicacion_id': data['id'],
        'tag_id': tag['id'],
        'tag_nombre': tag['nombre'],
        'tag_slug': tag['slug'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> removePublicacion(int id) async {
    final db = await database;
    await db.delete('publicaciones', where: 'id = ?', whereArgs: [id]);
    await db.delete('publicacion_tags',
        where: 'publicacion_id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPublicaciones() async {
    final db = await database;
    final rows = await db.query('publicaciones',
        where: "estado = 'publicada'", orderBy: 'updated_at DESC');
    return Future.wait(rows.map((row) async {
      final tags = await db.query('publicacion_tags',
          where: 'publicacion_id = ?', whereArgs: [row['id']]);
      return {
        ...row,
        'tags': tags
            .map((t) => {
                  'id': t['tag_id'],
                  'nombre': t['tag_nombre'],
                  'slug': t['tag_slug'],
                })
            .toList(),
      };
    }));
  }

  /// Devuelve publicaciones cuyo estado es 'publicada' y que tienen
  /// AL MENOS UN tag cuyo slug esté en [slugs].
  Future<List<Map<String, dynamic>>> getPublicacionesByTagSlugs(
      List<String> slugs) async {
    if (slugs.isEmpty) return getPublicaciones();
    final db = await database;
    final placeholders = slugs.map((_) => '?').join(', ');
    final rows = await db.rawQuery('''
      SELECT DISTINCT p.*
      FROM publicaciones p
      INNER JOIN publicacion_tags pt ON p.id = pt.publicacion_id
      WHERE p.estado = 'publicada'
        AND pt.tag_slug IN ($placeholders)
      ORDER BY p.updated_at DESC
    ''', slugs);

    return Future.wait(rows.map((row) async {
      final tags = await db.query('publicacion_tags',
          where: 'publicacion_id = ?', whereArgs: [row['id']]);
      return {
        ...row,
        'tags': tags
            .map((t) => {
                  'id': t['tag_id'],
                  'nombre': t['tag_nombre'],
                  'slug': t['tag_slug'],
                })
            .toList(),
      };
    }));
  }

  Future<Map<String, dynamic>?> getPublicacion(int id) async {
    final db = await database;
    final rows = await db.query('publicaciones',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final tags = await db.query('publicacion_tags',
        where: 'publicacion_id = ?', whereArgs: [id]);
    return {
      ...rows.first,
      'tags': tags
          .map((t) => {
                'id': t['tag_id'],
                'nombre': t['tag_nombre'],
                'slug': t['tag_slug'],
              })
          .toList(),
    };
  }
}
