class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final String? description;
}
