import 'package:equatable/equatable.dart';

enum DocumentType { prescription, labResult, insurance, discharge, imaging, other }

class HealthDocument extends Equatable {
  final String id;
  final String title;
  final String filePath;
  final String fileExtension; // 'pdf', 'jpg', 'png', etc.
  final DocumentType type;
  final List<String> tags;
  final String? linkedMedicationId;
  final DateTime addedAt;

  const HealthDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileExtension,
    this.type = DocumentType.other,
    this.tags = const [],
    this.linkedMedicationId,
    required this.addedAt,
  });

  bool get isPdf => fileExtension.toLowerCase() == 'pdf';
  bool get isImage => ['jpg', 'jpeg', 'png', 'heic', 'webp'].contains(fileExtension.toLowerCase());

  HealthDocument copyWith({
    String? title,
    DocumentType? type,
    List<String>? tags,
  }) {
    return HealthDocument(
      id: id,
      title: title ?? this.title,
      filePath: filePath,
      fileExtension: fileExtension,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      linkedMedicationId: linkedMedicationId,
      addedAt: addedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, title, filePath, fileExtension, type, tags, linkedMedicationId, addedAt];
}
