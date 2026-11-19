import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage.dart';

const _favoritesKey = 'vv_favorite_product_ids';

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    _load();
    return <int>{};
  }

  Future<void> _load() async {
    final raw = await SecureStorage.readValue(_favoritesKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = (jsonDecode(raw) as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toSet();
        state = decoded;
      } catch (_) {}
    }
  }

  Future<void> toggleFavorite(int productId) async {
    final updated = Set<int>.from(state);
    if (updated.contains(productId)) {
      updated.remove(productId);
    } else {
      updated.add(productId);
    }
    state = updated;
    await SecureStorage.writeValue(_favoritesKey, jsonEncode(updated.toList()));
  }

  Future<void> clearAll() async {
    state = <int>{};
    await SecureStorage.deleteValue(_favoritesKey);
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<int>>(() {
  return FavoritesNotifier();
});
