import 'package:equatable/equatable.dart';
import 'product.dart';

enum SortOrder {
  newest,
  oldest,
  priceLowToHigh,
  priceHighToLow,
  mostViewed,
  mostLiked,
  closestLocation,
}

class ProductFilters extends Equatable {
  const ProductFilters({
    this.searchQuery,
    this.categoryId,
    this.condition,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.maxDistance, // in kilometers
    this.isPromotedOnly = false,
    this.sellerId,
    this.tags = const [],
    this.sortOrder = SortOrder.newest,
    this.page = 1,
    this.limit = 20,
  });

  final String? searchQuery;
  final String? categoryId;
  final ProductCondition? condition;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final double? maxDistance;
  final bool isPromotedOnly;
  final String? sellerId;
  final List<String> tags;
  final SortOrder sortOrder;
  final int page;
  final int limit;

  /// Check if any filters are applied
  bool get hasActiveFilters {
    return searchQuery != null ||
        categoryId != null ||
        condition != null ||
        minPrice != null ||
        maxPrice != null ||
        location != null ||
        maxDistance != null ||
        isPromotedOnly ||
        sellerId != null ||
        tags.isNotEmpty;
  }

  /// Check if price range is valid
  bool get hasPriceRange {
    return minPrice != null && maxPrice != null && minPrice! <= maxPrice!;
  }

  ProductFilters copyWith({
    String? searchQuery,
    String? categoryId,
    ProductCondition? condition,
    double? minPrice,
    double? maxPrice,
    String? location,
    double? maxDistance,
    bool? isPromotedOnly,
    String? sellerId,
    List<String>? tags,
    SortOrder? sortOrder,
    int? page,
    int? limit,
  }) {
    return ProductFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: categoryId ?? this.categoryId,
      condition: condition ?? this.condition,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      location: location ?? this.location,
      maxDistance: maxDistance ?? this.maxDistance,
      isPromotedOnly: isPromotedOnly ?? this.isPromotedOnly,
      sellerId: sellerId ?? this.sellerId,
      tags: tags ?? this.tags,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  /// Clear all filters except pagination
  ProductFilters clearFilters() {
    return ProductFilters(
      sortOrder: sortOrder,
      page: 1,
      limit: limit,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        categoryId,
        condition,
        minPrice,
        maxPrice,
        location,
        maxDistance,
        isPromotedOnly,
        sellerId,
        tags,
        sortOrder,
        page,
        limit,
      ];
}