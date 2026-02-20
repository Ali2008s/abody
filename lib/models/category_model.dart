class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.order = 0,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'imageUrl': imageUrl, 'order': order};
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      order: map['order'] ?? 0,
    );
  }
}
