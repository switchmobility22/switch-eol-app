class EolBrand {
  final String id;
  final String name;
  final String primaryColorHex;
  final String logoAsset;
  final List<String> supportedModels;

  const EolBrand({
    required this.id,
    required this.name,
    required this.primaryColorHex,
    required this.logoAsset,
    required this.supportedModels,
  });

  // Pre-configured OEM brands matching backend /brands registry
  static const List<EolBrand> supportedBrands = [
    EolBrand(
      id: 'switch',
      name: 'Switch',
      primaryColorHex: '#0074D7',
      logoAsset: 'assets/powerpedal_logo.png',
      supportedModels: ['Apex Pro', 'City Commuter', 'Trail Sport'],
    ),
    EolBrand(
      id: 'cypro',
      name: 'Cypro',
      primaryColorHex: '#0074D7',
      logoAsset: 'assets/logo.png',
      supportedModels: ['C1 Commuter', 'C2 Cargo', 'Trail Pro'],
    ),
    EolBrand(
      id: 'emotorad',
      name: 'E-Motorad',
      primaryColorHex: '#EF4444',
      logoAsset: 'assets/powerpedal_logo.png',
      supportedModels: ['X1', 'X2', 'T-Rex'],
    ),
    EolBrand(
      id: 'hero_lectro',
      name: 'Hero Lectro',
      primaryColorHex: '#F59E0B',
      logoAsset: 'assets/logo.png',
      supportedModels: ['C5', 'C3', 'F6i'],
    ),
    EolBrand(
      id: 'rockrider',
      name: 'Decathlon Rockrider',
      primaryColorHex: '#3B82F6',
      logoAsset: 'assets/powerpedal_logo.png',
      supportedModels: ['ST120e', 'E-ST500', 'E-ST900'],
    ),
  ];

  static EolBrand getById(String id) {
    return supportedBrands.firstWhere(
      (b) => b.id.toLowerCase() == id.toLowerCase(),
      orElse: () => supportedBrands.first,
    );
  }
}
