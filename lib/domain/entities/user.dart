import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImageUrl,
    this.phoneNumber,
    this.address,
    this.isEmailVerified = false,
    this.sellerRating = 0.0,
    this.buyerRating = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String name;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? address;
  final bool isEmailVerified;
  final double sellerRating;
  final double buyerRating;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImageUrl,
    String? phoneNumber,
    String? address,
    bool? isEmailVerified,
    double? sellerRating,
    double? buyerRating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      sellerRating: sellerRating ?? this.sellerRating,
      buyerRating: buyerRating ?? this.buyerRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        profileImageUrl,
        phoneNumber,
        address,
        isEmailVerified,
        sellerRating,
        buyerRating,
        createdAt,
        updatedAt,
      ];
}