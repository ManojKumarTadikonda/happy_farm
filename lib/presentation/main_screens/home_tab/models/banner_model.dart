class BannerModel {
  final String id;
  final List<String> images;

  BannerModel({required this.id, required this.images});

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'],
      images: List<String>.from(json['images'] ?? []),
    );
  }
}