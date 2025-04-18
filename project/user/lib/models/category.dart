class CategoryModel {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      categoryId: map['category_id'].toString(),
      categoryName: map['category_name'] ?? '',
      categoryIcon: map['category_icon'],
    );
  }
} 