class ScannedRecord {
  final String scannedCode;
  final String drugName;
  final bool isGenuine;
  final bool wasFound;
  final String scanDate;
  final int timestamp;
  final String? expirationDate;

  ScannedRecord({
    required this.scannedCode,
    required this.drugName,
    required this.isGenuine,
    required this.wasFound,
    required this.scanDate,
    required this.timestamp,
    this.expirationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'scannedCode': scannedCode,
      'drugName': drugName,
      'isGenuine': isGenuine,
      'wasFound': wasFound,
      'scanDate': scanDate,
      'timestamp': timestamp,
      'expirationDate': expirationDate,
    };
  }
}

