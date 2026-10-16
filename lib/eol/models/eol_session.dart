import 'assembler_user.dart';
import 'eol_brand.dart';

class EolSession {
  final String stationId;
  final int rssiThresholdDbm;
  final AssemblerUser assembler;
  final EolBrand brand;

  const EolSession({
    required this.stationId,
    required this.rssiThresholdDbm,
    required this.assembler,
    required this.brand,
  });

  EolSession copyWith({
    String? stationId,
    int? rssiThresholdDbm,
    AssemblerUser? assembler,
    EolBrand? brand,
  }) {
    return EolSession(
      stationId: stationId ?? this.stationId,
      rssiThresholdDbm: rssiThresholdDbm ?? this.rssiThresholdDbm,
      assembler: assembler ?? this.assembler,
      brand: brand ?? this.brand,
    );
  }
}
