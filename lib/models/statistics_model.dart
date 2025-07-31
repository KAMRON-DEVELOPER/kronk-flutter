class StatisticsModel {
  final Map<String, int> weekly;
  final Map<String, int> monthly;
  final Map<String, int> yearly;
  final int total;

  StatisticsModel({this.weekly = const {}, this.monthly = const {}, this.yearly = const {}, this.total = 0});

  factory StatisticsModel.fromJson(Map<String, dynamic> json) {
    return StatisticsModel(
      weekly: Map<String, int>.from(json['weekly'] ?? {}),
      monthly: Map<String, int>.from(json['monthly'] ?? {}),
      yearly: Map<String, int>.from(json['yearly'] ?? {}),
      total: json['total'] ?? 0,
    );
  }
}
