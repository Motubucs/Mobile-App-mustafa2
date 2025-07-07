import 'package:cloud_firestore/cloud_firestore.dart';

import 'user.dart';

class ReportModel {
  final String? id;
  final String? comments;
  final String? productId;
  final String? productTitle;
  final String? reason;
  final String? sellerId;
  final String? reportedBy;
  final String? reporterEmail;
  final String? status;
  final String? type;
  final DateTime? createdAt;
  final User? sellerDetails;
  final User? reportarDetails;

  ReportModel({
    this.id,
    this.comments,
    this.productId,
    this.productTitle,
    this.reason,
    this.sellerId,
    this.reportedBy,
    this.reporterEmail,
    this.status,
    this.type,
    this.createdAt,
    this.sellerDetails,
    this.reportarDetails,
  });

  ReportModel copyWith({
    String? id,
    String? comments,
    String? productId,
    String? productTitle,
    String? reason,
    String? sellerId,
    String? reportedBy,
    String? reporterEmail,
    String? status,
    String? type,
    DateTime? createdAt,
    User? sellerDetails,
    User? reportarDetails,
  }) {
    return ReportModel(
      id: id ?? this.id,
      comments: comments ?? this.comments,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      reason: reason ?? this.reason,
      sellerId: sellerId ?? this.sellerId,
      reportedBy: reportedBy ?? this.reportedBy,
      reporterEmail: reporterEmail ?? this.reporterEmail,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      sellerDetails: sellerDetails ?? this.sellerDetails,
      reportarDetails: reportarDetails ?? this.reportarDetails,
    );
  }

  factory ReportModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return ReportModel(
      id: id,
      comments: json['comments'],
      productId: json['productId'],
      productTitle: json['productTitle'],
      sellerId: json['sellerId'],
      reason: json['reason'],
      reportedBy: json['reportedBy'],
      reporterEmail: json['reporterEmail'],
      status: json['status'],

      type: json['type'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      sellerDetails:
          json['user'] != null ? User.fromMap(json['user'] as Map<String, dynamic>) : null,
      reportarDetails:
          json['user'] != null ? User.fromMap(json['user'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comments': comments,
      'createdAt': createdAt,
      'productId': productId,
      'productTitle': productTitle,
      'reason': reason,
      'reportedBy': reportedBy,
      'reporterEmail': reporterEmail,
      'sellerId': sellerId,
      'status': status,
      'type': type,
    };
  }
}
