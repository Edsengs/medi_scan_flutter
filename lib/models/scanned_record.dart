class ScannedRecord {
  final String scannedCode;
  final String drugName;
  final bool isGenuine;
  final bool wasFound;
  final String scanDate;
  final int timestamp;

  ScannedRecord({
    required this.scannedCode,
    required this.drugName,
    required this.isGenuine,
    required this.wasFound,
    required this.scanDate,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'scannedCode': scannedCode,
      'drugName': drugName,
      'isGenuine': isGenuine,
      'wasFound': wasFound,
      'scanDate': scanDate,
      'timestamp': timestamp,
    };
  }
}

