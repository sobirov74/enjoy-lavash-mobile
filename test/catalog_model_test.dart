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
              'basePrice': 32000,
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
                      'price': 7000,
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

  test('keeps whole-UZS prices of 100 000 and above unchanged', () {
    // Production prices on 2026-10-07: pizzas at 110 000 and 105 000 UZS were
    // previously divided by 100 by a tiyin heuristic and shown as 1 100.
    final catalog = CatalogModel.fromJson({
      'categories': [
        {
          'id': 'cat-pizza',
          'name': 'Pizza',
          'products': [
            {
              'id': 'pizza-4-seasons',
              'name': '4 сезон 40см',
              'basePrice': 110000,
              'modifierGroups': [
                {
                  'id': 'group-extra',
                  'name': 'Extra',
                  'modifiers': [
                    {'id': 'mod-big', 'name': 'Big', 'price': 100000},
                  ],
                },
              ],
            },
            {'id': 'pizza-enjoy', 'name': 'Enjoy Pizza 45см', 'price': 105000},
            {'id': 'pizza-exact', 'name': 'Exact', 'basePrice': 100000},
          ],
        },
      ],
    });

    final prices = {
      for (final product in catalog.products) product.id: product.price,
    };
    expect(prices, {
      'pizza-4-seasons': 110000,
      'pizza-enjoy': 105000,
      'pizza-exact': 100000,
    });
    final modifier = catalog.products
        .firstWhere((product) => product.id == 'pizza-4-seasons')
        .modifierGroups
        .single
        .options
        .single;
    expect(modifier.price, 100000);
  });
}
