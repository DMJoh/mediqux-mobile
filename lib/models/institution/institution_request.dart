import 'package:json_annotation/json_annotation.dart';

part 'institution_request.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class InstitutionRequest {
  const InstitutionRequest({
    required this.name,
    this.type,
    this.address,
    this.phone,
    this.email,
    this.website,
  });

  factory InstitutionRequest.fromJson(Map<String, dynamic> json) =>
      _$InstitutionRequestFromJson(json);

  final String name;
  final String? type;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;

  Map<String, dynamic> toJson() => _$InstitutionRequestToJson(this);
}
