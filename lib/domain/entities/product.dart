import 'package:equatable/equatable.dart';

enum ProductCondition {
  likeNew,
  excellent,
  good,
  fair,
  poor,
}

class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.condition,
    required this.imageUrls,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatarUrl,
    this.location,
    this.isPromoted = false,
    this.viewCount = 0,
    this.likeCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String categoryId;
  final ProductCondition condition;
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatarUrl;
  final String? location;
  final bool isPromoted;
  final int viewCount;
  final int likeCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final List<String> tags;

  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? categoryId,
    ProductCondition? condition,
    List<String>? imageUrls,
    String? sellerId,
    String? sellerName,
    String? sellerAvatarUrl,
    String? location,
    bool? isPromoted,
    int? viewCount,
    int? likeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? tags,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatarUrl: sellerAvatarUrl ?? this.sellerAvatarUrl,
      location: location ?? this.location,
      isPromoted: isPromoted ?? this.isPromoted,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        price,
        categoryId,
        condition,
        imageUrls,
        sellerId,
        sellerName,
        sellerAvatarUrl,
        location,
        isPromoted,
        viewCount,
        likeCount,
        createdAt,
        updatedAt,
        isActive,
        tags,
      ];
}