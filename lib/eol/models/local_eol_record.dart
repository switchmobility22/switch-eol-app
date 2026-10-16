class LocalEolRecord {
  final int? id;
  final String mac;
  final String brandId;
  final String brandName;
  final String model;
  final String name;
  final String colour;
  final double wheelSizeInches;
  final int wheelCircumferenceMm;
  final String imageAsset;
  final String assemblerId;
  final String assemblerName;
  final String stationId;
  final String initialErrorCode;
  final bool qcPassed;
  final String syncStatus; // 'pending' | 'synced' | 'failed'
  final String createdAt;
  final String? syncedAt;

  LocalEolRecord({
    this.id,
    required this.mac,
    required this.brandId,
    required this.brandName,
    required this.model,
    required this.name,
    required this.colour,
    required this.wheelSizeInches,
    required this.wheelCircumferenceMm,
    required this.imageAsset,
    required this.assemblerId,
    required this.assemblerName,
    required this.stationId,
    required this.initialErrorCode,
    required this.qcPassed,
    this.syncStatus = 'pending',
    required this.createdAt,
    this.syncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mac': mac,
      'brandId': brandId,
      'brandName': brandName,
      'model': model,
      'name': name,
      'colour': colour,
      'wheelSizeInches': wheelSizeInches,
      'wheelCircumferenceMm': wheelCircumferenceMm,
      'imageAsset': imageAsset,
      'assemblerId': assemblerId,
      'assemblerName': assemblerName,
      'stationId': stationId,
      'initialErrorCode': initialErrorCode,
      'qcPassed': qcPassed ? 1 : 0,
      'syncStatus': syncStatus,
      'createdAt': createdAt,
      'syncedAt': syncedAt,
    };
  }

  factory LocalEolRecord.fromMap(Map<String, dynamic> map) {
    return LocalEolRecord(
      id: map['id'] as int?,
      mac: map['mac'] as String,
      brandId: map['brandId'] as String,
      brandName: map['brandName'] as String,
      model: map['model'] as String,
      name: map['name'] as String,
      colour: map['colour'] as String,
      wheelSizeInches: (map['wheelSizeInches'] as num).toDouble(),
      wheelCircumferenceMm: (map['wheelCircumferenceMm'] as num).toInt(),
      imageAsset: map['imageAsset'] as String,
      assemblerId: map['assemblerId'] as String,
      assemblerName: map['assemblerName'] as String,
      stationId: map['stationId'] as String,
      initialErrorCode: map['initialErrorCode'] as String,
      qcPassed: (map['qcPassed'] as int) == 1,
      syncStatus: map['syncStatus'] as String? ?? 'pending',
      createdAt: map['createdAt'] as String,
      syncedAt: map['syncedAt'] as String?,
    );
  }

  // Generates the Firestore payload conforming to /ebikes/{mac}
  Map<String, dynamic> toFirestoreMap() {
    return {
      'mac': mac.toUpperCase(),
      'Manufacturer': brandName,
      'manufacturer': brandName,
      'brandId': brandId,
      'brandName': brandName,
      'Name': name,
      'name': name,
      'Model': model,
      'model': model,
      'Colour': colour,
      'colour': colour,
      'ImageURL': imageAsset,
      'imageUrl': imageAsset,
      'wheelSize': {
        'diameterInches': wheelSizeInches,
        'circumferenceMm': wheelCircumferenceMm,
      },
      'status': 'unassigned',
      'assigned_user_id': null,
      'eolDetails': {
        'provisionedAt': createdAt,
        'assemblerId': assemblerId,
        'assemblerName': assemblerName,
        'stationId': stationId,
        'initialErrorCode': initialErrorCode,
        'wheelSizeFlashed': true,
        'qcPassed': qcPassed,
      },
      'lastUpdatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
