class BikeSku {
  final String skuId;
  final String brandId;
  final String brandName;
  final String model;
  final String name;
  final String colour;
  final double wheelSizeInches;
  final int wheelCircumferenceMm;
  final String imageAsset;

  const BikeSku({
    required this.skuId,
    required this.brandId,
    required this.brandName,
    required this.model,
    required this.name,
    required this.colour,
    required this.wheelSizeInches,
    required this.wheelCircumferenceMm,
    required this.imageAsset,
  });

  factory BikeSku.fromMap(Map<String, dynamic> map) {
    return BikeSku(
      skuId: map['skuId'] ?? '',
      brandId: map['brandId'] ?? '',
      brandName: map['brandName'] ?? '',
      model: map['model'] ?? '',
      name: map['name'] ?? '',
      colour: map['colour'] ?? '',
      wheelSizeInches: (map['wheelSizeInches'] as num?)?.toDouble() ?? 27.5,
      wheelCircumferenceMm: (map['wheelCircumferenceMm'] as num?)?.toInt() ?? 2180,
      imageAsset: map['imageAsset'] ?? 'assets/Cycle.png',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skuId': skuId,
      'brandId': brandId,
      'brandName': brandName,
      'model': model,
      'name': name,
      'colour': colour,
      'wheelSizeInches': wheelSizeInches,
      'wheelCircumferenceMm': wheelCircumferenceMm,
      'imageAsset': imageAsset,
    };
  }
}
