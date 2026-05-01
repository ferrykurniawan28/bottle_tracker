import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/stored_model.dart';
import '../models/device_model.dart';
import '../../core/constants/app_constants.dart';

class BottleService {
  final _storage = GetStorage();
  final _uuid = const Uuid();

  // ── Catalog (admin-managed bar bottles) ──

  List<CatalogBottle> getCatalogBottles() {
    final data = _storage.read<String>(AppConstants.catalogKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => CatalogBottle.fromJson(e)).toList();
  }

  void _saveCatalog(List<CatalogBottle> bottles) {
    _storage.write(
      AppConstants.catalogKey,
      jsonEncode(bottles.map((e) => e.toJson()).toList()),
    );
  }

  CatalogBottle addCatalogBottle({
    required String name,
    required String brand,
    required String category,
  }) {
    final bottles = getCatalogBottles();
    final bottle = CatalogBottle(
      id: _uuid.v4(),
      name: name,
      brand: brand,
      category: category,
    );
    bottles.add(bottle);
    _saveCatalog(bottles);
    return bottle;
  }

  void updateCatalogBottle(CatalogBottle bottle) {
    final bottles = getCatalogBottles();
    final index = bottles.indexWhere((b) => b.id == bottle.id);
    if (index != -1) {
      bottles[index] = bottle;
      _saveCatalog(bottles);
    }
  }

  void deleteCatalogBottle(String id) {
    final bottles = getCatalogBottles();
    bottles.removeWhere((b) => b.id == id);
    _saveCatalog(bottles);
  }

  // ── User-stored bottles ──

  List<BottleModel> _getBottles() {
    final data = _storage.read<String>(AppConstants.bottlesKey);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => BottleModel.fromJson(e)).toList();
  }

  void _saveBottles(List<BottleModel> bottles) {
    _storage.write(
      AppConstants.bottlesKey,
      jsonEncode(bottles.map((e) => e.toJson()).toList()),
    );
  }

  List<BottleModel> getAllBottles() => _getBottles();

  List<BottleModel> getBottlesByUserId(String userId) {
    return _getBottles().where((b) => b.userId == userId).toList();
  }

  BottleModel storeBottle({
    required String userId,
    required String catalogBottleId,
    required String name,
    required String brand,
    required String category,
    required double weightGrams,
    String? notes,
  }) {
    final bottles = _getBottles();
    final bottle = BottleModel(
      id: _uuid.v4(),
      userId: userId,
      name: name,
      brand: brand,
      category: category,
      weightGrams: weightGrams,
      currentWeightGrams: weightGrams,
      notes: notes,
    );
    bottles.add(bottle);
    _saveBottles(bottles);
    return bottle;
  }

  void updateBottle(BottleModel bottle) {
    final bottles = _getBottles();
    final index = bottles.indexWhere((b) => b.id == bottle.id);
    if (index != -1) {
      bottles[index] = bottle;
      _saveBottles(bottles);
    }
  }

  void deleteBottle(String id) {
    final bottles = _getBottles();
    bottles.removeWhere((b) => b.id == id);
    _saveBottles(bottles);
  }

  void deleteBottlesByUserId(String userId) {
    final bottles = _getBottles();
    bottles.removeWhere((b) => b.userId == userId);
    _saveBottles(bottles);
  }
}
