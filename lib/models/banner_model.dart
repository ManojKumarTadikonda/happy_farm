class BannerModel {
  final String id;
  final String imageUrl;

  BannerModel({required this.id, required this.imageUrl});

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'],
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
