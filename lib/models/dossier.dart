class Dossier {
  final String id;
  final String title;
  final String createdAt;
  final String creatorServiceId;
  final String currentStatus;
  final bool isSynced;

  Dossier({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.creatorServiceId,
    required this.currentStatus,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt,
      'creator_service_id': creatorServiceId,
      'current_status': currentStatus,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Dossier.fromMap(Map<String, dynamic> map) {
    return Dossier(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: map['created_at'] as String,
      creatorServiceId: map['creator_service_id'] as String,
      currentStatus: map['current_status'] as String? ?? 'Créé',
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }
}
