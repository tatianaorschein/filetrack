class Transmission {
  final String id;
  final String dossierId;
  final String senderServiceId;
  final String senderUserId;
  final String receiverServiceId;
  final String? receiverUserId;
  final String dateTime;
  final String observation;
  final String type; // 'interne' ou 'externe'
  final String? externalOrganization;
  final String? attachmentPath;
  final String status; // 'émis', 'reçu', 'rejeté'

  Transmission({
    required this.id,
    required this.dossierId,
    required this.senderServiceId,
    required this.senderUserId,
    required this.receiverServiceId,
    this.receiverUserId,
    required this.dateTime,
    required this.observation,
    required this.type,
    this.externalOrganization,
    this.attachmentPath,
    required this.status,
  });

  bool get isExternal => type.toLowerCase() == 'externe';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dossier_id': dossierId,
      'sender_service_id': senderServiceId,
      'sender_user_id': senderUserId,
      'receiver_service_id': receiverServiceId,
      'receiver_user_id': receiverUserId,
      'date_time': dateTime,
      'observation': observation,
      'type': type,
      'external_organization': externalOrganization,
      'attachment_path': attachmentPath,
      'status': status,
    };
  }

  factory Transmission.fromMap(Map<String, dynamic> map) {
    return Transmission(
      id: map['id'] as String,
      dossierId: map['dossier_id'] as String,
      senderServiceId: map['sender_service_id'] as String,
      senderUserId: map['sender_user_id'] as String,
      receiverServiceId: map['receiver_service_id'] as String,
      receiverUserId: map['receiver_user_id'] as String?,
      dateTime: map['date_time'] as String,
      observation: map['observation'] as String? ?? '',
      type: map['type'] as String? ?? 'interne',
      externalOrganization: map['external_organization'] as String?,
      attachmentPath: map['attachment_path'] as String?,
      status: map['status'] as String? ?? 'émis',
    );
  }
}
