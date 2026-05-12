import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:sm_networking/infrastructure/model/brand.dart';
import 'package:sm_networking/infrastructure/model/category.dart'; // Add this import
import 'package:path_provider/path_provider.dart';

class CacheServices {
  // Makes this a singleton class, as we want only want a single
  // instance of this object for the whole application
  CacheServices._privateConstructor();

  static final CacheServices instance = CacheServices._privateConstructor();

  static File? _allBrandFile;
  static File? _allCategoryFile; // Add category file

  static const _brandFileName = 'brandFile.txt';
  static const _categoryFileName = 'categoryFile.txt'; // Add category file name

  static final Set<BrandListingModel> _allBrandSet = {};
  static final Set<CategoryListingModel> _allCategorySet = {}; // Add category set

  /// Initialize brand file
  Future<File> _initBrandFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/$_brandFileName');

    // Create the file with empty array if it doesn't exist
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]'); // Initialize with empty JSON array
    }

    return file;
  }

  /// Initialize category file
  Future<File> _initCategoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final file = File('$path/$_categoryFileName');

    // Create the file with empty array if it doesn't exist
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]'); // Initialize with empty JSON array
    }

    return file;
  }

  /// Get the brand data file
  Future<File> get allBrands async {
    if (_allBrandFile != null) return _allBrandFile!;

    _allBrandFile = await _initBrandFile();
    return _allBrandFile!;
  }

  /// Get the category data file
  Future<File> get allCategories async {
    if (_allCategoryFile != null) return _allCategoryFile!;

    _allCategoryFile = await _initCategoryFile();
    return _allCategoryFile!;
  }

  // ==================== BRAND METHODS ====================

  /// Write Brand Data
  Future<void> writeBrands(BrandListingModel dataModel) async {
    try {
      _allBrandSet.clear();
      final File fl = await allBrands;
      _allBrandSet.add(dataModel);
      final brandListMap = _allBrandSet.map((e) => e.toJson()).toList();
      await fl.writeAsString(jsonEncode(brandListMap));
      log('Brand data written successfully');
    } catch (e) {
      log('Error writing brands: $e');
      rethrow;
    }
  }

  /// Read Brand Data
  Future<BrandListingModel?> readBrands() async {
    try {
      final File fl = await allBrands;

      // Check if file exists and has content
      if (!await fl.exists()) {
        log('Brand file does not exist, returning null');
        return null;
      }

      final content = await fl.readAsString();

      // Check if file is empty
      if (content.isEmpty) {
        log('Brand file is empty, returning null');
        return null;
      }

      final List<dynamic> jsonData = jsonDecode(content);

      if (jsonData.isEmpty) {
        log('No brand data found');
        return null;
      }

      final data = jsonData
          .map(
            (e) => BrandListingModel.fromJson(e as Map<String, dynamic>),
      )
          .toList();

      if (data.isNotEmpty) {
        log('Brand data loaded successfully');
        return data[0];
      } else {
        log('Brand data list is empty');
        return null;
      }
    } catch (e) {
      log('Error reading brands: $e');
      return null;
    }
  }

  /// Check if brand data exists
  Future<bool> hasBrandData() async {
    try {
      final data = await readBrands();
      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// Clear all brand data
  Future<void> clearBrandData() async {
    try {
      final File fl = await allBrands;
      await fl.writeAsString('[]');
      _allBrandSet.clear();
      log('Brand data cleared successfully');
    } catch (e) {
      log('Error clearing brand data: $e');
    }
  }

  // ==================== CATEGORY METHODS ====================

  /// Write Category Data
  Future<void> writeCategories(CategoryListingModel dataModel) async {
    try {
      _allCategorySet.clear();
      final File fl = await allCategories;
      _allCategorySet.add(dataModel);
      final categoryListMap = _allCategorySet.map((e) => e.toJson()).toList();
      await fl.writeAsString(jsonEncode(categoryListMap));
      log('Category data written successfully');
    } catch (e) {
      log('Error writing categories: $e');
      rethrow;
    }
  }

  /// Read Category Data
  Future<CategoryListingModel?> readCategories() async {
    try {
      final File fl = await allCategories;

      // Check if file exists and has content
      if (!await fl.exists()) {
        log('Category file does not exist, returning null');
        return null;
      }

      final content = await fl.readAsString();

      // Check if file is empty
      if (content.isEmpty) {
        log('Category file is empty, returning null');
        return null;
      }

      final List<dynamic> jsonData = jsonDecode(content);

      if (jsonData.isEmpty) {
        log('No category data found');
        return null;
      }

      final data = jsonData
          .map(
            (e) => CategoryListingModel.fromJson(e as Map<String, dynamic>),
      )
          .toList();

      if (data.isNotEmpty) {
        log('Category data loaded successfully');
        return data[0];
      } else {
        log('Category data list is empty');
        return null;
      }
    } catch (e) {
      log('Error reading categories: $e');
      return null;
    }
  }

  /// Check if category data exists
  Future<bool> hasCategoryData() async {
    try {
      final data = await readCategories();
      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// Clear all category data
  Future<void> clearCategoryData() async {
    try {
      final File fl = await allCategories;
      await fl.writeAsString('[]');
      _allCategorySet.clear();
      log('Category data cleared successfully');
    } catch (e) {
      log('Error clearing category data: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Clear all cached data (both brands and categories)
  Future<void> clearAllData() async {
    await Future.wait([
      clearBrandData(),
      clearCategoryData(),
    ]);
    log('All cached data cleared');
  }

  /// Check if any cached data exists
  Future<bool> hasAnyData() async {
    final results = await Future.wait([
      hasBrandData(),
      hasCategoryData(),
    ]);
    return results.any((hasData) => hasData);
  }

  /// Get cache status
  Future<Map<String, bool>> getCacheStatus() async {
    final results = await Future.wait([
      hasBrandData(),
      hasCategoryData(),
    ]);

    return {
      'brands': results[0],
      'categories': results[1],
    };
  }
}