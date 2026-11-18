import 'package:enjoy_lavash_mobile/features/menu/menu_search_index.dart';
import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/menu_catalog.dart';

MenuProduct _product(String id, String title, {String? description}) =>
    MenuProduct(
      id: id,
      title: title,
      price: 30000,
      category: 'Ichimliklar',
      emoji: '🥤',
      tint: Colors.orange,
      highlight: Colors.amber,
      description: description,
    );

List<String> _ids(List<MenuProduct> products) =>
    products.map((product) => product.id).toList();

void main() {
  group('foldSearchText', () {
    test('old and reformed Uzbek spellings fold to the same text', () {
      expect(
        foldSearchText('Ço‘p şirin göşt'),
        foldSearchText("Cho'p shirin go'sht"),
      );
      expect(foldSearchText("Tog'ora"), foldSearchText('Toğora'));
    });

    test('Cyrillic folds to Latin, case and punctuation are ignored', () {
      expect(foldSearchText('ЛАВАШ, куриный!'), 'lavash kuriniy');
      expect(foldSearchText('Хот-дог'), foldSearchText('hotdog'));
      expect(foldSearchText('  qovun   '), foldSearchText('ковун'));
    });
  });

  group('MenuSearchIndex', () {
    final index = MenuSearchIndex(menuProducts);

    test('an empty or blank query matches every product', () {
      expect(index.search(''), same(menuProducts));
      expect(index.search("  ' "), same(menuProducts));
    });

    test('finds products across scripts and spellings', () {
      expect(
        _ids(index.search('lavash')),
        containsAll(<String>[
          'lavash-cheese',
          'lavash-classic',
          'lavash-set',
          'lavash-big',
        ]),
      );
      expect(_ids(index.search('hot dog')), <String>['hotdog']);
      expect(_ids(index.search('бургер')), <String>['burger-classic']);
    });

    test('every word must match', () {
      expect(_ids(index.search('лаваш сыр')), <String>['lavash-cheese']);
      expect(index.search('лаваш пицца'), isEmpty);
    });

    test('title matches rank above description matches, menu order within', () {
      final products = <MenuProduct>[
        _product('juice', 'Apelsin şarbati', description: 'Choy bilan'),
        _product('green-tea', 'Yashil çoy'),
        _product('black-tea', 'Qora choy'),
        _product('tea-pot', 'Çoynak çoy'),
      ];
      final results = MenuSearchIndex(products).search('choy');
      expect(_ids(results), <String>[
        'tea-pot', // title starts with the query
        'green-tea', // a title word starts with it
        'black-tea',
        'juice', // only the description matches
      ]);
    });
  });
}
