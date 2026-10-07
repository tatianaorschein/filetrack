class Dossier {
  final String id;
  final String title;
  final String createdAt;
  final String creatorServiceId;
  final String currentStatus;

  Dossier({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.creatorServiceId,
    required this.currentStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt,
      'creator_service_id': creatorServiceId,
      'current_status': currentStatus,
    };
  }

  factory Dossier.fromMap(Map<String, dynamic> map) {
    return Dossier(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: map['created_at'] as String,
      creatorServiceId: map['creator_service_id'] as String,
      currentStatus: map['current_status'] as String? ?? 'Créé',
    );
  }
}
