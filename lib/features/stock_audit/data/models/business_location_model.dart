import '../../../../core/utils/json_parse.dart';

class BusinessLocationModel {
  const BusinessLocationModel({
    required this.id,
    required this.label,
    this.name,
  });

  final int id;
  final String label;
  final String? name;

  factory BusinessLocationModel.fromJson(Map<String, dynamic> json) {
    return BusinessLocationModel(
      id: jsonInt(json['id']),
      label: (json['label'] ?? json['name'] ?? 'Location').toString(),
      name: json['name']?.toString(),
    );
  }
}
