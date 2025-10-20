import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.iconUrl,
    this.description,
    this.parentCategoryId,
    this.subcategories = const [],
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String iconUrl;
  final String? description;
  final String? parentCategoryId;
  final List<Category> subcategories;
  final bool isActive;
  final int sortOrder;

  /// Check if this is a root category (no parent)
  bool get isRootCategory => parentCategoryId == null;

  /// Check if this category has subcategories
  bool get hasSubcategories => subcategories.isNotEmpty;

  Category copyWith({
    String? id,
    String? name,
    String? iconUrl,
    String? description,
    String? parentCategoryId,
    List<Category>? subcategories,
    bool? isActive,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      description: description ?? this.description,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      subcategories: subcategories ?? this.subcategories,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        iconUrl,
        description,
        parentCategoryId,
        subcategories,
        isActive,
        sortOrder,
      ];
}