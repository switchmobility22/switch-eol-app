class QcResult {
  final String errorRegisterCode;
  final bool isErrorRegisterClean;
  final String faultDescription;
  final int cadencePulseCount;
  final bool powerSensorPassed;

  const QcResult({
    required this.errorRegisterCode,
    required this.isErrorRegisterClean,
    required this.faultDescription,
    required this.cadencePulseCount,
    required this.powerSensorPassed,
  });

  bool get isFullyPassed => isErrorRegisterClean && powerSensorPassed;

  static const Map<String, String> knownFaults = {
    '0x01': 'Motor Cable Disconnection (Phase Open)',
    '0x02': 'Throttle Hall Signal Out of Range',
    '0x03': 'Battery Power Cable / Undervoltage Fault',
    '0x04': 'Controller Overcurrent Protection',
    '0x05': 'MOSFET Thermal Over-Temp',
    '0x06': 'Sensorless Angle / Sync Loss',
    '0xFF': 'Nominal (Zero Active Faults)',
    '0x00': 'Nominal (Zero Active Faults)',
  };

  factory QcResult.initial() {
    return const QcResult(
      errorRegisterCode: '',
      isErrorRegisterClean: false,
      faultDescription: 'Pending audit',
      cadencePulseCount: 0,
      powerSensorPassed: false,
    );
  }

  QcResult copyWith({
    String? errorRegisterCode,
    bool? isErrorRegisterClean,
    String? faultDescription,
    int? cadencePulseCount,
    bool? powerSensorPassed,
  }) {
    return QcResult(
      errorRegisterCode: errorRegisterCode ?? this.errorRegisterCode,
      isErrorRegisterClean: isErrorRegisterClean ?? this.isErrorRegisterClean,
      faultDescription: faultDescription ?? this.faultDescription,
      cadencePulseCount: cadencePulseCount ?? this.cadencePulseCount,
      powerSensorPassed: powerSensorPassed ?? this.powerSensorPassed,
    );
  }
}
