import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

enum RequestStatus { pending, approved, rejected }

class RoleRequestModel {
  final String id;
  final String requesterUid;
  final String requesterEmail;
  final UserRole requestedRole;
  final RequestStatus status;
  final String? reason;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  RoleRequestModel({
    required this.id,
    required this.requesterUid,
    required this.requesterEmail,
    required this.requestedRole,
    this.status = RequestStatus.pending,
    this.reason,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory RoleRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoleRequestModel(
      id: doc.id,
      requesterUid: data['requesterUid'] as String,
      requesterEmail: data['requesterEmail'] as String? ?? '',
      requestedRole: UserRole.fromString(data['requestedRole'] as String?),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      reason: data['reason'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterUid': requesterUid,
      'requesterEmail': requesterEmail,
      'requestedRole': requestedRole.value,
      'status': status.name,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
}