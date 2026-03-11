class MosqueModel {
  const MosqueModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;

  factory MosqueModel.fromJson(Map<String, dynamic> json) {
    return MosqueModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'جامع بدون اسم',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      address: json['address'] as String? ?? 'لا يوجد عنوان',
    );
  }

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
