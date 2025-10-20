import 'package:equatable/equatable.dart';

enum VerificationStatus {
  pending,
  verified,
  rejected,
  expired,
}

enum VerificationType {
  identity,
  phone,
  email,
  address,
  paymentMethod,
  businessLicense,
}

enum ReportType {
  spam,
  inappropriateContent,
  harassment,
  fraud,
  counterfeit,
  intellectual property,
  violence,
  other,
}

enum ReportStatus {
  submitted,
  underReview,
  resolved,
  dismissed,
  escalated,
}

enum SecurityEventType {
  loginAttempt,
  passwordChange,
  paymentAttempt,
  suspiciousActivity,
  accountLocked,
  dataBreach,
}

class UserVerification extends Equatable {
  const UserVerification({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    this.documentUrl,
    this.verificationData,
    required this.submittedAt,
    this.verifiedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.expiresAt,
    this.verifiedBy,
    this.notes,
  });

  final String id;
  final String userId;
  final VerificationType type;
  final VerificationStatus status;
  final String? documentUrl;
  final Map<String, dynamic>? verificationData;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? expiresAt;
  final String? verifiedBy;
  final String? notes;

  UserVerification copyWith({
    String? id,
    String? userId,
    VerificationType? type,
    VerificationStatus? status,
    String? documentUrl,
    Map<String, dynamic>? verificationData,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    DateTime? expiresAt,
    String? verifiedBy,
    String? notes,
  }) {
    return UserVerification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      documentUrl: documentUrl ?? this.documentUrl,
      verificationData: verificationData ?? this.verificationData,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      expiresAt: expiresAt ?? this.expiresAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        status,
        documentUrl,
        verificationData,
        submittedAt,
        verifiedAt,
        rejectedAt,
        rejectionReason,
        expiresAt,
        verifiedBy,
        notes,
      ];
}

class SecurityReport extends Equatable {
  const SecurityReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.productId,
    this.messageId,
    required this.type,
    required this.status,
    required this.description,
    this.evidence = const [],
    required this.submittedAt,
    this.reviewedAt,
    this.resolvedAt,
    this.reviewedBy,
    this.resolution,
    this.actionTaken,
    this.isAnonymous = false,
  });

  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? productId;
  final String? messageId;
  final ReportType type;
  final ReportStatus status;
  final String description;
  final List<String> evidence;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? resolvedAt;
  final String? reviewedBy;
  final String? resolution;
  final String? actionTaken;
  final bool isAnonymous;

  SecurityReport copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? productId,
    String? messageId,
    ReportType? type,
    ReportStatus? status,
    String? description,
    List<String>? evidence,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? resolvedAt,
    String? reviewedBy,
    String? resolution,
    String? actionTaken,
    bool? isAnonymous,
  }) {
    return SecurityReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      productId: productId ?? this.productId,
      messageId: messageId ?? this.messageId,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      resolution: resolution ?? this.resolution,
      actionTaken: actionTaken ?? this.actionTaken,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reporterId,
        reportedUserId,
        productId,
        messageId,
        type,
        status,
        description,
        evidence,
        submittedAt,
        reviewedAt,
        resolvedAt,
        reviewedBy,
        resolution,
        actionTaken,
        isAnonymous,
      ];
}

class SecurityEvent extends Equatable {
  const SecurityEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.ipAddress,
    this.userAgent,
    this.location,
    this.deviceInfo,
    this.severity = SecuritySeverity.low,
    this.metadata = const {},
    this.isBlocked = false,
    this.riskScore = 0.0,
  });

  final String id;
  final String userId;
  final SecurityEventType type;
  final DateTime timestamp;
  final String ipAddress;
  final String? userAgent;
  final String? location;
  final Map<String, dynamic>? deviceInfo;
  final SecuritySeverity severity;
  final Map<String, dynamic> metadata;
  final bool isBlocked;
  final double riskScore;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        timestamp,
        ipAddress,
        userAgent,
        location,
        deviceInfo,
        severity,
        metadata,
        isBlocked,
        riskScore,
      ];
}

class BuyerProtection extends Equatable {
  const BuyerProtection({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.coverageAmount,
    required this.coverageType,
    required this.startDate,
    required this.endDate,
    this.claimId,
    this.status = ProtectionStatus.active,
    this.terms = const [],
    this.exclusions = const [],
  });

  final String id;
  final String orderId;
  final String buyerId;
  final double coverageAmount;
  final ProtectionType coverageType;
  final DateTime startDate;
  final DateTime endDate;
  final String? claimId;
  final ProtectionStatus status;
  final List<String> terms;
  final List<String> exclusions;

  @override
  List<Object?> get props => [
        id,
        orderId,
        buyerId,
        coverageAmount,
        coverageType,
        startDate,
        endDate,
        claimId,
        status,
        terms,
        exclusions,
      ];
}

enum SecuritySeverity {
  low,
  medium,
  high,
  critical,
}

enum ProtectionType {
  purchase,
  authenticity,
  condition,
  delivery,
}

enum ProtectionStatus {
  active,
  claimed,
  expired,
  cancelled,
}