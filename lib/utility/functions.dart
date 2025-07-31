import 'package:kronk/utility/extensions.dart';

List<int> generateYearlyData(Map<String, int> yearly) {
  List<String> years = yearly.keys.toList()..sort();
  return years.map((year) => yearly[year]!).toList();
}

List<String> generateDailyLabels(int length) {
  List<String> labels = [];
  DateTime now = DateTime.now();
  for (int i = length - 1; i >= 0; i--) {
    DateTime date = now.subtract(Duration(days: length - 1 - i));
    labels.add(date.weekday.weekdayName);
  }
  return labels;
}

List<String> generateWeeklyLabels(int length) {
  return List.generate(length, (index) => 'Week ${index + 1}');
}

List<String> generateMonthlyLabels(int length) {
  List<String> labels = [];
  DateTime now = DateTime.now();
  for (int i = length - 1; i >= 0; i--) {
    int totalMonthsAgo = length - 1 - i;
    int year = now.year;
    int month = now.month - totalMonthsAgo;
    while (month <= 0) {
      month += 12;
      year--;
    }
    labels.add('${month.monthName} $year');
  }
  return labels;
}

List<String> generateYearlyLabels(Map<String, int> yearly) {
  return yearly.keys.toList()..sort();
}
