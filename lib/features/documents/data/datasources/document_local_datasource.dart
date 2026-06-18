import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/health_document.dart';

/// Local data source for the document vault.
///
/// Important detail: image_picker / camera return files in a temporary or
/// cache directory that the OS can clear at any time. So when a document is
/// added, this data source copies the file into the app's permanent
/// documents directory (under a `vault/` subfolder) and stores that
/// permanent path — otherwise documents would silently "disappear" after a
/// few days as the OS reclaims cache space.
class DocumentLocalDataSource {
  static const _boxName = 'documents';

  Box get _box => Hive.box(_boxName);

  static Future<void> ensureBoxOpen() async {
    if (!Hive.isBoxOpen(_boxName)) await Hive.openBox(_boxName);
  }

  Future<List<HealthDocument>> getAll() async {
    return _box.values.map((raw) => _decode(Map<String, dynamic>.from(raw as Map))).toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  Future<HealthDocument?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return _decode(Map<String, dynamic>.from(raw as Map));
  }

  /// Copies [sourcePath] into permanent app storage and returns the new
  /// permanent path. Call this before constructing the [HealthDocument]
  /// that gets saved.
  Future<String> persistFile(String sourcePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory(p.join(docsDir.path, 'vault'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    final ext = p.extension(sourcePath);
    final destPath = p.join(vaultDir.path, '${DateTime.now().microsecondsSinceEpoch}$ext');
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<void> save(HealthDocument document) async {
    await _box.put(document.id, _encode(document));
  }

  Future<void> delete(String id) async {
    final existing = await getById(id);
    await _box.delete(id);
    if (existing != null) {
      final file = File(existing.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // Non-fatal: metadata is gone either way, orphaned file cleanup
          // can be revisited later without affecting the user-facing flow.
        }
      }
    }
  }

  Future<List<HealthDocument>> search(String query) async {
    final all = await getAll();
    final lower = query.toLowerCase();
    return all.where((d) {
      final inTitle = d.title.toLowerCase().contains(lower);
      final inTags = d.tags.any((t) => t.toLowerCase().contains(lower));
      final inType = d.type.name.toLowerCase().contains(lower);
      return inTitle || inTags || inType;
    }).toList();
  }

  Map<String, dynamic> _encode(HealthDocument d) => {
        'id': d.id,
        'title': d.title,
        'filePath': d.filePath,
        'fileExtension': d.fileExtension,
        'type': d.type.name,
        'tags': d.tags,
        'linkedMedicationId': d.linkedMedicationId,
        'addedAt': d.addedAt.toIso8601String(),
      };

  HealthDocument _decode(Map<String, dynamic> m) => HealthDocument(
        id: m['id'] as String,
        title: m['title'] as String,
        filePath: m['filePath'] as String,
        fileExtension: m['fileExtension'] as String,
        type: DocumentType.values.firstWhere((t) => t.name == m['type']),
        tags: List<String>.from(m['tags'] as List? ?? []),
        linkedMedicationId: m['linkedMedicationId'] as String?,
        addedAt: DateTime.parse(m['addedAt'] as String),
      );
}
