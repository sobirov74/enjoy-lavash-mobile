import 'json_helpers.dart';

class CatalogModel {
  CatalogModel._({
    required List<CatalogCategoryModel> categories,
    required List<CatalogProductModel> products,
    required Map<String, List<CatalogProductModel>> productsByCategoryId,
  }) : categories = List<CatalogCategoryModel>.unmodifiable(categories),
       products = List<CatalogProductModel>.unmodifiable(products),
       productsByCategoryId =
           Map<String, List<CatalogProductModel>>.unmodifiable(
             productsByCategoryId.map(
               (key, value) =>
                   MapEntry(key, List<CatalogProductModel>.unmodifiable(value)),
             ),
           );

  final List<CatalogCategoryModel> categories;
  final List<CatalogProductModel> products;
  final Map<String, List<CatalogProductModel>> productsByCategoryId;

  factory CatalogModel.fromJson(Object? data, {String language = 'ru'}) {
    final categoryMaps = _extractCategoryMaps(data);
    final explicitProductMaps = _extractProductMaps(data);
    final categories = <CatalogCategoryModel>[];
    final products = <CatalogProductModel>[];

    for (final categoryJson in categoryMaps) {
      final category = CatalogCategoryModel.fromJson(
        categoryJson,
        language: language,
      );
      if (!category.isActive) continue;

      categories.add(category);

      final nestedProducts = asJsonMapList(
        categoryJson['products'] ??
            categoryJson['items'] ??
            categoryJson['productItems'],
      );

      for (final productJson in nestedProducts) {
        products.add(
          CatalogProductModel.fromJson(
            productJson,
            language: language,
            fallbackCategoryId: category.id,
            fallbackCategoryName: category.name,
          ),
        );
      }
    }

    for (final productJson in explicitProductMaps) {
      products.add(
        CatalogProductModel.fromJson(productJson, language: language),
      );
    }

    final mergedCategories = _mergeCategories(categories, products);
    final grouped = _groupProductsByCategory(products);

    return CatalogModel._(
      categories: mergedCategories,
      products: products,
      productsByCategoryId: grouped,
    );
  }

  CatalogProductModel? productByIdOrSlug(String idOrSlug) {
    for (final product in products) {
      if (product.id == idOrSlug || product.slug == idOrSlug) return product;
    }
    return null;
  }
}

class CatalogCategoryModel {
  const CatalogCategoryModel({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.image,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String? image;
  final int sortOrder;
  final bool isActive;

  factory CatalogCategoryModel.fromJson(
    Map<String, dynamic> json, {
    String language = 'ru',
  }) {
    final id = readString(json, const [
      'id',
      'categoryId',
      'category_id',
      'slug',
    ]);
    return CatalogCategoryModel(
      id: id,
      name: localizedText(
        json['name'] ?? json['title'],
        language,
        fallback: readString(json, const ['name', 'title'], fallback: id),
      ),
      slug: stringOrNull(json['slug']),
      description: localizedText(
        json['description'],
        language,
        fallback: readString(json, const ['description']),
      ),
      image: _readImageUrl(json),
      sortOrder: readInt(json, const ['sortOrder', 'sort_order', 'position']),
      isActive: readBool(json, const [
        'isActive',
        'is_active',
        'active',
      ], fallback: true),
    );
  }
}

class CatalogProductModel {
  CatalogProductModel({
    required this.id,
    required this.name,
    required this.price,
    required List<CatalogModifierGroupModel> modifierGroups,
    this.iikoId,
    this.slug,
    this.description,
    this.image,
    this.calories,
    this.weightGrams,
    this.cookingTimeMinutes,
    this.categoryId,
    this.categoryName,
    this.isAvailable = true,
    this.raw = const <String, dynamic>{},
  }) : modifierGroups = List<CatalogModifierGroupModel>.unmodifiable(
         modifierGroups,
       );

  final String id;
  final String? iikoId;
  final String name;
  final int price;
  final List<CatalogModifierGroupModel> modifierGroups;
  final String? slug;
  final String? description;
  final String? image;
  final int? calories;
  final int? weightGrams;
  final int? cookingTimeMinutes;
  final String? categoryId;
  final String? categoryName;
  final bool isAvailable;
  final Map<String, dynamic> raw;

  bool get hasRequiredModifiers {
    return modifierGroups.any((group) => group.isRequired);
  }

  factory CatalogProductModel.fromJson(
    Map<String, dynamic> json, {
    String language = 'ru',
    String? fallbackCategoryId,
    String? fallbackCategoryName,
  }) {
    final category = asJsonMap(json['category']);
    final categoryId =
        stringOrNull(json['categoryId']) ??
        stringOrNull(json['category_id']) ??
        stringOrNull(category['id']) ??
        fallbackCategoryId;
    final categoryName = localizedText(
      json['categoryName'] ?? json['category_name'] ?? category['name'],
      language,
      fallback: fallbackCategoryName ?? '',
    );

    return CatalogProductModel(
      id: readString(json, const ['id']),
      iikoId: stringOrNull(
        json['iikoId'] ??
            json['iiko_id'] ??
            json['iikoProductId'] ??
            json['iiko_product_id'],
      ),
      slug: stringOrNull(json['slug']),
      name: localizedText(
        json['name'] ?? json['title'],
        language,
        fallback: readString(json, const ['name', 'title']),
      ),
      description: localizedText(
        json['description'],
        language,
        fallback: readString(json, const ['description']),
      ),
      price: _normalizePrice(
        readInt(json, const ['price', 'amount', 'basePrice', 'base_price']),
      ),
      image: _readImageUrl(json),
      calories: _optionalPositiveInt(json, const [
        'calories',
        'caloriesKcal',
        'calories_kcal',
      ]),
      weightGrams: _optionalPositiveInt(json, const [
        'weightGrams',
        'weight_grams',
      ]),
      cookingTimeMinutes: _optionalPositiveInt(json, const [
        'cookingTimeMinutes',
        'cooking_time_minutes',
      ]),
      categoryId: categoryId,
      categoryName: categoryName.isEmpty ? fallbackCategoryName : categoryName,
      isAvailable: readBool(json, const [
        'isAvailable',
        'is_available',
        'available',
        'isActive',
        'is_active',
        'active',
      ], fallback: true),
      modifierGroups:
          asJsonMapList(
                json['modifierGroups'] ??
                    json['modifier_groups'] ??
                    json['modifiersGroups'],
              )
              .map(
                (group) => CatalogModifierGroupModel.fromJson(
                  group,
                  language: language,
                ),
              )
              .toList(growable: false),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

class CatalogModifierGroupModel {
  CatalogModifierGroupModel({
    required this.id,
    required this.name,
    required List<CatalogModifierOptionModel> options,
    this.minSelected = 0,
    this.maxSelected = 1,
  }) : options = List<CatalogModifierOptionModel>.unmodifiable(options);

  final String id;
  final String name;
  final int minSelected;
  final int maxSelected;
  final List<CatalogModifierOptionModel> options;

  bool get isRequired => minSelected > 0;

  factory CatalogModifierGroupModel.fromJson(
    Map<String, dynamic> json, {
    String language = 'ru',
  }) {
    return CatalogModifierGroupModel(
      id: readString(json, const ['id']),
      name: localizedText(
        json['name'] ?? json['title'],
        language,
        fallback: readString(json, const ['name', 'title']),
      ),
      minSelected: readInt(json, const [
        'minSelect',
        'min_select',
        'minSelected',
        'min_selected',
        'min',
      ]),
      maxSelected: readInt(json, const [
        'maxSelect',
        'max_select',
        'maxSelected',
        'max_selected',
        'max',
      ], fallback: 1),
      options:
          asJsonMapList(json['modifiers'] ?? json['options'] ?? json['items'])
              .map(
                (option) => CatalogModifierOptionModel.fromJson(
                  option,
                  language: language,
                ),
              )
              .toList(growable: false),
    );
  }
}

class CatalogModifierOptionModel {
  const CatalogModifierOptionModel({
    required this.id,
    required this.name,
    this.price = 0,
    this.quantity = 1,
    this.image,
    this.isDefault = false,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final int price;
  final int quantity;
  final String? image;
  final bool isDefault;
  final bool isAvailable;

  factory CatalogModifierOptionModel.fromJson(
    Map<String, dynamic> json, {
    String language = 'ru',
  }) {
    return CatalogModifierOptionModel(
      id: readString(json, const ['id', 'modifierId', 'modifier_id']),
      name: localizedText(
        json['name'] ?? json['title'],
        language,
        fallback: readString(json, const ['name', 'title']),
      ),
      price: _normalizePrice(readInt(json, const ['price', 'amount'])),
      quantity: readInt(json, const ['quantity'], fallback: 1),
      image: _readImageUrl(json),
      isDefault: readBool(json, const ['isDefault', 'is_default']),
      isAvailable: readBool(json, const [
        'isAvailable',
        'is_available',
        'available',
      ], fallback: true),
    );
  }
}

List<Map<String, dynamic>> _extractCategoryMaps(Object? data) {
  final map = asJsonMap(data);
  if (map.isNotEmpty) {
    final direct = asJsonMapList(map['categories']);
    if (direct.isNotEmpty) return direct;

    final items = asJsonMapList(map['items']);
    if (items.any(_looksLikeCategory)) {
      return items.where(_looksLikeCategory).toList(growable: false);
    }
  }

  final list = asJsonMapList(data);
  if (list.any(_looksLikeCategory)) {
    return list.where(_looksLikeCategory).toList(growable: false);
  }

  return const <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _extractProductMaps(Object? data) {
  final map = asJsonMap(data);
  if (map.isNotEmpty) {
    final products = asJsonMapList(map['products']);
    if (products.isNotEmpty) return products;

    final items = asJsonMapList(map['items']);
    if (items.any(_looksLikeProduct)) {
      return items.where(_looksLikeProduct).toList(growable: false);
    }
  }

  final list = asJsonMapList(data);
  if (list.any(_looksLikeProduct) && !list.any(_looksLikeCategory)) {
    return list.where(_looksLikeProduct).toList(growable: false);
  }

  return const <Map<String, dynamic>>[];
}

bool _looksLikeCategory(Map<String, dynamic> json) {
  return json.containsKey('products') ||
      json.containsKey('productItems') ||
      json.containsKey('children');
}

bool _looksLikeProduct(Map<String, dynamic> json) {
  return json.containsKey('price') ||
      json.containsKey('basePrice') ||
      json.containsKey('base_price') ||
      json.containsKey('modifierGroups') ||
      json.containsKey('modifier_groups');
}

List<CatalogCategoryModel> _mergeCategories(
  List<CatalogCategoryModel> categories,
  List<CatalogProductModel> products,
) {
  final byId = <String, CatalogCategoryModel>{};
  for (final category in categories) {
    byId[category.id] = category;
  }

  for (final product in products) {
    final categoryId = product.categoryId;
    if (categoryId == null ||
        categoryId.isEmpty ||
        byId.containsKey(categoryId)) {
      continue;
    }
    byId[categoryId] = CatalogCategoryModel(
      id: categoryId,
      name: product.categoryName?.isNotEmpty == true
          ? product.categoryName!
          : categoryId,
    );
  }

  final merged = byId.values.toList(growable: false)
    ..sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      return orderCompare == 0 ? a.name.compareTo(b.name) : orderCompare;
    });
  return merged;
}

Map<String, List<CatalogProductModel>> _groupProductsByCategory(
  List<CatalogProductModel> products,
) {
  final grouped = <String, List<CatalogProductModel>>{};
  for (final product in products) {
    final categoryId = product.categoryId;
    if (categoryId == null || categoryId.isEmpty) continue;
    (grouped[categoryId] ??= <CatalogProductModel>[]).add(product);
  }
  return grouped;
}

int _normalizePrice(int value) {
  if (value >= 100000 && value % 100 == 0) return value ~/ 100;
  return value;
}

int? _optionalPositiveInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final parsed = switch (value) {
      int() => value,
      num() => value.toInt(),
      String() => int.tryParse(value),
      _ => null,
    };
    if (parsed != null && parsed > 0) return parsed;
  }
  return null;
}

String? _readImageUrl(JsonMap json) {
  for (final key in const [
    'image',
    'imageUrl',
    'image_url',
    'photo',
    'photoUrl',
    'photo_url',
    'thumbnail',
    'thumbnailUrl',
    'thumbnail_url',
  ]) {
    final candidate = _imageUrlFromValue(json[key]);
    if (candidate != null) return candidate;
  }

  for (final image in asObjectList(json['images'])) {
    final candidate = _imageUrlFromValue(image);
    if (candidate != null) return candidate;
  }

  return null;
}

String? _imageUrlFromValue(Object? value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  final map = asJsonMap(value);
  if (map.isEmpty) return null;

  for (final key in const [
    'url',
    'src',
    'path',
    'image',
    'imageUrl',
    'image_url',
  ]) {
    final candidate = _imageUrlFromValue(map[key]);
    if (candidate != null) return candidate;
  }

  return null;
}
