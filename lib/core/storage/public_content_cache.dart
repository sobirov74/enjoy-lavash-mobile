import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Raw response bodies of the public endpoints, exactly as the server sent
/// them. Only these three fit: customer data (profile, addresses, orders,
/// tokens) cannot be stored here by construction.
typedef PublicContentPayloads = ({
  Object? catalog,
  Object? branches,
  Object? banners,
});

/// The last successfully loaded public content (menu, branches, banners),
/// kept on the device so a cold start can show it before the network
/// answers.
///
/// One file in the app's cache directory. Anything unexpected — another
/// schema, server, organisation or language, an old or oversized file,
/// unreadable data — is a miss, and a bad file is deleted. It never throws:
/// without saved content the app simply waits for the network as before.
class PublicContentCache {
  PublicContentCache({
    Future<Directory> Function()? directory,
    DateTime Function()? clock,
  }) : _directory = directory ?? getApplicationCacheDirectory,
       _clock = clock ?? DateTime.now;

  /// Bump when the stored document changes shape.
  static const int schema = 2;
  static const String fileName = 'public_content.json';

  /// Written here first and then renamed. One fixed name, so a file left by
  /// a kill mid-write is overwritten by the next save instead of piling up.
  static const String temporaryFileName = '$fileName.tmp';
  static const int maxBytes = 2 * 1024 * 1024;
  static const Duration maxAge = Duration(days: 14);

  final Future<Directory> Function() _directory;
  final DateTime Function() _clock;

  /// Saves run one after another: they share the temporary file.
  Future<void> _lastWrite = Future<void>.value();

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  /// The saved payloads for [scope] (server and organisation) and
  /// [language], or null.
  Future<PublicContentPayloads?> read({
    required String scope,
    required String language,
  }) async {
    File? file;
    try {
      file = await _file();
      if (!await file.exists()) return null;
      if (await file.length() > maxBytes) {
        await _deleteQuietly(file);
        return null;
      }
      final document = jsonDecode(await file.readAsString());
      if (document is! Map<String, dynamic>) {
        await _deleteQuietly(file);
        return null;
      }
      if (document['schema'] != schema ||
          document['scope'] != scope ||
          document['language'] != language) {
        return null;
      }
      final savedAt = DateTime.tryParse('${document['savedAt']}');
      if (savedAt == null) return null;
      final age = _clock().difference(savedAt);
      // Saved "in the future" (a wrong clock then or now): not trusted, or
      // it would never expire.
      if (age.isNegative || age > maxAge) return null;
      final catalog = document['catalog'];
      if (catalog == null) return null;
      return (
        catalog: catalog,
        branches: document['branches'],
        banners: document['banners'],
      );
    } catch (error) {
      debugPrint('Saved public content unreadable: ${error.runtimeType}');
      if (file != null) await _deleteQuietly(file);
      return null;
    }
  }

  /// Replaces the saved content. A failed write leaves the previous file.
  Future<void> write({
    required String scope,
    required String language,
    required PublicContentPayloads payloads,
  }) {
    final write = _lastWrite.then(
      (_) => _write(scope: scope, language: language, payloads: payloads),
    );
    _lastWrite = write;
    return write;
  }

  Future<void> _write({
    required String scope,
    required String language,
    required PublicContentPayloads payloads,
  }) async {
    File? temporary;
    try {
      final bytes = utf8.encode(
        jsonEncode(<String, Object?>{
          'schema': schema,
          'scope': scope,
          'language': language,
          'savedAt': _clock().toUtc().toIso8601String(),
          'catalog': payloads.catalog,
          'branches': payloads.branches,
          'banners': payloads.banners,
        }),
      );
      if (bytes.length > maxBytes) return;
      final file = await _file();
      // Written aside and renamed, so a kill mid-write cannot leave a torn
      // file behind.
      temporary = File('${file.parent.path}/$temporaryFileName');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
    } catch (error) {
      debugPrint('Saving public content failed: ${error.runtimeType}');
      if (temporary != null) await _deleteQuietly(temporary);
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } catch (_) {
      // Already gone or not removable; the next write replaces it.
    }
  }
}
