import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../features/catalog/data/models/product.dart';

/// Base de datos SQLite local estructurada para caché offline del catálogo VintageVibe.
/// Implementa operaciones CRUD reales (INSERT, SELECT, UPDATE, DELETE) sobre la tabla
/// `cached_products` (Práctica 4: Almacenamiento estructurado en dispositivo móvil).
///
/// Es 100% segura en Web/PWA: omite SQLite nativo cuando `kIsWeb` es verdadero.
class LocalCatalogDatabase {
  static const String _dbName = 'vintagevibe_catalog.db';
  static const int _dbVersion = 1;
  static const String tableProducts = 'cached_products';

  Database? _database;
  final DatabaseFactory? _customFactory;
  final String? _customPath;

  LocalCatalogDatabase({
    DatabaseFactory? databaseFactory,
    String? customPath,
  })  : _customFactory = databaseFactory,
        _customPath = customPath;

  static final LocalCatalogDatabase instance = LocalCatalogDatabase();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null && _database!.isOpen) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    final factory = _customFactory ?? databaseFactory;
    final dbPath = _customPath ?? p.join(await getDatabasesPath(), _dbName);

    return factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $tableProducts (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              price REAL NOT NULL,
              category_name TEXT,
              brand_name TEXT,
              condition_name TEXT,
              seller_name TEXT,
              images_json TEXT NOT NULL,
              variants_json TEXT NOT NULL,
              cached_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  /// INSERT / UPSERT individual
  Future<int> insertProduct(Product product) async {
    final db = await database;
    if (db == null) return 0;
    return db.insert(
      tableProducts,
      _toRow(product),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// INSERT masivo en transacción (sincroniza la última respuesta de la API)
  Future<void> saveProducts(List<Product> products) async {
    final db = await database;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete(tableProducts);
      for (final product in products) {
        await txn.insert(
          tableProducts,
          _toRow(product),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// SELECT de todos los productos almacenados localmente
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    if (db == null) return [];
    final rows = await db.query(tableProducts, orderBy: 'id ASC');
    return rows.map(_fromRow).toList();
  }

  /// SELECT individual por ID
  Future<Product?> getProductById(int id) async {
    final db = await database;
    if (db == null) return null;
    final rows = await db.query(
      tableProducts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// UPDATE de un producto almacenado
  Future<int> updateProduct(Product product) async {
    final db = await database;
    if (db == null) return 0;
    return db.update(
      tableProducts,
      _toRow(product),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// DELETE individual por ID
  Future<int> deleteProduct(int id) async {
    final db = await database;
    if (db == null) return 0;
    return db.delete(
      tableProducts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// DELETE de toda la tabla de caché
  Future<int> clearAll() async {
    final db = await database;
    if (db == null) return 0;
    return db.delete(tableProducts);
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Map<String, Object?> _toRow(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'category_name': product.categoryName,
      'brand_name': product.brandName,
      'condition_name': product.conditionName,
      'seller_name': product.sellerName,
      'images_json': jsonEncode(product.images),
      'variants_json': jsonEncode(
        product.variants
            .map((v) => {
                  'id': v.id,
                  'sku': v.sku,
                  'size': v.size,
                  'color': v.color,
                  'stock': v.stock,
                })
            .toList(),
      ),
      'cached_at': DateTime.now().toIso8601String(),
    };
  }

  Product _fromRow(Map<String, Object?> row) {
    final imagesList = (jsonDecode(row['images_json'] as String) as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    final variantsList = (jsonDecode(row['variants_json'] as String) as List<dynamic>)
        .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
        .toList();

    return Product(
      id: row['id'] as int,
      name: row['name'] as String,
      description: row['description'] as String,
      price: (row['price'] as num).toDouble(),
      categoryName: row['category_name'] as String?,
      brandName: row['brand_name'] as String?,
      conditionName: row['condition_name'] as String?,
      sellerName: row['seller_name'] as String?,
      images: imagesList,
      variants: variantsList,
    );
  }
}
