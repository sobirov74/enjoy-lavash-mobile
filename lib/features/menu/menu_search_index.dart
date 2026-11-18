import 'package:enjoy_lavash_mobile/features/models/menu_product.dart';

/// Text search over one menu. The products' text is folded once, when the
/// index is made; each query then only scans the folded strings.
///
/// A product matches when every word of the query appears in its title,
/// category or description. Matches keep the menu order inside each rank:
/// titles that start with the query, then titles where every word starts a
/// title word, then titles containing every word, then the rest.
class MenuSearchIndex {
  MenuSearchIndex(this.products)
    : _entries = List<_SearchEntry>.unmodifiable(
        products.map(_SearchEntry.new),
      );

  /// The products this index was built for, in menu order.
  final List<MenuProduct> products;
  final List<_SearchEntry> _entries;

  /// Products matching [query], best first. A query with no searchable
  /// characters matches everything.
  List<MenuProduct> search(String query) {
    final folded = foldSearchText(query);
    if (folded.isEmpty) return products;
    final words = folded.split(' ');

    final matches = <({int rank, int order})>[];
    for (var order = 0; order < _entries.length; order++) {
      final rank = _entries[order].rank(folded, words);
      if (rank != null) matches.add((rank: rank, order: order));
    }
    matches.sort(
      (a, b) => a.rank != b.rank ? a.rank - b.rank : a.order - b.order,
    );
    return List<MenuProduct>.unmodifiable(
      matches.map((match) => products[match.order]),
    );
  }
}

class _SearchEntry {
  _SearchEntry(MenuProduct product)
    : title = foldSearchText(product.title),
      rest = foldSearchText('${product.category} ${product.description ?? ''}');

  final String title;
  final String rest;

  static const int _titleStart = 0;
  static const int _titleWordStarts = 1;
  static const int _titleContains = 2;
  static const int _elsewhere = 3;

  int? rank(String query, List<String> words) {
    if (!words.every((word) => title.contains(word) || rest.contains(word))) {
      return null;
    }
    if (title.startsWith(query)) return _titleStart;
    final spacedTitle = ' $title';
    if (words.every((word) => spacedTitle.contains(' $word'))) {
      return _titleWordStarts;
    }
    if (words.every(title.contains)) return _titleContains;
    return _elsewhere;
  }
}

/// Lower-cases [text] and folds away differences a customer should not have
/// to match exactly: the reformed and the old Uzbek Latin spellings
/// (`ö`/`o'`, `ş`/`sh`, `ç`/`ch`, `ğ`/`g'`), apostrophes, hyphens
/// ("hot-dog" = "hotdog"), `x`/`h` and `q`/`k`, and Cyrillic, which is
/// written in Latin letters ("лаваш" = "lavash"). Punctuation becomes a
/// space; runs of spaces become one.
String foldSearchText(String text) {
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final folded = _foldedLetters[char];
    if (folded != null) {
      buffer.write(folded);
    } else if (_separators.hasMatch(char)) {
      buffer.write(' ');
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString().replaceAll(_spaceRun, ' ').trim();
}

final RegExp _separators = RegExp(r'[\s.,;:!?()\[\]{}/\\|+&*"«»“”„#№%]');
final RegExp _spaceRun = RegExp(r' {2,}');

const Map<String, String> _foldedLetters = <String, String>{
  // Dropped: apostrophes (o'/oʻ), hyphens, the combining dot of a
  // lower-cased `İ`, and the Cyrillic hard and soft signs.
  "'": '', 'ʻ': '', 'ʼ': '', '‘': '', '’': '', '`': '', '-': '', '‐': '',
  '–': '', '̇': '', 'ъ': '', 'ь': '',
  // Latin.
  'ö': 'o', 'ğ': 'g', 'ş': 'sh', 'ç': 'ch', 'ü': 'u', 'ı': 'i', 'x': 'h',
  'q': 'k',
  // Cyrillic, Russian and Uzbek.
  'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'e',
  'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
  'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
  'ф': 'f', 'х': 'h', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'sh', 'ы': 'i',
  'э': 'e', 'ю': 'yu', 'я': 'ya', 'ў': 'o', 'қ': 'k', 'ғ': 'g', 'ҳ': 'h',
};
