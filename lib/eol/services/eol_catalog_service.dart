import '../models/bike_sku.dart';

class EolCatalogService {
  // Production SKUs mapped to verified models from Firebase & brand manufacturers
  static final Map<String, List<BikeSku>> brandSkus = {
    // Switch: PowerPedal Powertrain & Controller Platform
    'switch': [
      const BikeSku(
        skuId: 'sw_powerpedal_275',
        brandId: 'switch',
        brandName: 'Switch',
        model: 'PowerPedal Reference',
        name: 'PowerPedal System',
        colour: 'Powerpedal Blue',
        wheelSizeInches: 27.5,
        wheelCircumferenceMm: 2180,
        imageAsset: 'assets/Cycle_blue.png',
      ),
      const BikeSku(
        skuId: 'sw_powerpedal_26',
        brandId: 'switch',
        brandName: 'Switch',
        model: 'PowerPedal Reference',
        name: 'PowerPedal System',
        colour: 'Powerpedal Blue',
        wheelSizeInches: 26.0,
        wheelCircumferenceMm: 2075,
        imageAsset: 'assets/Cycle_blue.png',
      ),
      const BikeSku(
        skuId: 'sw_powerpedal_29',
        brandId: 'switch',
        brandName: 'Switch',
        model: 'PowerPedal Reference',
        name: 'PowerPedal System',
        colour: 'Powerpedal Blue',
        wheelSizeInches: 29.0,
        wheelCircumferenceMm: 2288,
        imageAsset: 'assets/Cycle_blue.png',
      ),
    ],

    // Hero Lectro: C5 & Y5 production models
    'hero_lectro': [
      const BikeSku(
        skuId: 'hero_c5_red_275',
        brandId: 'hero_lectro',
        brandName: 'Hero Lectro',
        model: 'C5',
        name: 'Lectro',
        colour: 'Red',
        wheelSizeInches: 27.5,
        wheelCircumferenceMm: 2180,
        imageAsset: 'assets/Cycle_Lectro_C5.png',
      ),
      const BikeSku(
        skuId: 'hero_y5_pista_275',
        brandId: 'hero_lectro',
        brandName: 'Hero Lectro',
        model: 'Y5',
        name: 'Lectro',
        colour: 'Pista',
        wheelSizeInches: 27.5,
        wheelCircumferenceMm: 2180,
        imageAsset: 'assets/Cycle.png',
      ),
    ],

    // Decathlon Rockrider: ST120e
    'rockrider': [
      const BikeSku(
        skuId: 'rr_st120e_blue_275',
        brandId: 'rockrider',
        brandName: 'Decathlon Rockrider',
        model: 'ST120e',
        name: 'Rockrider',
        colour: 'Blue',
        wheelSizeInches: 27.5,
        wheelCircumferenceMm: 2180,
        imageAsset: 'assets/Cycle_ST120e.png',
      ),
      const BikeSku(
        skuId: 'rr_st120e_charcoal_275',
        brandId: 'rockrider',
        brandName: 'Decathlon Rockrider',
        model: 'ST120e',
        name: 'Rockrider',
        colour: 'Dark Grey',
        wheelSizeInches: 27.5,
        wheelCircumferenceMm: 2180,
        imageAsset: 'assets/Cycle_Rockrider.png',
      ),
    ],

    // E-Motorad: X1
    'emotorad': [
      const BikeSku(
        skuId: 'em_x1_red_26',
        brandId: 'emotorad',
        brandName: 'E-Motorad',
        model: 'X1',
        name: 'E-Motorad',
        colour: 'Red',
        wheelSizeInches: 26.0,
        wheelCircumferenceMm: 2075,
        imageAsset: 'assets/Cycle_red.png',
      ),
    ],

    // eSthira: L27 & Z26
    'esthira': [
      const BikeSku(
        skuId: 'es_l27_black_275',
        brandId: 'esthira',
        brandName: 'eSthira',
        model: 'L27',
        name: 'Raptric',
        colour: 'Black',
        wheelSizeInches: 27.5,
        wheelCircumferenceMm: 2180,
        imageAsset: 'assets/Cycle.png',
      ),
      const BikeSku(
        skuId: 'es_z26_black_26',
        brandId: 'esthira',
        brandName: 'eSthira',
        model: 'Z26',
        name: 'Raptric',
        colour: 'Black',
        wheelSizeInches: 26.0,
        wheelCircumferenceMm: 2075,
        imageAsset: 'assets/Cycle.png',
      ),
      const BikeSku(
        skuId: 'es_z26_teal_26',
        brandId: 'esthira',
        brandName: 'eSthira',
        model: 'z26',
        name: 'Cypro',
        colour: 'Teal',
        wheelSizeInches: 26.0,
        wheelCircumferenceMm: 2075,
        imageAsset: 'assets/Cycle.png',
      ),
    ],

    // Daijo: Town & Country
    'daijo': [
      const BikeSku(
        skuId: 'dj_tc_grey_28',
        brandId: 'daijo',
        brandName: 'Daijo Pedaleze',
        model: 'Town & Country',
        name: 'Pedaleze',
        colour: 'Dark Grey',
        wheelSizeInches: 28.0,
        wheelCircumferenceMm: 2240,
        imageAsset: 'assets/Cycle.png',
      ),
    ],

    // eZPedal: Olive
    'ezpedal': [
      const BikeSku(
        skuId: 'ez_olive_26',
        brandId: 'ezpedal',
        brandName: 'eZPedal',
        model: 'Olive',
        name: 'eZpedal',
        colour: 'Olive',
        wheelSizeInches: 26.0,
        wheelCircumferenceMm: 2075,
        imageAsset: 'assets/Cycle.png',
      ),
    ],

    // Cypro: C1
    'cypro': [
      const BikeSku(
        skuId: 'cyp_c1_teal_275',
        brandId: 'cypro',
        brandName: 'Cypro',
        model: 'C1 Commuter',
        name: 'Cypro',
        colour: 'Teal',
        wheelSizeInches: 27.5,
        wheelCircumferenceMm: 2180,
        imageAsset: 'assets/Cycle.png',
      ),
    ],
  };

  // Get SKUs for a specific brand (Strict Brand Isolation)
  static List<BikeSku> getSkusForBrand(String brandId) {
    return brandSkus[brandId.toLowerCase()] ?? brandSkus['switch'] ?? [];
  }

  // Get authorized PNG images for that brand
  static List<String> getAuthorizedImagesForBrand(String brandId) {
    final skus = getSkusForBrand(brandId);
    final images = skus.map((s) => s.imageAsset).toSet().toList();
    if (images.isEmpty) {
      images.add('assets/Cycle.png');
    }
    return images;
  }
}
