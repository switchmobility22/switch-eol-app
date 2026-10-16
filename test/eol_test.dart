import 'package:flutter_test/flutter_test.dart';
import 'package:switch_app/eol/models/eol_brand.dart';
import 'package:switch_app/eol/models/local_eol_record.dart';
import 'package:switch_app/eol/models/qc_result.dart';
import 'package:switch_app/eol/services/eol_catalog_service.dart';

void main() {
  group('EOL Brand Isolation & Catalog Tests', () {
    test('Supported brands contain Switch, Cypro, E-Motorad, Hero Lectro, Decathlon Rockrider', () {
      const brands = EolBrand.supportedBrands;
      expect(brands.length, 5);
      expect(brands.map((b) => b.id).toList(), containsAll(['switch', 'cypro', 'emotorad', 'hero_lectro', 'rockrider']));
    });

    test('Catalog service enforces strict brand isolation', () {
      final cyproSkus = EolCatalogService.getSkusForBrand('cypro');
      expect(cyproSkus.isNotEmpty, true);
      for (final sku in cyproSkus) {
        expect(sku.brandId, 'cypro');
      }

      final rockriderSkus = EolCatalogService.getSkusForBrand('rockrider');
      expect(rockriderSkus.isNotEmpty, true);
      for (final sku in rockriderSkus) {
        expect(sku.brandId, 'rockrider');
      }

      // Cypro must never see Rockrider SKUs
      final rockriderModels = rockriderSkus.map((s) => s.model).toSet();
      for (final cyproSku in cyproSkus) {
        expect(rockriderModels.contains(cyproSku.model), false);
      }
    });

    test('Wheel circumference mappings match standard diameters', () {
      final cyproSkus = EolCatalogService.getSkusForBrand('cypro');
      final c1 = cyproSkus.firstWhere((s) => s.wheelSizeInches == 27.5);
      expect(c1.wheelCircumferenceMm, 2180);

      final emSkus = EolCatalogService.getSkusForBrand('emotorad');
      final x1 = emSkus.firstWhere((s) => s.wheelSizeInches == 26.0);
      expect(x1.wheelCircumferenceMm, 2075);
    });

    test('Brand image authorization returns verified PNG assets', () {
      final cyproImages = EolCatalogService.getAuthorizedImagesForBrand('cypro');
      expect(cyproImages, contains('assets/Cycle.png'));

      final switchImages = EolCatalogService.getAuthorizedImagesForBrand('switch');
      expect(switchImages, contains('assets/Cycle_blue.png'));
    });
  });

  group('EOL Local Record & Cloud Payload Tests', () {
    test('LocalEolRecord serializes to SQLite map and back losslessly', () {
      final record = LocalEolRecord(
        id: 1,
        mac: 'CC:54:3B:A8:FF:10',
        brandId: 'cypro',
        brandName: 'Cypro',
        model: 'C1 Commuter',
        name: 'Cypro C1 Commuter',
        colour: 'Matte Teal',
        wheelSizeInches: 27.5,
        wheelCircumferenceMm: 2180,
        imageAsset: 'assets/Cycle.png',
        assemblerId: 'asm_cyp_01',
        assemblerName: 'Ramesh Patil',
        stationId: 'Station-1-Line-A',
        initialErrorCode: '0xFF',
        qcPassed: true,
        syncStatus: 'pending',
        createdAt: '2026-10-14T20:30:00Z',
      );

      final map = record.toMap();
      final revived = LocalEolRecord.fromMap(map);

      expect(revived.mac, 'CC:54:3B:A8:FF:10');
      expect(revived.brandId, 'cypro');
      expect(revived.wheelSizeInches, 27.5);
      expect(revived.wheelCircumferenceMm, 2180);
      expect(revived.qcPassed, true);
      expect(revived.syncStatus, 'pending');
    });

    test('Firestore export payload contains wheelSize and eolDetails', () {
      final record = LocalEolRecord(
        mac: 'CC:54:3B:A8:FF:10',
        brandId: 'cypro',
        brandName: 'Cypro',
        model: 'C1 Commuter',
        name: 'Cypro C1 Commuter',
        colour: 'Matte Teal',
        wheelSizeInches: 27.5,
        wheelCircumferenceMm: 2180,
        imageAsset: 'assets/Cycle.png',
        assemblerId: 'asm_cyp_01',
        assemblerName: 'Ramesh Patil',
        stationId: 'Station-1',
        initialErrorCode: '0xFF',
        qcPassed: true,
        createdAt: '2026-10-14T20:30:00Z',
      );

      final firestoreData = record.toFirestoreMap();
      expect(firestoreData['mac'], 'CC:54:3B:A8:FF:10');
      expect(firestoreData['Manufacturer'], 'Cypro');
      expect(firestoreData['status'], 'unassigned');
      expect(firestoreData['wheelSize']['diameterInches'], 27.5);
      expect(firestoreData['wheelSize']['circumferenceMm'], 2180);
      expect(firestoreData['eolDetails']['assemblerId'], 'asm_cyp_01');
      expect(firestoreData['eolDetails']['qcPassed'], true);
      expect(firestoreData['eolDetails']['wheelSizeFlashed'], true);
    });
  });

  group('QC Result Diagnostic Logic Tests', () {
    test('Initial QC state is pending', () {
      final qc = QcResult.initial();
      expect(qc.isFullyPassed, false);
      expect(qc.isErrorRegisterClean, false);
      expect(qc.powerSensorPassed, false);
    });

    test('Nominal 0xFF and 4 cadence pulses declare full pass', () {
      const qc = QcResult(
        errorRegisterCode: '0xFF',
        isErrorRegisterClean: true,
        faultDescription: 'Nominal',
        cadencePulseCount: 4,
        powerSensorPassed: true,
      );
      expect(qc.isFullyPassed, true);
    });

    test('Active fault code blocks QC pass even if cadence passes', () {
      const qc = QcResult(
        errorRegisterCode: '0x01',
        isErrorRegisterClean: false,
        faultDescription: 'Motor Phase Open',
        cadencePulseCount: 6,
        powerSensorPassed: true,
      );
      expect(qc.isFullyPassed, false);
    });
  });
}
