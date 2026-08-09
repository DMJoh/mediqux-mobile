class LabPanelParameter {
  const LabPanelParameter({
    required this.id,
    required this.parameterName,
    this.unit,
    this.referenceMin,
    this.referenceMax,
  });

  factory LabPanelParameter.fromJson(Map<String, dynamic> json) {
    double? parseNum(Object? v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return LabPanelParameter(
      id: json['id'] as String,
      parameterName: json['parameter_name'] as String,
      unit: json['unit'] as String?,
      referenceMin: parseNum(json['reference_min']),
      referenceMax: parseNum(json['reference_max']),
    );
  }

  final String id;
  final String parameterName;
  final String? unit;
  final double? referenceMin;
  final double? referenceMax;

  String? get referenceRange {
    if (referenceMin != null && referenceMax != null) {
      final minStr = referenceMin == referenceMin!.truncateToDouble()
          ? referenceMin!.toInt().toString()
          : referenceMin!.toStringAsFixed(1);
      final maxStr = referenceMax == referenceMax!.truncateToDouble()
          ? referenceMax!.toInt().toString()
          : referenceMax!.toStringAsFixed(1);
      return '$minStr - $maxStr';
    }
    return null;
  }
}

class LabPanel {
  const LabPanel({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.parameters = const [],
  });

  factory LabPanel.fromJson(Map<String, dynamic> json) {
    final params = json['parameters'];
    return LabPanel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      parameters: params is List
          ? params
              .map((e) =>
                  LabPanelParameter.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? category;
  final List<LabPanelParameter> parameters;
}
