part of '../mobile_backend_controller.dart';

extension _MobileBackendCatalogAdapter on MobileBackendController {
  void _applyCatalog(CatalogModel catalog) {
    final adaptedProducts = _adaptProducts(catalog);
    final adaptedCategoryItems = catalog.categories
        .map(
          (category) => MenuCategory(
            id: category.id,
            name: category.name,
            imageUrl: _resolveImageUrl(category.image),
            description: category.description,
          ),
        )
        .toList(growable: true);

    final knownNames = adaptedCategoryItems
        .map((category) => category.name)
        .toSet();
    for (final product in adaptedProducts) {
      if (!knownNames.add(product.category)) continue;
      adaptedCategoryItems.add(
        MenuCategory(id: product.category, name: product.category),
      );
    }

    _menuProducts = adaptedProducts;
    _menuCategoryItems = List<MenuCategory>.unmodifiable(adaptedCategoryItems);
    _menuCategories = _menuCategoryItems
        .map((category) => category.name)
        .toList(growable: false);
  }

  List<MenuProduct> _adaptProducts(CatalogModel catalog) {
    final categoryNameById = <String, String>{
      for (final category in catalog.categories) category.id: category.name,
    };

    return catalog.products
        .where((product) => product.isAvailable)
        .map((product) {
          final category = product.categoryName?.isNotEmpty == true
              ? product.categoryName!
              : categoryNameById[product.categoryId] ?? 'Menu';
          final visual = _visualFor(product.id, product.name, category);

          return MenuProduct(
            id: product.id,
            iikoId: product.iikoId,
            title: product.name,
            price: product.price,
            category: category,
            emoji: visual.emoji,
            tint: visual.tint,
            highlight: visual.highlight,
            imageUrl: _resolveImageUrl(product.image),
            description: product.description,
            calories: product.calories,
            weightGrams: product.weightGrams,
            cookingTimeMinutes: product.cookingTimeMinutes,
            modifierGroups: product.modifierGroups
                .map(
                  (group) => MenuModifierGroup(
                    id: group.id,
                    name: group.name,
                    minSelected: group.minSelected,
                    maxSelected: group.maxSelected,
                    options: group.options
                        .map(
                          (option) => MenuModifierOption(
                            id: option.id,
                            name: option.name,
                            price: option.price,
                            defaultQuantity: option.quantity,
                            isDefault: option.isDefault,
                            isAvailable: option.isAvailable,
                            imageUrl: _resolveImageUrl(option.image),
                          ),
                        )
                        .toList(growable: false),
                  ),
                )
                .toList(growable: false),
          );
        })
        .toList(growable: false);
  }
}

String? _resolveImageUrl(String? value) {
  final imageUrl = value?.trim();
  if (imageUrl == null || imageUrl.isEmpty) return null;

  final parsedUrl = Uri.tryParse(imageUrl);
  if (parsedUrl != null && parsedUrl.hasScheme) return imageUrl;

  final baseUrl = Uri.tryParse(BaseUrl.baseUrl);
  if (baseUrl == null) return imageUrl;

  return baseUrl.resolve(imageUrl).toString();
}

typedef _ProductVisual = ({String emoji, Color tint, Color highlight});

String? _supportedLanguageOrNull(String? language) {
  final normalized = language?.trim().toLowerCase().split(RegExp('[-_]')).first;
  return switch (normalized) {
    'uz' || 'ru' || 'en' => normalized,
    _ => null,
  };
}

const List<_ProductVisual> _fallbackVisuals = <_ProductVisual>[
  (emoji: '🌯', tint: Color(0xFFFFE0D6), highlight: Color(0xFFFFF6F0)),
  (emoji: '🥙', tint: Color(0xFFFFEAD1), highlight: Color(0xFFFFF7EE)),
  (emoji: '🍕', tint: Color(0xFFFFE2D4), highlight: Color(0xFFFFF5F0)),
  (emoji: '🍔', tint: Color(0xFFFFE8C8), highlight: Color(0xFFFFF7EA)),
  (emoji: '🌭', tint: Color(0xFFFFDFC9), highlight: Color(0xFFFFF5EE)),
  (emoji: '🥗', tint: Color(0xFFE4F3D8), highlight: Color(0xFFF6FBF0)),
  (emoji: '🥤', tint: Color(0xFFDDF1FF), highlight: Color(0xFFF3FAFF)),
];

_ProductVisual _visualFor(String id, String name, String category) {
  final text = '$name $category'.toLowerCase();
  if (text.contains('pizza') || text.contains('пиц')) {
    return _fallbackVisuals[2];
  }
  if (text.contains('burger') || text.contains('бургер')) {
    return _fallbackVisuals[3];
  }
  if (text.contains('hot') || text.contains('хот')) {
    return _fallbackVisuals[4];
  }
  if (text.contains('salad') || text.contains('салат')) {
    return _fallbackVisuals[5];
  }
  if (text.contains('cola') ||
      text.contains('pepsi') ||
      text.contains('напит')) {
    return _fallbackVisuals[6];
  }
  return _fallbackVisuals[_stableHash(id) % _fallbackVisuals.length];
}

int _stableHash(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = 0x1fffffff & (hash + codeUnit);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= hash >> 6;
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= hash >> 11;
  hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  return hash;
}
