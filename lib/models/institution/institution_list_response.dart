import 'package:json_annotation/json_annotation.dart';
import 'package:mediqux_mobile/models/institution/institution.dart';

part 'institution_list_response.g.dart';

@JsonSerializable()
class InstitutionListResponse {
  const InstitutionListResponse({
    required this.success,
    this.data,
    this.error,
    this.count,
  });

  factory InstitutionListResponse.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$InstitutionListResponseFromJson(json);

  final bool success;
  final List<Institution>? data;
  final String? error;
  final int? count;
}
