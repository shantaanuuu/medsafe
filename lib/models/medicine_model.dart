class MedicineModel {
  const MedicineModel({
    this.id,
    this.brandName,
    this.genericName,
    this.strength,
    this.expiryDate,
    this.manufacturingDate,
    this.batchNumber,
    this.mrp,
    this.manufacturer,
    this.packSize,
    this.sideEffects,
    this.drugInteractions,
    this.medicineDesc,
    this.substitutes,
    this.chemicalClass,
    this.therapeuticClass,
    this.habitForming,
    this.verifiedSource,
    this.nickname,
    this.quantity,
    this.dosageSchedule,
  });

  final String? id;
  final String? brandName;
  final String? genericName;
  final String? strength;
  final String? expiryDate;
  final String? manufacturingDate;
  final String? batchNumber;
  final String? mrp;
  
  // New merged fields from databases
  final String? manufacturer;
  final String? packSize;
  final String? sideEffects;
  final String? drugInteractions;
  final String? medicineDesc;
  final String? substitutes;
  final String? chemicalClass;
  final String? therapeuticClass;
  final String? habitForming;
  
  // App verified source metadata
  final int? verifiedSource;

  // Customized properties
  final String? nickname;
  final double? quantity;
  final String? dosageSchedule;

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id']?.toString(),
      brandName: json['brand_name']?.toString() ?? json['name']?.toString(),
      genericName: json['generic_name']?.toString() ?? json['genericName']?.toString(),
      strength: json['strength']?.toString() ?? json['dosageForm']?.toString(),
      expiryDate: json['expiry_date']?.toString() ?? json['expiryDate']?.toString(),
      manufacturingDate: json['manufacturing_date']?.toString() ?? json['addedDate']?.toString(),
      batchNumber: json['batch_number']?.toString() ?? json['batchNumber']?.toString(),
      mrp: json['price']?.toString() ?? json['mrp']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      packSize: json['pack_size']?.toString(),
      sideEffects: json['side_effects']?.toString() ?? json['sideEffects']?.toString(),
      drugInteractions: json['drug_interactions']?.toString() ?? json['drugInteractions']?.toString(),
      medicineDesc: json['medicine_desc']?.toString() ?? json['medicineDesc']?.toString(),
      substitutes: json['substitutes']?.toString(),
      chemicalClass: json['chemical_class']?.toString() ?? json['chemicalClass']?.toString(),
      therapeuticClass: json['therapeutic_class']?.toString() ?? json['therapeuticClass']?.toString(),
      habitForming: json['habit_forming']?.toString() ?? json['habitForming']?.toString(),
      verifiedSource: json['verifiedSource'] != null ? int.tryParse(json['verifiedSource'].toString()) : (json['verified_source'] != null ? int.tryParse(json['verified_source'].toString()) : null),
      nickname: json['nickname']?.toString(),
      quantity: json['quantity'] != null ? double.tryParse(json['quantity'].toString()) : null,
      dosageSchedule: json['dosage_schedule']?.toString() ?? json['dosageSchedule']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'brand_name': brandName,
      'name': brandName, // Support both keys
      'generic_name': genericName,
      'genericName': genericName,
      'strength': strength,
      'dosageForm': strength,
      'expiry_date': expiryDate,
      'expiryDate': expiryDate,
      'manufacturing_date': manufacturingDate,
      'addedDate': manufacturingDate,
      'batch_number': batchNumber,
      'batchNumber': batchNumber,
      'price': mrp,
      'mrp': mrp,
      'manufacturer': manufacturer,
      'pack_size': packSize,
      'side_effects': sideEffects,
      'sideEffects': sideEffects,
      'drug_interactions': drugInteractions,
      'drugInteractions': drugInteractions,
      'medicine_desc': medicineDesc,
      'medicineDesc': medicineDesc,
      'substitutes': substitutes,
      'chemical_class': chemicalClass,
      'chemicalClass': chemicalClass,
      'therapeutic_class': therapeuticClass,
      'therapeuticClass': therapeuticClass,
      'habit_forming': habitForming,
      'habitForming': habitForming,
      'verifiedSource': verifiedSource,
      'verified_source': verifiedSource,
      'nickname': nickname,
      'quantity': quantity,
      'dosage_schedule': dosageSchedule,
      'dosageSchedule': dosageSchedule,
    };
  }
}
