import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/catalog_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses documented nested catalog response', () {
    final catalog = CatalogModel.fromJson({
      'organisationId': 'org-enjoy-lavash',
      'language': 'uz',
      'categories': [
        {
          'id': 'cat-lavash',
          'slug': 'lavash',
          'name': {'ru': 'Лаваш', 'uz': 'Lavashlar'},
          'sortOrder': 1,
          'isActive': true,
          'products': [
            {
              'id': 'prod-classic-lavash',
              'iikoId': 'iiko-classic-lavash',
              'slug': 'classic-lavash',
              'name': {'ru': 'Классический лаваш', 'uz': 'Klassik lavash'},
              'image': '/uploads/products/classic-lavash.jpg',
              'basePrice': 3200000,
              'isAvailable': true,
              'modifierGroups': [
                {
                  'id': 'group-lavash-size',
                  'name': {'ru': 'Размер', 'uz': 'Hajmi'},
                  'minSelect': 1,
                  'maxSelect': 1,
                  'modifiers': [
                    {
                      'id': 'mod-lavash-big',
                      'name': {'ru': 'Большой', 'uz': 'Katta'},
                      'price': 700000,
                    },
                  ],
                },
              ],
            },
          ],
        },
        {
          'id': 'cat-hidden',
          'name': 'Hidden',
          'isActive': false,
          'products': [
            {'id': 'prod-hidden', 'name': 'Hidden product', 'basePrice': 10000},
          ],
        },
      ],
    }, language: 'uz');

    expect(catalog.categories, hasLength(1));
    expect(catalog.categories.single.name, 'Lavashlar');
    expect(catalog.products, hasLength(1));

    final product = catalog.products.single;
    expect(product.id, 'prod-classic-lavash');
    expect(product.iikoId, 'iiko-classic-lavash');
    expect(product.name, 'Klassik lavash');
    expect(product.categoryId, 'cat-lavash');
    expect(product.categoryName, 'Lavashlar');
    expect(product.price, 32000);
    expect(product.image, '/uploads/products/classic-lavash.jpg');
    expect(product.isAvailable, isTrue);

    final group = product.modifierGroups.single;
    expect(group.isRequired, isTrue);
    expect(group.minSelected, 1);
    expect(group.maxSelected, 1);
    expect(group.options.single.price, 7000);
  });
}
