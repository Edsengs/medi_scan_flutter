class DrugData {
  final String id;
  final String name;
  final String manufacturer;
  final String expirationDate;
  final String batchNumber;
  final bool genuine;
  final String indication;
  final String dosage;
  final String sideEffects;
  final String warnings;

  DrugData({
    required this.id,
    required this.name,
    this.manufacturer = "Unknown",
    this.expirationDate = "N/A",
    this.batchNumber = "N/A",
    this.genuine = false,
    this.indication = "Not provided",
    this.dosage = "Not provided",
    this.sideEffects = "Not provided",
    this.warnings = "Not provided",
  });

  factory DrugData.fromJson(String id, Map<dynamic, dynamic> json) {
    return DrugData(
      id: id,
      name: json['name'] ?? 'Unknown Medicine',
      manufacturer: json['manufacturer'] ?? 'Unknown',
      expirationDate: json['expirationDate'] ?? 'N/A',
      batchNumber: json['batchNumber'] ?? 'N/A',
      genuine: json['genuine'] ?? false,
      indication: json['indication'] ?? 'Not provided',
      dosage: json['dosage'] ?? 'Not provided',
      sideEffects: json['sideEffects'] ?? 'Not provided',
      warnings: json['warnings'] ?? 'Not provided',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'manufacturer': manufacturer,
      'expirationDate': expirationDate,
      'batchNumber': batchNumber,
      'genuine': genuine,
      'indication': indication,
      'dosage': dosage,
      'sideEffects': sideEffects,
      'warnings': warnings,
    };
  }
}

